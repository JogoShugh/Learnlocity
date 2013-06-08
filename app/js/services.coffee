class ChallengeState
    constructor: (@socket, @challengeName, creatorName) ->      
      @currentChallengeQuestionIndex = 0
      @watchingOnly = true
      @spying = false

      if creatorName?
        @creatorName = creatorName      
      
      @scoreBoard = new ScoreBoard @socket, @challengeName, @creatorName

      if creatorName?
        @setWatchingOnly false

      @challengePlay =       
        hasAnswered: false 
        completed: false
        challengeName: @challengeName
        isAnswered: (player, index) ->
          answer = player.answers[index];
          if answer?          
            return answer.answered
          else
            return false
        getAnswerClass: (player, index) ->
          answer = player.answers[index]
          cssClass = (if answer? then 'label ' + (if answer.correct then 'label-success' else 'label-important') else '')
          return cssClass
        getUserAvatarUrl: (playerName) =>
          if playerName is window.userName and window.profile.photos? and window.profile.photos.length > 0
            return window.profile.photos[0].value
          else
            return @scoreBoard.players[playerName].userAvatarUrl

        hasUserAvatarUrl: (playerName) =>        
          if @scoreBoard.players[playerName].userAvatarUrl?
            return true  
          return playerName is window.userName and window.profile.photos? and window.profile.photos.length

    join: (user) ->
      @scoreBoard.makeEmptyPlayerIfNotExist user.userName
      if user.userAvatarUrl?        
        @scoreBoard.players[user.userName].userAvatarUrl = user.userAvatarUrl
      if user.userName is window.userName
        @setWatchingOnly false

    setWatchingOnly: (isWatchingOnly) ->
      @watchingOnly = isWatchingOnly
      # TODO: very odd:
      @scoreBoard.watchingOnly = isWatchingOnly
      @scoreBoard.updateDefinitionVisibility()

    setSpying: (isSpying) ->
      @spying = isSpying
      # TODO: very odd:
      @scoreBoard.spying = isSpying
      @scoreBoard.watchingOnly = false
      @scoreBoard.updateDefinitionVisibility()

    setChallengeQuestions: (challengeQuestions) ->
      @challengeQuestions = challengeQuestions
      @scoreBoard.setChallengeQuestions challengeQuestions
      @scoreBoard.updateDefinitionVisibility()
      @challengePlay.questionCount = challengeQuestions.length

    setCurrentQuestionIndex: (challengeQuestion) ->
      if @currentChallengeQuestionIndex < @challengeQuestions.length
        @currentChallengeQuestionIndex = challengeQuestion.index

    sendNextQuestion: () ->
      if @currentChallengeQuestionIndex < @challengeQuestions.length
        question = @challengeQuestions[@currentChallengeQuestionIndex]
        @socket.invoke 'ChallengeQuestionSent', question
        @currentChallengeQuestionIndex++

    applyQuestion: (challengeQuestion) ->
      definition = challengeQuestion.definition
      choices = challengeQuestion.choices
      unless @watchingOnly
        @scoreBoard.applyQuestionDefinition challengeQuestion.index
      @challengePlay.answerDefinition = challengeQuestion.definition
      @challengePlay.questionIndex = challengeQuestion.index + 1
      for i in [0..challengeQuestion.choices.length]
        @challengePlay['answer' + i] = challengeQuestion.choices[i]

      @challengePlay.answer = (index) =>
        selection = choices[index]
        answer =
          name: challengeQuestion.name
          index: challengeQuestion.index
          answer: selection
          userName: window.userName
        @socket.send 'ChallengeSubmitAnswer', answer
        @scoreBoard.saveOwnAnswerSubmission challengeQuestion.index, selection
        @sendNextQuestion()

    updateScores: (scoredAnswer) ->
      @scoreBoard.updateScores scoredAnswer
      if scoredAnswer.userName is window.userName
        @challengePlay.hasAnswered = true


class ScoreBoard
  constructor: (@socket, @challengeName, @creatorName) ->
    @watchingOnly = true
    @spying = false

    @summary =
      playersCount: 0
      answersCount: 0
      answersCorrect: 0
      answersAttempted: 0
      percentCorrect: 0
      points: 0
      pointsPossible: 0
    @questions = []
    @players = {}
    @lastResultClass = ''
    @lastResultAnswer = ''
    @answersCorrectCount = 0
    @answersAttemptCount = 0
    @answersCorrectPercentage = 0

    if @creatorName?
      @makeEmptyPlayerIfNotExist @creatorName

  makeEmptyPlayerIfNotExist: (playerName) ->
    if not @players[playerName]?
      @players[playerName] =
        answersCorrectCount: 0
        answersAttemptCount: 0
        answersCorrectPercentage: 0
        points: 0
        answers: @makeEmptyAnswers(3)
      if playerName is window.userName
        @players[playerName].answerSubmissions = []

  makeScoreBoardQuestions: (challengeQuestions) ->
    questions = []
    for challengeQuestion in challengeQuestions
      question =
        definition: 'pending'
        answersCorrect: 0
        answersAttempted: 0
        percentCorrect: 0
        points: 0
      questions.push question
    return questions

  makeEmptyAnswers: (count) ->
    answers = []
    for i in [0..count-1]
      answers.push 
        correct: false
        answered: false
        answer: '--------'
    return answers

  setChallengeQuestions: (challengeQuestions) ->
    @challengeQuestions = challengeQuestions
    @questions = @makeScoreBoardQuestions challengeQuestions

  applyQuestionDefinition: (questionIndex) ->
    if @questions[questionIndex]?
      @questions[questionIndex].definition = @challengeQuestions[questionIndex].definition

  saveOwnAnswerSubmission: (questionIndex, answer) ->
    @players[window.userName].answerSubmissions[questionIndex] = answer

  updateIfOwnAnswer: (scoredAnswer) ->
    if scoredAnswer.userName is window.userName
      labelSuccess = 'label label-success'
      labelFailure = 'label label-important'
      if scoredAnswer.correct      
        @lastResultClass = labelSuccess
      else
        @lastResultClass = labelFailure
      @lastResultAnswer = scoredAnswer.answer

  updateScores: (scoredAnswer) ->
    @updateIfOwnAnswer scoredAnswer

    answer = @players[scoredAnswer.userName].answers[scoredAnswer.index]
    if (@spying and scoredAnswer.answer) or (window.userName is scoredAnswer.userName)
      answer.answer = scoredAnswer.answer
    answer.correct = scoredAnswer.correct
    answer.answered = true

    if (not @spying) and window.userName? and @players[window.userName]?
      myScoredAnswer = @players[window.userName].answers[scoredAnswer.index]
      if myScoredAnswer.answered
        for playerName, player of @players
          if playerName != window.userName
            playerAnswer = player.answers[scoredAnswer.index]
            if playerAnswer? and playerAnswer.correct and myScoredAnswer.correct
              playerAnswer.answer = myScoredAnswer.answer
    # Recalc the summaries
    totalAnswersCorrect = 0
    totalAnswersAttempted = 0
    totalPoints = 0
    
    playerScores = {}
    for playerName of @players
      playerScores[playerName] =
        answersAttemptCount: 0
        answersCorrectCount: 0

    for question, questionIndex in @questions
      answersCorrect = 0
      answersAttempted = 0      
      for playerName, player of @players
        playerAnswer = player.answers[questionIndex]
        if playerAnswer.answered
          answersAttempted++
          playerScores[playerName].answersAttemptCount++
          if playerAnswer.correct
            answersCorrect++
            playerScores[playerName].answersCorrectCount++
      @updateDefinitionVisibility()
      question.points = answersCorrect * 100
      question.answersCorrect = answersCorrect
      question.answersAttempted = answersAttempted
      totalAnswersCorrect += answersCorrect
      totalAnswersAttempted += answersAttempted
      totalPoints += question.points
    for playerName, player of @players
      player.answersAttemptCount = playerScores[playerName].answersAttemptCount
      player.answersCorrectCount = playerScores[playerName].answersCorrectCount
      player.points = player.answersCorrectCount * 100
      if playerName is window.userName
        @answersCorrectCount = player.answersCorrectCount
        @answersAttemptCount = player.answersAttemptCount
        if player.answersCorrectCount > 0          
          @answersCorrectPercentage = (100 * (player.answersCorrectCount / player.answersAttemptCount)).toFixed(0)
        @points = player.points
    @summary.points = totalPoints
    @summary.answersCorrect = totalAnswersCorrect
    @summary.answersAttempted = totalAnswersAttempted

  updateDefinitionVisibility: () ->
    for question, questionIndex in @questions
      if @spying
        question.answer = @challengeQuestions[questionIndex].answer
      answersAttempted = 0
      playerCount = 0
      for playerName, player of @players
        playerCount++
        playerAnswer = player.answers[questionIndex]
        if playerAnswer.answered
          answersAttempted++
      console.log 'answersattempted:' + answersAttempted
      if answersAttempted > 0 or @spying 
        if answersAttempted >= playerCount or @spying
          console.log 'Applying definition now'
          @applyQuestionDefinition questionIndex
          if @watchingOnly
            for playerName, player of @players
              playerAnswer = player.answers[questionIndex]
              if playerAnswer.correct
                playerAnswer.answer = @challengeQuestions[questionIndex].answer

  getOwnAnswerSubmissionIfExists: (questionIndex) ->
    if @players[window.userName]? and @players[window.userName].answerSubmissions?
      return @players[window.userName].answerSubmissions[questionIndex]
    return null
(->
  app = angular.module('learnlocity.services', []).value('version', '0.1')
  app.service 'socket', ['$rootScope', '$location', ($rootScope, $location) ->
    socket = io.connect('http://localhost:8000')
    handlerDeregistrationCallbacks = []

    socketWrapper =
      on: (topic, callback) ->
        socket.on topic, ->
          args = arguments
          $rootScope.$apply ->
            callback.apply socket, args

      emit: (topic, data, callback) ->
        socket.emit topic, data, ->
          args = arguments
          $rootScope.$apply ->
            callback.apply socket, args if callback

      send: (topic, data) ->
        console.log 'send: ' + topic + ' -> ' + data
        @emit 'message', [topic, data]

      invoke: (messageClassName, message) ->
        console.log 'recv: ' + messageClassName + ' -> '
        console.log message
        $rootScope.$broadcast messageClassName, message

      handle: (topic, handler) ->
        deregistrationCallback = $rootScope.$on topic, (event, message) ->
          handler message, $location, $rootScope
        return deregistrationCallback

    socketWrapper
  ]
  app.factory 'apiFactory', ['$rootScope', 'socket', ($rootScope, socket) ->
    return (scope) ->
      handlerDeregistrationCallbacks = {}
      scope.$on '$destroy', ->
        for responseTopicName, deregistrationCallback of handlerDeregistrationCallbacks
          deregistrationCallback()
      obj = send: (topic, data, handler, responseTopicName='') ->
          if responseTopicName is ''
            responseTopicName = topic + 'Complete'
          if not handlerDeregistrationCallbacks[responseTopicName]?
            deregistrationCallback = socket.handle responseTopicName, handler
            handlerDeregistrationCallbacks[responseTopicName] = deregistrationCallback
          socket.send topic, data
      return obj
  ]  
  app.run ($rootScope, $location, socket) ->
    $rootScope.challengesOpen = []
    $rootScope.currentDefinition = 

    $rootScope.activeChallenges = {}
    $rootScope.openChallenge = (challengeName) ->
      activeChallenge = $rootScope.activeChallenges[challengeName]
      if activeChallenge?
        $location.path('/challengePlay').search(challengeName: challengeName)
      else
        alert 'You are not active in ' + challengeName
    $rootScope.home = () ->
      $location.path '/groupChallenge'

    commandHandler = (name, handler) ->
      $rootScope.$on name, (event, message) ->
        console.log 'Command handler: ' + name
        console.log message
        handler message, $location, $rootScope

    commandHandler 'LoginSucceeded', (message, $location, $rootScope) ->
      window.userName = message.userName
      $rootScope.loggedIn = true
      $rootScope.loggedInUserName = message.userName
      if message.profile?
        window.profile = message.profile
      else
        window.profile = {}
      $location.path '/mainMenu'

    commandHandler 'ChallengesOpenSent', (message, $location, $rootScope) ->
      $rootScope.challengesOpen = message

    commandHandler 'ChallengeCreated', (message) ->
      $rootScope.challengesOpen.items.unshift message

    commandHandler 'ChallengesActiveSent', (message, $location, $rootScope) ->
      $rootScope.challengesActive = message

    commandHandler 'ChallengesCompletedSent', (message, $location, $rootScope) ->
      $rootScope.challengesCompleted = message

    commandHandler 'ChallengeScoreboardSent', (message, $location, $rootScope) ->
      for item in message.items
        item.detailsVisible = false
      $rootScope.scoreboard = message

    window.challenges = {}

    createChallenge = (challengeName, creatorName) ->
      if window.challenges[challengeName]?
        return window.challenges[challengeName]
      else 
        window.challenges[challengeName] = new ChallengeState socket, challengeName, creatorName
      return window.challenges[challengeName]

    createChallengeFromJoin = (challengeJoin) ->
      challengeName = challengeJoin.name
      if window.challenges[challengeName]?
        return window.challenges[challengeName]
      else 
        window.challenges[challengeName] = new ChallengeState socket, challengeName
      return window.challenges[challengeName]

    getChallengeByName = (challengeName) ->
      return window.challenges[challengeName]
    window.getChallengeByName = getChallengeByName

    commandHandler 'ChallengeCreateSucceeded', (message, $location, $rootScope) ->
      createChallenge message, window.userName
      $rootScope.activeChallenges[message] = message

    commandHandler 'ChallengeQuestionsSent', (message, $location, $rootScope) ->
      challengeName = message[0].name
      challenge = getChallengeByName challengeName
      if not challenge?
        challenge = createChallenge challengeName, null
      challenge.setChallengeQuestions message
      $location.path('/challengePlay').search(challengeName: challengeName)

    commandHandler 'ChallengeQuestionSent', (challengeQuestion, $location, $rootScope) ->
      if challengeQuestion
        challengeName = challengeQuestion.name
        challenge = getChallengeByName challengeName
        challenge.applyQuestion challengeQuestion

    commandHandler 'ChallengeJoined', (message, $location, $rootScope) ->
      challenge = getChallengeByName message.name
      if challenge?
        challenge.join message
      else
        challenge = createChallengeFromJoin message
        challenge.join message
        if message.userName is window.userName
          $rootScope.activeChallenges[message.name] = message.name
        $location.path('/challengePlay').search(challengeName: message.name)

    commandHandler 'ChallengeWatched', (message) ->
      challenge = getChallengeByName message.name
      if challenge?
        challenge.setWatchingOnly true

    commandHandler 'ChallengeSpied', (message) ->
      challenge = getChallengeByName message.name
      if challenge?
        challenge.setSpying true

    commandHandler 'ChallengeAnswerScored', (message, $location, $rootScope) ->
      challengeName = message.name
      challenge = getChallengeByName challengeName
      challenge.updateScores message

    commandHandler 'ChallengerTotalsUpdated', (message, $location, $rootScope) ->
      challengeName = message.name
      challenge = getChallengeByName challengeName
      player = challenge.scoreBoard.players[message.userName]
      player.answersCorrectCount = message.answersCorrectCount
      player.answersAttemptCount = message.answersAttemptCount
      player.answersCorrectPercentage = message.answersCorrectPercentage
      player.points = player.answersCorrectCount * 100

    commandHandler 'ChallengeCompletedDetails', (message, $location, $rootScope) ->
      challengeName = message.details.name
      challenge = getChallengeByName challengeName
      challenge.challengePlay.completed = true
)()