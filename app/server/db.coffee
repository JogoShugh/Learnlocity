mongo = require('mongodb').MongoClient
_ = require './myunderscore'
commands = require './commands'
repo = require './mongoRepository'
paginator = require './paginator'
winston = require 'winston'
dictionary = require './dictionarySchema'

useDebug = true

debug = (data) ->
    console.log(data) if useDebug

class ChallengeCompletedDetails
    constructor: (@RowKeyPrefix, @userName, @details) ->
        @created = new Date()

module.exports =
    repo: repo

    connect: ->
        mongo.connect 'mongodb://localhost:27017/learnlocity', (err, db) =>
            if err?
                return console.dir(err)
            else
                debug 'Got db:' + db
                repo.setStorage db
                if useDebug
                    repo.setDebugReporter = debug

    find: (query, done) ->
        return repo.find query, done

    paging: (query) ->
        return paginator.paging query

    diffFilter: (masterList, compareList, comparisonProperty, paging) ->
        return paginator.diffFilter masterList, compareList, comparisonProperty, paging

    userAuthenticate: (login, callback) ->
        query =
            from: 'AccountRegister'
            where:
                $and: [ 
                    { password : login.password }, 
                    $or: [ 
                        {userName: login.userNameOrEmail}, 
                        {email: login.userNameOrEmail} 
                    ] 
                ]
            select: 'userName'
        @find query, (users) ->
            exists = users.length > 0
            callback null, exists

    challengeStateStore: (challengeState, callback) ->
        repo.store(challengeState, challengeState.name, true, callback)

    getQuestion: (challengeState, index) ->
        answer = challengeState.roundItems[index]
        question = new commands.ChallengeQuestion(challengeState.name, index, answer[0].definition, answer[1])
        return question
    
    getAllQuestions: (challengeState, includeAnswer=false) ->
        questions = []
        index = 0
        for answer in challengeState.roundItems
            actualAnswer = null
            if includeAnswer is true
                actualAnswer = answer[0].word
            question = new commands.ChallengeQuestion(challengeState.name, index, answer[0].definition, answer[1], actualAnswer)
            questions.push question
            index++
        return questions                        

    challengeJoinStore: (challengeJoin, callback) ->
        rowKeyPrefix = challengeJoin.name
        rowKey = rowKeyPrefix + ":" + challengeJoin.userName
        challengeJoin.RowKeyPrefix = rowKeyPrefix
        repo.store(challengeJoin, rowKey, false, callback)                   

    challengeSubmitAnswerStore: (challengeSubmitAnswer, callback) ->
        rowKeyPrefix = challengeSubmitAnswer.name + ":" + challengeSubmitAnswer.userName
        rowKey = rowKeyPrefix + ":" + challengeSubmitAnswer.index
        challengeSubmitAnswer.RowKeyPrefix = rowKeyPrefix
        repo.store(challengeSubmitAnswer, rowKey, false, callback)

    challengeAnswerScoredStore: (challengeAnswerScored, callback) ->
        rowKeyPrefix = challengeAnswerScored.name + ':' + challengeAnswerScored.userName
        rowKey = rowKeyPrefix + ':' + challengeAnswerScored.index
        challengeAnswerScored.RowKeyPrefix = rowKeyPrefix
        repo.store challengeAnswerScored, rowKey, false, callback

    challengeCompletedDetailsStore: (challengeCompletedDetails, callback) ->
        rowKey = challengeCompletedDetails.name + ":" + challengeCompletedDetails.userName    
        repo.store(challengeCompletedDetails, rowKey, false, callback)

    findChallengeByName: (name, callback) ->
        query =
            from: 'ChallengeState'
            where:
                name: name
        @find query, (challenges) ->
            challenge = null
            if challenges.length > 0
                challenge = challenges[0]
            callback challenge

    findChallengeJoinsByChallengeName: (challengeName, callback) ->
        query =
            from: 'ChallengeJoin'
            where:
                name: challengeName
        @find query, (challengeJoins) ->
            callback challengeJoins

    userExistsAlready: (accountRegistration, callback) ->
        query =
            from: 'AccountRegister'
            where: 
                email: accountRegistration.email
            select: 'userName'
        repo.find query, (users) ->
            exists = users.length > 0
            callback null, exists

    challengesOpenFind: (query, callback) ->
        paging = @paging query
        @find
            from: 'ChallengeState'
            select: ['name', 'userName', 'created']
            sort: 
                created: -1
        , (allChallenges) =>               
            @find
                from: 'ChallengeJoin'
                select: ['name']                    
                where: 
                    userName: query.userName
            , (challengesJoined) =>
                challengesOpen = @diffFilter allChallenges,
                    challengesJoined, 'name', paging
                callback challengesOpen

    challengesActiveFind: (query, callback) ->
        paging = @paging query
        @find
            from: 'ChallengeJoin'
            select: ['name', 'userName', 'created']
            where:
                userName: query.userName
            sort:
                created: -1
        , (challengesJoined) =>
            @find
                from: 'ChallengeCompletedDetails'
                select: ['details']
                where:
                    userName: query.userName
            , (challengesCompletedDetails) =>
                completedNames = _.pluck challengesCompletedDetails, 'name'
                challengesActive = @diffFilter challengesJoined,
                    completedNames, 'name', paging
                callback challengesActive

    challengesCompletedFind: (query, callback) ->
        paging = @paging query
        @find
            from: 'ChallengeCompletedDetails'
            select: ['name', 'details', 'created']
            where: 
                userName: query.userName
            sort:
                created: -1
        , (challengesCompletedDetails) =>
            challengesCompletedDetails = _.skipTake challengesCompletedDetails, paging
            result = paginator.createPagedResult challengesCompletedDetails, paging
            callback result

    challengeScoreboardSummary: (query, callback) ->
        query.limit = 20
        paging = @paging query
        @find 
            from: 'ChallengeCompletedDetails'
            select: ['name', 'userName', 'details', 'created']
            sort:
                created: -1
        , (challengesCompletedDetails) =>
            groupsUnsorted = _.groupBy challengesCompletedDetails, (challengeCompleted) ->
                return challengeCompleted.details.name
            groups = []
            for challengeName, challengeCompletedList of groupsUnsorted
                sortedCompletedList = _.sortBy challengeCompletedList, (challengeCompleted) ->
                    return - challengeCompleted.details.answersCorrectCount
                groups.push sortedCompletedList
            groups = _.sortBy groups, (group) ->
                return - _.max group, (challengeCompleted) ->
                    return challengeCompleted.created
            groups = _.skipTake groups, paging
            for group in groups
                group[0].latest = _.clone _.max group, (challengeCompleted) ->
                    return challengeCompleted.created
            result = paginator.createPagedResult groups, paging
            callback result

    scorePrefix: (challenge, userName) ->
        return challenge.name + ':' + userName

    challengeCompletedDetailsFind: (challenge, userName, callback) ->
        keyPrefix = @scorePrefix challenge, userName
        debug 'Entering challengesCompletedFind:'
        debug keyPrefix
        @find
            from: 'ChallengeAnswerScored'
            where: 
                RowKeyPrefix: keyPrefix
        , (scoredAnswers) =>
            answersCorrectCount =_.reduce scoredAnswers, (correctCount, answer) ->
                if answer.correct
                    correctCount++
                return correctCount
            , 0
            _.each scoredAnswers, (answer) ->
                answer.word = challenge.roundItems[answer.index][0]
                answer.choices = challenge.roundItems[answer.index][1]
            userChallengeCompletedDetails =
                name: challenge.name
                userName: userName
                answersCorrectCount: answersCorrectCount
                answersAttemptCount: scoredAnswers.length
                answersCorrectPercentage: (100 * (answersCorrectCount / scoredAnswers.length)).toFixed(0)
                answers: scoredAnswers
            debug 'here is the userChallengeCompletedDetails:'
            debug userChallengeCompletedDetails
            challengeCompletedDetails = new ChallengeCompletedDetails keyPrefix, userName, userChallengeCompletedDetails
            debug 'and the actual challengeCompletedDetails:'
            debug challengeCompletedDetails
            callback challengeCompletedDetails

    definitionsStore: (definitions, callback) ->
        repo.store(definitions, 'Definitions', true, callback)

    definitionsLoad: (callback) ->
        @find
            from: 'Definitions'
        , (definitions) =>
            callback definitions

    definitionStore: (definition, callback) ->
        dictionary.findOne {title:definition.dictionary}, (err, dictionary) ->
            if dictionary?
                word = {word:definition.word, definition:definition.definition}
                dictionary.words.push word
                dictionary.save (err) ->
                    if err?
                        console.log 'Error in definitionStore: ' + err
                    else 
                        callback err, word

        '''
        repo.storage.collection 'Definitions', (err, collection) ->
            collection.update {key:'Definitions'},
                {$addToSet: {'words':definition}}, (err, result) ->
                    debug 'error: ' + err
                    debug 'res: ' + result
                    callback err, result
        '''
    dictionaryList: (args, callback) ->
        dictionary.count {}, (err, count) ->
            query = dictionary.find {}
            query.skip (args.page - 1) * 5
            query.limit 5
            query.exec (err, dictionaryList) ->
                items = _.map dictionaryList, (item) ->
                    return {title: item.title, wordCount: item.words.length}
                fakeList = new Array(count);
                result = paginator.createPagedResult fakeList, {limit:5}
                result.items = items
                console.log 'result:'
                console.log result
                callback null, result

    dictionaryCreate: (dictionaryCreateCmd, callback) ->
        dictionary.findOne {title:dictionaryCreateCmd.title}, (err, existingDictionary) ->
            if not existingDictionary?
                props =
                    title: dictionaryCreateCmd.title
                    author: dictionaryCreateCmd.userName
                    words: []
                console.log 'props:'
                console.log props
                dictionary.create props, (err, data) ->
                    console.log 'err:'
                    console.log err
                    console.log 'data:'
                    console.log data
                    if not err?
                        callback null, {title:props.title}