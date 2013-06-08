importer = require './importer'
importer(require('./utils'))

module.exports =
    AccountRegister: class AccountRegister
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

    Login: class Login
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

    ChallengesOpen: class ChallengesOpen
        constructor: (@userName) ->

    ChallengesCompleted: class ChallengesCompleted
        constructor: (@userName) ->

    ChallengesActive: class ChallengesActive
        constructor: (@userName) ->

    ChallengesSendChatMessage: class ChallengeSendChatMessage
        constructor: (@userName="", @message='', @dateTime=null) ->

    ChallengeCreate: class ChallengeCreate
        constructor: (@userName='', @name='', @dictionary='', @isOpen=false, @isGroup=false) ->

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

            sv.field('Dictionary', @dictionary)
                .notEmpty()
                .max(100)
                .min(5)

            return sv.errors    

    ChallengeJoin: class ChallengeJoin
        constructor: (@userName='', @name='') ->
            @created = new Date()

    ChallengeResume: class ChallengeResume
        constructor: (@userName='', @name='') ->

    ChallengeSpy: class ChallengeSpy
        constructor: (@userName='', @name='') ->

    ChallengeWatch: class ChallengeWatch
        constructor: (@userName='', @name='') ->

    ChallengeQuestionByIndex: class ChallengeQuestionByIndex
        constructor: (@name='', @index=0) ->

    ChallengeQuestion: class ChallengeQuestion
        constructor: (@name='', @index=0, @definition='', @choices=[], answer) ->
            if answer?
                @answer = answer

    ChallengeSubmitAnswer: class ChallengeSubmitAnswer
        constructor: (@name='', @userName='', @index=0, @answer='') ->

    ChallengeSubmitAnswerResponse: class ChallengeSubmitAnswerResponse
        constructor: (@challengeName='', @challengePlayerName='', @choice='', @result=false, @scoreStatusInfo=null) ->

    ScoreStatusInfo: class ScoreStatusInfo
        constructor: (@answersAttemptCount=0, @answersCorrectCount=0,
            @answersPercentage=0.0, @streakCount=0, @streakIsCorrect=false) ->

    ChallengeScoreboard: class ChallengeScoreboard
        constructor: (@userName='') ->

    DefinitionsImport: class DefinitionsImport
        constructor: () ->

    DefinitionAdd: class DefinitionAdd
        constructor: (@word='', @definition='', @dictionary='') ->

    DictionaryList: class DictionaryList
        constructor: (@page=1) ->

    DictionaryCreate: class DictionaryCreate
        constructor: (@title='', @userName='') ->