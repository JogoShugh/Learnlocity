importer = require './importer'
importer(require('./utils'))
dict = require ('./AgileDictionary')
http = require 'http'
mongo = require('mongodb').MongoClient
storage = null
_ = require 'underscore'

_.mixin
    skipTake: (array, options) -> 
        options = _.extend({skip:0, limit:0}, options || {}) 
        return _(array)
            .chain()
            .rest(options.skip)
            .first(options.limit || array.length - options.skip)
            .value()

mongo.connect 'mongodb://localhost:27017/learnlocity', (err, db) ->
    if err?
        return console.dir(err)
    else
        console.log 'Got db:' + db
        storage = db

NUMBER_OF_QUESTIONS_PER_ROUND = 3

# Commands and Queries

useDebug = true

debug = (data) ->
    console.log data if useDebug

class AccountRegister
    constructor: (@userName='', @email='', 
        @password='', @passwordConfirm='', @id='', @externalAuth=false) ->

    getValidationErrors: ->
        sv = new StringValidator

        sv.field('userName', @userName)
            .max(50)
            .min(4)
            .notEmpty()

        if @externalAuth
            return sv.errors

        sv.field('email', @email)
            .max(100)
            .min(5)
            .notEmpty()

        sv.field('password', @password)
            .max(50)
            .min(8)
            .notEmpty()

        sv.field('Confirm Password', @passwordConfirm)
            .matches(@password, 'Password')

        return sv.errors

class Login
    constructor: (@userNameOrEmail='', @password='', @externalAuth=false) ->

    getValidationErrors: ->
        sv = new StringValidator

        sv.field("Username or Email", @userNameOrEmail)
            .notEmpty()
            .max(100)
            .min(4)

        if @externalAuth
            return sv.errors

        sv.field("Password", @password)
            .notEmpty()
            .max(50)
            .min(8)

        return sv.errors

class ChallengesOpen
    constructor: (@userName) ->

class ChallengesCompleted
    constructor: (@userName) ->

class ChallengesActive
    constructor: (@userName) ->

class ChallengeSendChatMessage
    constructor: (@userName="", @message='', @dateTime=null) ->

class ChallengeCreate
    constructor: (@userName='', @name='', @isOpen=false, @isGroup=false) ->

    getValidationErrors: ->
        sv = new StringValidator

        # TODO: this should link to an auth cookie or header
        sv.field("Username", @userName)
            .notEmpty()
            .max(50)
            .min(4)

        sv.field("Name", @name)
            .notEmpty()
            .max(50)
            .min(5)

        return sv.errors    

class ChallengeJoin
    constructor: (@userName='', @name='') ->
        @created = new Date()

class ChallengeResume
    constructor: (@userName='', @name='') ->

class ChallengeSpy
    constructor: (@userName='', @name='') ->

class ChallengeWatch
    constructor: (@userName='', @name='') ->

class ChallengeQuestionByIndex
    constructor: (@name='', @index=0) ->

class ChallengeQuestion
    constructor: (@name='', @index=0, @definition='', @choices=[], answer) ->
        if answer?
            @answer = answer

class ChallengeSubmitAnswer
    constructor: (@name='', @userName='', @index=0, @answer='') ->

class ChallengeAnswerScored
    constructor: (@name='', @index=0, @correct=false, @userName='') ->
        @created = new Date()

class ChallengeSubmitAnswerResponse
    constructor: (@challengeName='', @challengePlayerName='', @choice='', @result=false, @scoreStatusInfo=null) ->

class ScoreStatusInfo
    constructor: (@answersAttemptCount=0, @answersCorrectCount=0,
        @answersPercentage=0.0, @streakCount=0, @streakIsCorrect=false) ->

class ChallengeCompletedDetails
    constructor: (@RowKeyPrefix, @userName, @details) ->
        @created = new Date()

class ChallengeScoreDetails
    constructor: (@name) ->

class ChallengeScoreboard
    constructor: (@userName='') ->

class Challenge
    constructor: (@userName='', @name='') ->
        @_roundItems = []
        @_players = []
        @_wordsSeenAlready = []
        @_generateRoundItems NUMBER_OF_QUESTIONS_PER_ROUND
        @addPlayer(@userName)

    _randOrd: -> # Prototype value
        return Math.round(Math.random()) - 0.5

    addPlayer: (userName) ->
        @_players.push [userName, new Array(NUMBER_OF_QUESTIONS_PER_ROUND)]

    _savePlayerAnswer: (userName, index, answer, correct) ->
        player = null
        for p in @_players
            if p[0] == userName
                player = p
        if player?
            player[1][index] = { "answer" : answer, "correct" : correct }

    questionByIndex: (index) ->
        return @_roundItems[index]

    submitAnswer: (userName, index, answer) ->
        if index > @_roundItems.length
            return false
        question = @questionByIndex(index)
        if not question?
            throw "Cannot submit answer for index: " + index
        correct = (answer == question[0].word)        
        @_savePlayerAnswer(userName, index, answer, correct)
        return correct

    submitAnswer: (userName, index, answer) ->
        if index > @_roundItems.length
            return false
        question = @questionByIndex(index)
        if not question?
            throw "Cannot submit answer for index: " + index
        correct = (answer == question[0].word)        
        @_savePlayerAnswer(userName, index, answer, correct)
        return correct        

    scoreDetails: ->
        return @_players

    _generateRoundItems: (numberOfQuestions) ->
        @_roundItems = []

        for i in [0..numberOfQuestions-1]
            word = @_getRandomUnseenWord()
            choices = @_getAnswerChoices(word).sort(@_randOrd)
            @_roundItems.push([word, choices])

    _getRandomUnseenWord: ->
        word = dict.Dictionary.getRandomWord()
        while (@_hasWordBeenSeenAlready(word))
            word = dict.Dictionary.getRandomWord()
        return word

    _hasWordBeenSeenAlready: (word) ->
        return word in @_wordsSeenAlready

    _registerSeenWord: (word) ->
        if not _hasWordBeenSeenAlready(word)
            @_wordsSeenAlready.push(word)

    _getAnswerChoices: (currentWord) ->
        choices = []
        for i in [0..2]
            word = dict.Dictionary.getRandomWord()
            while (word == currentWord)
                word = dict.Dictionary.getRandomWord()
            choices.push(word.word)
        choices.push(currentWord.word);
        return choices

class ChallengePlayer
    constructor: (@userName) ->

class ChallengeState
    constructor: (@userName, @name, @roundItems) ->
        @created = new Date()

class ChallengeStateFactory
    constructor: ->

    create: (@userName='', @name='') ->
        @_roundItems = []
        @_wordsSeenAlready = []
        @_generateRoundItems NUMBER_OF_QUESTIONS_PER_ROUND
        state = new ChallengeState(@userName, @name, @_roundItems)
        return state

    _randOrd: -> # Prototype value
        return Math.round(Math.random()) - 0.5

    _generateRoundItems: (numberOfQuestions) ->
        @_roundItems = []
        for i in [0..numberOfQuestions-1]
            word = @_getRandomUnseenWord()
            choices = @_getAnswerChoices(word).sort(@_randOrd)
            @_roundItems.push([word, choices])

    _getRandomUnseenWord: ->
        word = dict.Dictionary.getRandomWord()
        while (@_hasWordBeenSeenAlready(word))
            word = dict.Dictionary.getRandomWord()
        return word

    _hasWordBeenSeenAlready: (word) ->
        return word in @_wordsSeenAlready

    _getAnswerChoices: (currentWord) ->
        choices = []
        for i in [0..2]
            word = dict.Dictionary.getRandomWord()
            while (word == currentWord)
                word = dict.Dictionary.getRandomWord()
            choices.push(word.word)
        choices.push(currentWord.word);
        return choices

class LearnlocityServer
    constructor: ->
        @NotifySourceClient = null
        @NotifyAllClients = null
        @Join = null
        @NotifyRoom = null
        @_challenges = []
        @_onlineMembers = []

    send: (cmd, callback) ->
        # TODO: handle exceptions...
        @[cmd.constructor.name] cmd, callback

    invoke: (commandName, cmd) ->
        # TODO: handle exceptions...
        @[commandName] cmd

    AccountRegister: (cmd, callback=null) =>
        errors = cmd.getValidationErrors()
        if errors.length > 0
            @NotifySourceClient "ErrorOccurred", errors
            return
        @_userExistsAlready cmd, (duplicateName) =>
            if duplicateName == true
                @NotifySourceClient "ErrorOccurred", "Please try a different username. An account by that name already exists."
            else
                @_store cmd, cmd.username, false, (err, user) =>
                    if err?
                        @NotifySourceClient "ErrorOccurred", err
                    else
                        @NotifySourceClient "AccountRegisterSucceeded", cmd.userName
                        if callback?
                            callback()

    Login: (cmd, notifySourceClient) =>
        # TODO crazy hack
        if users[cmd.userNameOrEmail]?
            cmd.externalAuth = true
        errors = cmd.getValidationErrors()
        if errors.length > 0
            callback "ErrorOccurred", errors
            return
        @_userAuthenticate cmd, (err, authenticated) =>
            if err?
                debug "It blew up:" + err
                notifySourceClient "ErrorOccurred", err
                return
            else
                if authenticated                    
                    @_onlineMembers.push(cmd.userNameOrEmail)
                    user = {userName:cmd.userNameOrEmail}
                    if cmd.externalAuth
                        user.profile = users[cmd.userNameOrEmail]
                    @NotifySourceClient 'LoginSucceeded', user
                else
                    if cmd.externalAuth
                        registerCmd = new AccountRegister(cmd.userNameOrEmail, 
                            cmd.userNameOrEmail, cmd.userNameOrEmail, cmd.userNameOrEmail, "", true)
                        @AccountRegister registerCmd, =>
                            @NotifySourceClient "LoginSucceeded", cmd.userNameOrEmail
                    else  
                        @NotifySourceClient "LoginFailed", "Could not authenticate user with username or email of " + cmd.userNameOrEmail

    _find: (query, done) =>
        skip = query.skip || 0
        limit = query.limit || null
        collection = storage.collection query.from
        sort = query.sort
        values = []
        where = query.where || {}
        select = null
        collapseSelect = true
        if query.collapseSelect?
            collapseSelect = query.collapseSelect
        if query.select?
            select = {}
            for field in query.select
                select[field] = true
        else
            select = {}
        keys = _.keys select
        findExec = collection.find(where, select).skip(skip)
        if sort?
            findExec = findExec.sort sort
        if limit?
            findExec = findExec.limit(limit)                    
        findExec.stream()   
            .on 'data', (row) ->
                obj = null
                if keys.length > 0
                    obj = _.pick row, keys
                else
                    obj = row
                values.push obj
            .on 'end', ->
                if collapseSelect is true and keys.length is 1
                    key = keys[0]
                    values = _.pluck values, key
                if done?
                    done(values)

    _paging: (query) ->
        page = query.page || 1
        limit = query.limit || 5
        skip = (page-1) * 5
        return {
            page: page
            limit: limit
            skip: skip
        }

    _pageCountCalc: (list, pageSize) ->
        pageCount = parseInt(list.length / pageSize)
        itemCount = list.length
        fractionalPages = 0
        if list.length % pageSize > 0
            fractionalPages = 1
        pageCount += fractionalPages
        return {
           pageCount: pageCount
           itemCount: itemCount 
        }

    _diffFilter: (masterList, compareList, comparisonProperty, paging) ->
        comparisonProperties = _.pluck masterList, comparisonProperty
        filteredList = _.difference comparisonProperties, compareList
        pageInfo = @_pageCountCalc filteredList, paging.limit
        filteredList = _.skipTake filteredList, paging
        filteredList = _.filter masterList, (masterItem) ->
            return _.contains filteredList, masterItem[comparisonProperty]
        result =
            items: filteredList
            pageCount: pageInfo.pageCount
            itemCount: pageInfo.itemCount    
        return result

    ChallengesOpen: (query) =>
        paging = @_paging query
        @_find
            from: 'ChallengeState'
            select: ['name', 'userName', 'created']
            sort: 
                created: -1
        , (allChallenges) =>               
            @_find
                from: 'ChallengeJoin'
                select: ['name']                    
                where: 
                    userName: query.userName
            , (challengesJoined) =>
                challengesNotJoined = @_diffFilter allChallenges,
                    challengesJoined, 'name', paging
                @NotifySourceClient 'ChallengesOpenSent', challengesNotJoined

    ChallengesCompleted: (query) =>
        paging = @_paging query
        @_find 
            from: 'ChallengeCompletedDetails'
            select: ['name', 'details', 'created']
            where: 
                userName: query.userName
            sort:
                created: -1
        , (challengesCompletedDetails) =>
            challengesCompletedDetails = _.skipTake challengesCompletedDetails, paging
            pageInfo = @_pageCountCalc challengesCompletedDetails, paging.limit
            result = 
                items: challengesCompletedDetails
                pageCount: pageInfo.pageCount
                itemCount: pageInfo.itemCount
            @NotifySourceClient 'ChallengesCompletedSent', result

    ChallengesActive: (query) =>
        paging = @_paging query
        @_find
            from: 'ChallengeJoin'
            select: ['name', 'userName', 'created']
            where:
                userName: query.userName
            sort:
                created: -1
        , (challengesJoined) =>
            @_find
                from: 'ChallengeCompletedDetails'
                select: ['details']
                where:
                    userName: query.userName
            , (challengesCompletedDetails) =>
                completedNames = _.pluck challengesCompletedDetails, 'name'
                challengesActive = @_diffFilter challengesJoined,
                    completedNames, 'name', paging
                @NotifySourceClient 'ChallengesActiveSent', challengesActive
                
    ChallengeCreate: (cmd) =>    
        errors = cmd.getValidationErrors()        
        console.log errors
        if errors.length > 0
            return false
        # TODO: ensure challenge by same name does not exist currently
        factory = new ChallengeStateFactory()
        challengeState = factory.create(cmd.userName, cmd.name)
        console.log 'factory: ' + factory
        @_challengeStateStore challengeState, (err, challengeName) =>
            console.log ('ChallengeCreate: ' + err)
            if err?
                debug "ChallengeCreate: " + err
                @NotifySourceClient("ErrorOccurred", err)
            else
                challengeJoin = new ChallengeJoin(cmd.userName, cmd.name)
                @_challengeJoinStore challengeJoin, (err, rowKey) =>
                    if err?
                        debug "_challengeJoinStore:" + err
                        @NotifySourceClient "ErrorOccurred", err
                    else           
                        debug "ChallengeCreate worked: " + challengeName
                        @Join challengeName
                        @NotifySourceClient "ChallengeCreateSucceeded", challengeName
                        #firstQuestion = @_getQuestion challengeState, 0
                        #@NotifySourceClient "ChallengeQuestionSent", firstQuestion
                        questions = @_getAllQuestions challengeState
                        @NotifySourceClient "ChallengeQuestionsSent", questions
                        @NotifyAllClients "ChallengeCreated",                            
                            userName: challengeState.userName
                            name: challengeName
                            created: challengeState.created

    _challengeStateStore : (challengeState, callback) ->
        @_store(challengeState, challengeState.name, true, callback)

    _getQuestion : (challengeState, index) ->
        answer = challengeState.roundItems[index]
        question = new ChallengeQuestion(challengeState.name, index, answer[0].definition, answer[1])
        return question
    
    _getAllQuestions: (challengeState, includeAnswer=false) ->
        questions = []
        index = 0
        for answer in challengeState.roundItems
            actualAnswer = null
            if includeAnswer is true
                actualAnswer = answer[0].word
            question = new ChallengeQuestion(challengeState.name, index, answer[0].definition, answer[1], actualAnswer)
            questions.push question
            index++
        return questions

    ChallengeJoin: (cmd) ->
        @_findChallengeByName cmd.name, (challengeState) =>
            if challengeState?
                # TODO consider challenge security...
                @Join challengeState.name
                questions = @_getAllQuestions challengeState
                @NotifySourceClient "ChallengeQuestionsSent", questions
                @_challengeJoinStore cmd, (err, rowKey) =>
                    if err?
                        debug "_challengeJoinStore:" + err
                        @NotifySourceClient "ErrorOccurred", err
                    else
                        challengeJoin = { name: cmd.name, userName: cmd.userName, message: "#{cmd.userName} joined #{cmd.name}!" }
                        if users[cmd.userName]? and users[cmd.userName].photos? and users[cmd.userName].photos.length > 0
                            challengeJoin.userAvatarUrl = users[cmd.userName].photos[0].value
                        @NotifyRoomChannels challengeState.name, 'ChallengeJoined', challengeJoin
                            
                        @_findChallengeJoinsByChallengeName cmd.name, (challengeJoins) =>
                            for challengeJoin in challengeJoins
                                if users[challengeJoin.userName]? and users[challengeJoin.userName].photos? and users[challengeJoin.userName].photos.length > 0
                                    challengeJoin.userAvatarUrl = users[challengeJoin.userName].photos[0].value
                                challengeJoin.message = "#{challengeJoin.userName} joined #{challengeJoin.name}!"
                                @NotifySourceClient 'ChallengeJoined', challengeJoin

    ChallengeResume: (cmd) ->
        @_findChallengeByName cmd.name, (challengeState) =>
            if challengeState?
                @Join challengeState.name
                questions = @_getAllQuestions challengeState
                @NotifySourceClient "ChallengeQuestionsSent", questions
                challengeJoin = { name: cmd.name, userName: cmd.userName, message: "#{cmd.userName} joined #{cmd.name}!" }
                if users[cmd.userName]? and users[cmd.userName].photos? and users[cmd.userName].photos.length > 0
                    challengeJoin.userAvatarUrl = users[cmd.userName].photos[0].value
                @NotifySourceClient challengeState.name, 'ChallengeJoined', challengeJoin                    
                @_findChallengeJoinsByChallengeName cmd.name, (challengeJoins) =>
                    for challengeJoin in challengeJoins
                        if users[challengeJoin.userName]? and users[challengeJoin.userName].photos? and users[challengeJoin.userName].photos.length > 0
                            challengeJoin.userAvatarUrl = users[challengeJoin.userName].photos[0].value
                        challengeJoin.message = "#{challengeJoin.userName} joined #{challengeJoin.name}!"
                        @NotifySourceClient 'ChallengeJoined', challengeJoin
                    findScorings = 
                        from: 'ChallengeAnswerScored'
                        where:
                            name: cmd.name
                        done: (challengeAnswerScorings) =>
                            for challengeAnswerScored in challengeAnswerScorings
                                if challengeAnswerScored.userName is not cmd.userName
                                    delete challengeAnswerScored.answer
                                @NotifySourceClient 'ChallengeAnswerScored', challengeAnswerScored, true
                    @_find findScorings

    ChallengeWatch: (cmd) ->
        @_findChallengeByName cmd.name, (challengeState) =>
            if challengeState?
                # TODO consider challenge security...
                @Join challengeState.name + 'Watch'
                questions = @_getAllQuestions challengeState, true
                @NotifySourceClient "ChallengeQuestionsSent", questions
                @NotifySourceClient "ChallengeWatched", {name: cmd.name}
                @_findChallengeJoinsByChallengeName cmd.name, (challengeJoins) =>
                    for challengeJoin in challengeJoins
                        if users[challengeJoin.userName]? and users[challengeJoin.userName].photos? and users[challengeJoin.userName].photos.length > 0
                            challengeJoin.userAvatarUrl = users[challengeJoin.userName].photos[0].value                        
                        challengeJoin.message = "#{challengeJoin.userName} joined #{challengeJoin.name}!"
                        @NotifySourceClient 'ChallengeJoined', challengeJoin

    ChallengeSpy: (cmd) ->
        @_findChallengeByName cmd.name, (challengeState) =>
            if challengeState?
                # TODO consider challenge security...
                @Join challengeState.name + 'Spy'
                questions = @_getAllQuestions challengeState, true
                @NotifySourceClient "ChallengeQuestionsSent", questions
                @NotifySourceClient "ChallengeSpied", {name: cmd.name}
                @_findChallengeJoinsByChallengeName cmd.name, (challengeJoins) =>
                    for challengeJoin in challengeJoins
                        if users[challengeJoin.userName]? and users[challengeJoin.userName].photos? and users[challengeJoin.userName].photos.length > 0
                            challengeJoin.userAvatarUrl = users[challengeJoin.userName].photos[0].value                        
                        challengeJoin.message = "#{challengeJoin.userName} joined #{challengeJoin.name}!"
                        @NotifySourceClient 'ChallengeJoined', challengeJoin                        

    _challengeJoinStore: (challengeJoin, callback) ->
        rowKeyPrefix = challengeJoin.name
        rowKey = rowKeyPrefix + ":" + challengeJoin.userName
        challengeJoin.RowKeyPrefix = rowKeyPrefix
        @_store(challengeJoin, rowKey, false, callback)                   

    ChallengeSubmitAnswer: (cmd) ->
        @_findChallengeByName cmd.name, (challenge) =>
            if challenge?                
                @_challengeSubmitAnswerStore cmd, (err, rowKey) =>
                    if err?
                        debug "ERROR: _challengeSubmitAnswer:" + err
                        @NotifySourceClient "ErrorOccurred", err
                    else 
                        # Send next question
                        correct = @_answerIsCorrect(cmd, challenge)
                        challengeAnswerScored = new ChallengeAnswerScored(cmd.name, cmd.index, correct, cmd.userName)
                        challengeAnswerScoredSave = new ChallengeAnswerScored(cmd.name, cmd.index, correct, cmd.userName)
                        challengeAnswerScoredSave.answer = cmd.answer                        
                        @_challengeAnswerScoredStore challengeAnswerScoredSave, =>
                            @NotifyRoomChannels cmd.name, 'ChallengeAnswerScored', challengeAnswerScored, false,
                                Spy: 
                                    answer: cmd.answer
                            challengeAnswerScored.answer = cmd.answer
                            @NotifySourceClient 'ChallengeAnswerScored', challengeAnswerScored

                            if cmd.index == (NUMBER_OF_QUESTIONS_PER_ROUND - 1)
                                console.log "Completed the challenge now at index: " + cmd.index
                                @_challengeCompletedNotify challenge, cmd

    _challengeSubmitAnswerStore: (challengeSubmitAnswer, callback) ->
        rowKeyPrefix = challengeSubmitAnswer.name + ":" + challengeSubmitAnswer.userName
        rowKey = rowKeyPrefix + ":" + challengeSubmitAnswer.index
        debug "The key is: " + rowKey
        challengeSubmitAnswer.RowKeyPrefix = rowKeyPrefix
        @_store(challengeSubmitAnswer, rowKey, false, callback)

    _challengeAnswerScoredStore: (challengeAnswerScored, callback) ->
        rowKeyPrefix = challengeAnswerScored.name + ':' + challengeAnswerScored.userName
        rowKey = rowKeyPrefix + ':' + challengeAnswerScored.index
        challengeAnswerScored.RowKeyPrefix = rowKeyPrefix
        @_store challengeAnswerScored, rowKey, false, callback

    _answerIsCorrect: (challengeSubmitAnswer, challenge) ->
        index = challengeSubmitAnswer.index
        selection = challengeSubmitAnswer.answer       
        answer = challenge.roundItems[index]
        correct = false
        if selection == answer[0].word
            correct = true
        return correct

    _challengeCompletedNotify: (challenge, challengeSubmitAnswer) =>
        #@NotifySourceClient "ChallengeCompleted", {name:challenge.name}
        # TODO: lot of duplicate code here...        
        typeName = "ChallengeAnswerScored"        
        completedUserName = challengeSubmitAnswer.userName
        keyPrefix = challengeSubmitAnswer.name + ':' + completedUserName
        answers = []
        collection = storage.collection typeName
        collection.find({RowKeyPrefix : keyPrefix}).stream()
            .on 'data', (item) =>
                answers.push item
            .on 'end', =>
                answersCorrectCount =_.reduce answers, (correctCount, answer) ->
                    if answer.correct
                        correctCount++
                    return correctCount
                , 0
                _.each answers, (answer) ->
                    answer.word = challenge.roundItems[answer.index][0]
                    answer.choices = challenge.roundItems[answer.index][1]
                userChallengeCompletedDetails =
                    name: challenge.name
                    userName: completedUserName
                    answersCorrectCount : answersCorrectCount
                    answersAttemptCount : answers.length
                    answersCorrectPercentage : (100 * (answersCorrectCount / answers.length)).toFixed(0)
                    answers : answers
                challengeCompletedDetails = new ChallengeCompletedDetails keyPrefix, completedUserName, userChallengeCompletedDetails
                @_challengeCompletedDetailsStore challengeCompletedDetails, =>
                    console.log 'Saved the challengeCompletedDetails successfully: '
                    console.log challengeCompletedDetails
                    @NotifySourceClient 'ChallengeCompletedDetails', challengeCompletedDetails
                    @Join keyPrefix + 'Finished'
                    @ChallengeScoreboardAll {}

    _challengeCompletedDetailsStore: (challengeCompletedDetails, callback) ->
        rowKey = challengeCompletedDetails.name + ":" + challengeCompletedDetails.userName
        console.log 'The rowKey for saving completedDetails: ' + rowKey
        @_store(challengeCompletedDetails, rowKey, false, callback)

    ChallengeScoreDetails: (cmd) ->
        challenge = @_findChallengeByName cmd.name
        if challenge?
            return challenge.scoreDetails()
        return null

    ChallengeScoreboard: (query) =>
        query.limit = 20
        paging = @_paging query
        @_find 
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
            pageInfo = @_pageCountCalc groups, paging.limit
            groups = _.skipTake groups, paging
            for group in groups
                group[0].latest = _.clone _.max group, (challengeCompleted) ->
                    return challengeCompleted.created
            result = 
                items: groups
                pageCount: pageInfo.pageCount
                itemCount: pageInfo.itemCount
            @NotifySourceClient 'ChallengeScoreboardSent', result

    ChallengeScoreboardAll: (query) =>
        query.limit = 20
        paging = @_paging query
        @_find 
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
            pageInfo = @_pageCountCalc groups, paging.limit
            groups = _.skipTake groups, paging
            for group in groups
                group[0].latest = _.clone _.max group, (challengeCompleted) ->
                    return challengeCompleted.created
            result = 
                items: groups
                pageCount: pageInfo.pageCount
                itemCount: pageInfo.itemCount
            @NotifyAllClients 'ChallengeScoreboardSent', result            

    _findChallengeByName: (name, callback) ->
        typeName = "ChallengeState"
        collection = storage.collection typeName
        challengeState = null
        console.log "Challenge name: " + name
        collection.find({name : name}).stream()
            .on 'data', (item) ->
                challengeState = item
            .on 'end', ->
                callback challengeState

    _findChallengeJoinsByChallengeName: (challengeName, callback) ->
        typeName = "ChallengeJoin"
        collection = storage.collection typeName
        challengeJoins = []        
        collection.find({name : challengeName}).stream()
            .on 'data', (item) ->
                challengeJoins.push item
            .on 'end', ->
                callback challengeJoins

    _userExistsAlready: (accountRegistration, callback) ->
        typeName = "AccountRegister"
        collection = storage.collection typeName
        exists = false
        collection.find({email : accountRegistration.email}).stream()
            .on 'data', (item) ->
                debug 'user exists'
                exists = true
            .on 'end', ->
                debug "Exists: " + exists
                callback exists
    
    _userAuthenticate: (login, callback) ->
        typeName = "AccountRegister"
        collection = storage.collection typeName
        exists = false
        query = { $and: [ {password : login.password}, $or: [ {userName: login.userNameOrEmail}, {email: login.userNameOrEmail} ] ] }
        collection.find(query).stream()
            .on 'data', (row) ->
                exists = true
            .on 'end', ->
                callback null, exists

    _store: (obj, key, stringify, callback) ->
        typeName = obj.constructor.name        
        storage.collection typeName, (err, collection) ->
            if err?              
                debug "ERROR: _store:collection: " + err  
                callback err, null
                return
            else 
                debug "typeName: " + typeName + ": " + key + ': ' + obj
                obj.key = key
                collection.insert obj, (err, result) ->
                    if err?
                        callback err, null
                    else
                        callback null, key
module.exports =
    LearnlocityServer: LearnlocityServer
    AccountRegister: AccountRegister
    Login: Login
    ChallengeScoreboard: ChallengeScoreboard
    ChallengesOpen: ChallengesOpen
    ChallengesCompleted: ChallengesCompleted
    ChallengesActive: ChallengesActive
    ChallengeCreate: ChallengeCreate
    ChallengeJoin: ChallengeJoin
    ChallengeResume: ChallengeResume
    ChallengeWatch: ChallengeWatch
    ChallengeSpy: ChallengeSpy
    ChallengeQuestionByIndex: ChallengeQuestionByIndex
    ChallengeSubmitAnswer: ChallengeSubmitAnswer
    ChallengeScoreDetails: ChallengeScoreDetails

express = require('express')
app = express()
server = http.createServer app
io = require('socket.io').listen server

passport = require 'passport'
FacebookStrategy = require('passport-facebook').Strategy

FACEBOOK_APP_ID = '145122539006776'
FACEBOOK_APP_SECRET = '94eb7e44b1945f31c2cbfb37dcf1f3ff'

users = {}

passport.use new FacebookStrategy {
    clientID: FACEBOOK_APP_ID,
    clientSecret: FACEBOOK_APP_SECRET,
    callbackURL: 'http://localhost:8000/auth/facebook/callback'
    profileFields: ['id', 'displayName', 'username', 'photos', 'email', 'name', 'profileUrl']
  }, (accessToken, refreshToken, profile, done) ->
        console.log profile   
        done(null, profile)

passport.serializeUser (user, done) ->
    users[user.username] = user
    done null, user.username

passport.deserializeUser (id, done) ->
    user = users[id]
    done null, user

app.configure ->
    app.use '/app', express.static(__dirname + '/../')
    app.use passport.initialize()
    app.use passport.session()
    app.use app.router

app.get '/auth/facebook', passport.authenticate 'facebook'

app.get '/auth/facebook/callback', passport.authenticate('facebook', 
    { failureRedirect: '/auth/facebook' }), (req, res) ->
        console.log 'res user:'
        console.log req.user
        console.log '-----'
        res.redirect '/app/index.html#/?user=' + req.user.username

server.listen 8000

io.sockets.on 'connection', (socket) ->
    console.log 'started'
    learnlocityServer = new LearnlocityServer

    sourceClientId = socket.id
    
    notifyAllClients = (topic, data) ->
        io.sockets.emit 'message', [topic, data]

    notifySourceClient = (topic, data) ->
        io.sockets.socket(sourceClientId).emit 'message', [topic, data]
    
    join = (room) ->
       socket.join room

    notifyRoom = (room, topic, data, includeSelf=false) ->
        if includeSelf
            io.sockets.in(room).emit 'message', [topic, data]
        else
            socket.broadcast.to(room).emit 'message', [topic, data]

    learnlocityServer.NotifyAllClients = notifyAllClients
    learnlocityServer.NotifySourceClient = notifySourceClient
    learnlocityServer.Join = join
    learnlocityServer.NotifyRoom = notifyRoom
    learnlocityServer.NotifyRoomChannels = (room, topic, data, includeSelf=false, mixInPropertiesMap=null) ->        
        @NotifyRoom room, topic, data, includeSelf
        for subChannel in ['Watch', 'Spy']
            localData = _.clone data
            if mixInPropertiesMap? and mixInPropertiesMap[subChannel]?
                _.extend localData, mixInPropertiesMap[subChannel]
            @NotifyRoom room + subChannel, topic, localData, includeSelf

    socket.on 'message', (data) ->        
        commandClassName = data[0]
        commandConstructorArguments = data[1]
        console.log ('socket.on message: ' + commandClassName + " -> " + commandConstructorArguments)    
        cmd = new module.exports[commandClassName]
        props = data[1]
        for key, value of props
            cmd[key] = value
        debug commandClassName + ", " + cmd
        learnlocityServer.invoke commandClassName, cmd