importer = require './importer'
importer(require('./utils'))
_ = require './myunderscore'
dictionary = require './dictionarySchema'
dictClass = require './Dictionary'
commands = require './commands'
db = require './db'
paginator = require './paginator'

NUMBER_OF_QUESTIONS_PER_ROUND = 3

# Commands and Queries

useDebug = true

debug = (data) ->
    console.log data if useDebug

db.connect()

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
        word = dict.getRandomWord()
        while (@_hasWordBeenSeenAlready(word))
            word = dict.getRandomWord()
        return word

    _hasWordBeenSeenAlready: (word) ->
        return word in @_wordsSeenAlready

    _registerSeenWord: (word) ->
        if not _hasWordBeenSeenAlready(word)
            @_wordsSeenAlready.push(word)

    _getAnswerChoices: (currentWord) ->
        choices = []
        for i in [0..2]
            word = dict.getRandomWord()
            while (word == currentWord)
                word = dict.getRandomWord()
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

    create: (@userName='', @name='', dictName='GRE Words', callback) ->
        console.log dictionary
        dictionary.findOne {title:dictName}, (err, dict) =>
            if err?
                console.log 'ERROR: ' + err
            else
                console.log 'dict:'
                console.log dict.words
                @_dict = new dictClass dict.words
                console.log @_dict
                @_roundItems = []
                @_wordsSeenAlready = []
                @_generateRoundItems NUMBER_OF_QUESTIONS_PER_ROUND
                state = new ChallengeState(@userName, @name, @_roundItems)
                callback state

    _randOrd: -> # Prototype value
        return Math.round(Math.random()) - 0.5

    _generateRoundItems: (numberOfQuestions) ->
        @_roundItems = []
        for i in [0..numberOfQuestions-1]
            word = @_getRandomUnseenWord()
            choices = @_getAnswerChoices(word).sort(@_randOrd)
            @_roundItems.push([word, choices])

    _getRandomUnseenWord: ->
        word = @_dict.getRandomWord()
        while (@_hasWordBeenSeenAlready(word))
            word = @_dict.getRandomWord()
        return word

    _hasWordBeenSeenAlready: (word) ->
        return word in @_wordsSeenAlready

    _getAnswerChoices: (currentWord) ->
        choices = []
        for i in [0..2]
            word = @_dict.getRandomWord()
            while (word == currentWord)
                word = @_dict.getRandomWord()
            choices.push(word.word)
        choices.push(currentWord.word);
        return choices

class ChallengeAnswerScored
    constructor: (@name='', @index=0, @correct=false, @userName='') ->
        @created = new Date()

class LearnlocityServer
    constructor: ->
        # These all get "setter injected":
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

    process: (commandClassName, commandConstructorArguments) ->
        cmd = new commands[commandClassName]
        for key, value of commandConstructorArguments
            cmd[key] = value
        @invoke commandClassName, cmd

    AccountRegister: (cmd, callback=null) =>
        errors = cmd.getValidationErrors()
        if errors.length > 0
            @NotifySourceClient "ErrorOccurred", errors
            return
        @_userExistsAlready cmd, (duplicateName) =>
            if duplicateName == true
                @NotifySourceClient "ErrorOccurred", "Please try a different username. An account by that name already exists."
            else
                db.store cmd, cmd.username, false, (err, user) =>
                    if err?
                        @NotifySourceClient "ErrorOccurred", err
                    else
                        @NotifySourceClient "AccountRegisterSucceeded", cmd.userName
                        if callback?
                            callback()

    Login: (cmd, notifySourceClient) =>
        # TODO crazy hack
        if global.users[cmd.userNameOrEmail]?
            cmd.externalAuth = true
        errors = cmd.getValidationErrors()
        if errors.length > 0
            callback "ErrorOccurred", errors
            return
        db.userAuthenticate cmd, (err, authenticated) =>
            if err?
                debug "It blew up:" + err
                notifySourceClient "ErrorOccurred", err
                return
            else
                if authenticated                    
                    @_onlineMembers.push(cmd.userNameOrEmail)
                    user = {userName:cmd.userNameOrEmail}
                    if cmd.externalAuth
                        user.profile = global.users[cmd.userNameOrEmail]
                    @NotifySourceClient 'LoginSucceeded', user
                else
                    if cmd.externalAuth
                        registerCmd = new commands.AccountRegister(cmd.userNameOrEmail, 
                            cmd.userNameOrEmail, cmd.userNameOrEmail, cmd.userNameOrEmail, "", true)
                        @AccountRegister registerCmd, =>
                            @NotifySourceClient "LoginSucceeded", cmd.userNameOrEmail
                    else  
                        @NotifySourceClient "LoginFailed", "Could not authenticate user with username or email of " + cmd.userNameOrEmail

    ChallengesOpen: (query) =>
        db.challengesOpenFind query, (challengesOpen) =>
            @NotifySourceClient 'ChallengesOpenSent', challengesOpen

    ChallengesCompleted: (query) =>
        db.challengesCompletedFind query, (challengesCompleted) =>
            @NotifySourceClient 'ChallengesCompletedSent', challengesCompleted

    ChallengesActive: (query) ->
        db.challengesActiveFind query, (challengesActive) =>
            @NotifySourceClient 'ChallengesActiveSent', challengesActive
                
    ChallengeCreate: (cmd) ->    
        errors = cmd.getValidationErrors()        
        console.log errors
        if errors.length > 0
            return false
        # TODO: ensure challenge by same name does not exist currently
        factory = new ChallengeStateFactory()
        challengeState = factory.create cmd.userName, cmd.name, cmd.dictionary, (challengeState) =>
            db.challengeStateStore challengeState, (err, challengeName) =>
                console.log ('ChallengeCreate error: ' + err)
                if err?
                    debug "ChallengeCreate error: " + err
                    @NotifySourceClient("ErrorOccurred", err)
                else
                    challengeJoin = new commands.ChallengeJoin(cmd.userName, cmd.name)
                    db.challengeJoinStore challengeJoin, (err, rowKey) =>
                        if err?
                            debug "_challengeJoinStore:" + err
                            @NotifySourceClient "ErrorOccurred", err
                        else           
                            debug "ChallengeCreate worked: " + challengeName
                            @Join challengeName
                            @NotifySourceClient "ChallengeCreateSucceeded", challengeName
                            #firstQuestion = @_getQuestion challengeState, 0
                            #@NotifySourceClient "ChallengeQuestionSent", firstQuestion
                            questions = db.getAllQuestions challengeState
                            @NotifySourceClient "ChallengeQuestionsSent", questions
                            @NotifyAllClients "ChallengeCreated",                            
                                userName: challengeState.userName
                                name: challengeName
                                created: challengeState.created

    ChallengeJoin: (cmd) ->
        db.findChallengeByName cmd.name, (challengeState) =>
            if challengeState?
                # TODO consider challenge security...
                @Join challengeState.name
                questions = db.getAllQuestions challengeState
                @NotifySourceClient "ChallengeQuestionsSent", questions
                db.challengeJoinStore cmd, (err, rowKey) =>
                    if err?
                        debug "_challengeJoinStore:" + err
                        @NotifySourceClient "ErrorOccurred", err
                    else
                        challengeJoin = { name: cmd.name, userName: cmd.userName, message: "#{cmd.userName} joined #{cmd.name}!" }
                        if global.users[cmd.userName]? and global.users[cmd.userName].photos? and users[cmd.userName].photos.length > 0
                            challengeJoin.userAvatarUrl = global.users[cmd.userName].photos[0].value
                        @NotifyRoomChannels challengeState.name, 'ChallengeJoined', challengeJoin
                            
                        db.findChallengeJoinsByChallengeName cmd.name, (challengeJoins) =>
                            for challengeJoin in challengeJoins
                                if users[challengeJoin.userName]? and global.users[challengeJoin.userName].photos? and users[challengeJoin.userName].photos.length > 0
                                    challengeJoin.userAvatarUrl = global.users[challengeJoin.userName].photos[0].value
                                challengeJoin.message = "#{challengeJoin.userName} joined #{challengeJoin.name}!"
                                @NotifySourceClient 'ChallengeJoined', challengeJoin

    ChallengeResume: (cmd) ->
        db.findChallengeByName cmd.name, (challengeState) =>
            if challengeState?
                @Join challengeState.name
                questions = db.getAllQuestions challengeState
                @NotifySourceClient "ChallengeQuestionsSent", questions
                challengeJoin = 
                    name: cmd.name
                    userName: cmd.userName
                    message: "#{cmd.userName} joined #{cmd.name}!"
                if global.users[cmd.userName]? and global.users[cmd.userName].photos? and global.users[cmd.userName].photos.length > 0
                    challengeJoin.userAvatarUrl = global.users[cmd.userName].photos[0].value
                @NotifySourceClient challengeState.name, 'ChallengeJoined', challengeJoin                    
                db.findChallengeJoinsByChallengeName cmd.name, (challengeJoins) =>
                    for challengeJoin in challengeJoins
                        if global.users[challengeJoin.userName]? and global.users[challengeJoin.userName].photos? and global.users[challengeJoin.userName].photos.length > 0
                            challengeJoin.userAvatarUrl = global.users[challengeJoin.userName].photos[0].value
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
                    db.find findScorings

    ChallengeWatch: (cmd) ->
        db.findChallengeByName cmd.name, (challengeState) =>
            if challengeState?
                # TODO consider challenge security...
                @Join challengeState.name + 'Watch'
                questions = db.getAllQuestions challengeState, true
                @NotifySourceClient "ChallengeQuestionsSent", questions
                @NotifySourceClient "ChallengeWatched", {name: cmd.name}
                db.findChallengeJoinsByChallengeName cmd.name, (challengeJoins) =>
                    for challengeJoin in challengeJoins
                        if global.users[challengeJoin.userName]? and global.users[challengeJoin.userName].photos? and global.users[challengeJoin.userName].photos.length > 0
                            challengeJoin.userAvatarUrl = global.users[challengeJoin.userName].photos[0].value                        
                        challengeJoin.message = "#{challengeJoin.userName} joined #{challengeJoin.name}!"
                        @NotifySourceClient 'ChallengeJoined', challengeJoin

    ChallengeSpy: (cmd) ->
        db.findChallengeByName cmd.name, (challengeState) =>
            if challengeState?
                # TODO consider challenge security...
                @Join challengeState.name + 'Spy'
                questions = db.getAllQuestions challengeState, true
                @NotifySourceClient "ChallengeQuestionsSent", questions
                @NotifySourceClient "ChallengeSpied", {name: cmd.name}
                db.findChallengeJoinsByChallengeName cmd.name, (challengeJoins) =>
                    for challengeJoin in challengeJoins
                        if global.users[challengeJoin.userName]? and global.users[challengeJoin.userName].photos? and global.users[challengeJoin.userName].photos.length > 0
                            challengeJoin.userAvatarUrl = global.users[challengeJoin.userName].photos[0].value                        
                        challengeJoin.message = "#{challengeJoin.userName} joined #{challengeJoin.name}!"
                        @NotifySourceClient 'ChallengeJoined', challengeJoin                        

    ChallengeScoreboard: (query) ->
        db.challengeScoreboardSummary query, (challengeScoreboard) =>
            @NotifySourceClient 'ChallengeScoreboardSent', challengeScoreboard

    ChallengeScoreboardAll: (query) ->
        db.challengeScoreboardSummary query, (challengeScoreboard) =>        
            @NotifyAllClients 'ChallengeScoreboardSent', challengeScoreboard

    ChallengeSubmitAnswer: (cmd) ->
        db.findChallengeByName cmd.name, (challenge) =>
            if challenge?                
                db.challengeSubmitAnswerStore cmd, (err, rowKey) =>
                    if err?
                        debug "ERROR: _challengeSubmitAnswer:" + err
                        @NotifySourceClient "ErrorOccurred", err
                    else 
                        # Send next question
                        correct = @_answerIsCorrect(cmd, challenge)
                        challengeAnswerScored = new ChallengeAnswerScored(cmd.name, cmd.index, correct, cmd.userName)
                        challengeAnswerScoredSave = new ChallengeAnswerScored(cmd.name, cmd.index, correct, cmd.userName)
                        challengeAnswerScoredSave.answer = cmd.answer                        
                        db.challengeAnswerScoredStore challengeAnswerScoredSave, =>
                            @NotifyRoomChannels cmd.name, 'ChallengeAnswerScored', challengeAnswerScored, false,
                                Spy: 
                                    answer: cmd.answer
                            challengeAnswerScored.answer = cmd.answer
                            @NotifySourceClient 'ChallengeAnswerScored', challengeAnswerScored

                            if cmd.index != (NUMBER_OF_QUESTIONS_PER_ROUND - 1)
                                return

                            db.challengeCompletedDetailsFind challenge, cmd.userName,
                                (challengeCompletedDetails) =>
                                    db.challengeCompletedDetailsStore challengeCompletedDetails, =>
                                        @NotifySourceClient 'ChallengeCompletedDetails', challengeCompletedDetails
                                        @Join challenge.name + 'Finished'
                                        @ChallengeScoreboardAll {}

    _answerIsCorrect: (challengeSubmitAnswer, challenge) ->
        index = challengeSubmitAnswer.index
        selection = challengeSubmitAnswer.answer       
        answer = challenge.roundItems[index]
        correct = false
        if selection == answer[0].word
            correct = true
        return correct

    DefinitionsImport: (definitionsImport) ->
        words = dict.allWords()
        db.definitionsStore new Definitions(words), (err, rowKey) ->
            if err?
                console.log 'Error:'
                console.log err
            else
                console.log 'Stored the definitions in: ' + rowKey

    DictionaryList: (args) ->
        db.dictionaryList args, (err, dictionaryList) =>
            unless handleError err, 'DictionaryList'
                console.log dictionaryList
                @NotifySourceClient 'DictionaryListComplete', dictionaryList

    DictionaryCreate: (dictionaryCreate) ->
        db.dictionaryCreate dictionaryCreate, (err, dictionaryCreated) =>
            unless handleError err, 'DictionaryCreate'
                console.log dictionaryCreated
                @NotifySourceClient 'DictionaryCreateComplete', dictionaryCreated

    DefinitionAdd: (definitionAdd) ->
        console.log 'add:'
        console.log definitionAdd
        db.definitionStore definitionAdd, (err) =>
            if err?
                console.log 'Error in DefinitionAdd:'
                console.log err
            @NotifySourceClient 'DefinitionAddComplete', {word:definitionAdd.word, success:true}

class Definitions
    constructor: (@words=[]) ->

handleError = (err) ->
    if err?
        console.log err
        return true
    else
        return false

module.exports =
    LearnlocityServer: LearnlocityServer