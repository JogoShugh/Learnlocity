window.userName = ''

angular.module('learnlocity.controllers', []).controller('SplashCtrl', ['$location', '$rootScope', ($location, $rootScope) ->
  $location.path '/home' 
]).controller('MenuCtrl', ['$scope', ($scope) ->
  $scope.name = 'learnlocity'
]).controller('HomeCtrl', ['$dialog', '$scope', '$route', '$routeParams', 'socket', ($dialog, $scope, $route, $routeParams, socket) ->
  if $routeParams.user?
    cmd = 
      userNameOrEmail: $routeParams.user
      password: $routeParams.user
    socket.send 'Login', cmd

  $scope.login = (item) ->
    d = $dialog.dialog(
      modalFade: true
      resolve:
        item: ->
          angular.copy item
    )
    d.open 'partials/login.html', 'LoginCtrl'
]).controller('LoginCtrl', ['$rootScope', '$scope', 'socket', 'dialog', 'item', ($rootScope, $scope, socket, dialog, item) ->
  $scope.item = item
  $scope.submit = ->
    cmd =
      userNameOrEmail: $scope.email
      password: $scope.password
    socket.send 'Login', cmd
    dialog.close 'ok'

]).controller('MainMenuCtrl', ['$scope', '$rootScope', ($scope, $rootScope) ->
  if window.profile.photos? and window.profile.photos.length > 0
    $rootScope.userAvatarUrl = window.profile.photos[0].value
  else 
    $rootScope.userAvatarUrl = ''

]).controller('ChallengeScoreboardCtrl', ['$scope', '$rootScope', 'socket', ($scope, $rootScope, socket) ->
  socket.send 'ChallengeScoreboard',
    userName: window.userName
  $scope.setDetailsVisible = (challenge) ->
    challenge.detailsVisible = true

]).controller('GroupChallengeCtrl', ['$rootScope', '$scope', 'apiFactory', 'socket', '$location', ($rootScope, $scope, apiFactory, socket, $location) ->
  api = apiFactory $scope

  challenges = []
  $scope.challenges = challenges
  $scope.challengeName  = 
    name: ''  
  $scope.dictionaryList = ['Select a dictionary']
  $scope.selectedDictionary = {name:$scope.dictionaryList[0]}
  api.send 'DictionaryList', {}, (dictionaryList) ->
    titles = _.pluck dictionaryList, 'title'
    titles.unshift 'Select a dictionary'    
    $scope.dictionaryList = titles
    $scope.selectedDictionary = {name:$scope.dictionaryList[0]}

  $scope.createChallenge = ->
    if $scope.selectedDictionary.name != 'Select a dictionary'
      console.log 'Challenge name: ' + $scope.challengeName.name
      cmd =      
        userName: window.userName
        name: $scope.challengeName.name
        dictionary: $scope.selectedDictionary.name
        isOpen: true
        isGroup: true
      console.log cmd
      socket.send 'ChallengeCreate', cmd    
  
  challengesCmd =
    userName: window.userName

  $scope.challengesOpenPage = 1
  $scope.challengesOpenNewer = ->
    unless $scope.challengesOpenPage is 1 then --$scope.challengesOpenPage
    socket.send 'ChallengesOpen',
      userName: window.userName
      page: $scope.challengesOpenPage

  $scope.challengesOpenOlder = ->
    socket.send 'ChallengesOpen',
      userName: window.userName
      page: ++$scope.challengesOpenPage

  $scope.isLastChallengeOpenPage = ->
    return $scope.challengesOpenPage >= $scope.challengesOpen.pageCount

  $scope.challengesActivePage = 1
  $scope.challengesActiveNewer = ->
    unless $scope.challengesActivePage is 1 then --$scope.challengesActivePage
    socket.send 'ChallengesActive',
      userName: window.userName
      page: $scope.challengesActivePage

  $scope.challengesActiveOlder = ->
    socket.send 'ChallengesActive',
      userName: window.userName
      page: ++$scope.challengesActivePage

  $scope.challengesCompletedPage = 1
  $scope.challengesCompletedNewer = ->
    unless $scope.challengesCompletedPage is 1 then --$scope.challengesCompletedPage
    socket.send 'ChallengesCompleted',
      userName: window.userName
      page: $scope.challengesCompletedPage

  $scope.challengesCompletedOlder = ->
    socket.send 'ChallengesCompleted',
      userName: window.userName
      page: ++$scope.challengesCompletedPage            

  $scope.resume = (challengeName) ->
    console.log challengeName
    cmd =
      name: challengeName
      userName: window.userName
    socket.send 'ChallengeResume', cmd

  $scope.join = (challengeName) ->
    cmd =
      name: challengeName
      userName: window.userName
    socket.send 'ChallengeJoin', cmd

  $scope.watch = (challengeName) ->
    cmd =
      name: challengeName
      userName: window.userName
    socket.send 'ChallengeWatch', cmd

  $scope.spy = (challengeName) ->
    cmd =
      name: challengeName
      userName: window.userName
    socket.send 'ChallengeSpy', cmd

  $scope.view = (challengeName) ->
    $location.path('/challengeCompletedDetails').search(challengeName: challengeName)

  $scope.challengesOpenNewer()
  $scope.challengesActiveNewer()
  $scope.challengesCompletedNewer()

]).controller('ChallengePlayCtrl', ['$rootScope', '$scope', '$location', '$route', '$routeParams', 'socket', ($rootScope, $scope, $location, $route, $routeParams, socket) ->
  challengeName = $routeParams.challengeName  
  challenge = getChallengeByName challengeName
  $scope.challenge = challenge.challengePlay
  $scope.scoreBoard = challenge.scoreBoard
  challenge.sendNextQuestion()
]).controller('ChallengeCompletedCtrl', ['$scope', '$rootScope', '$route', '$routeParams', ($scope, $rootScope, $route, $routeParams) ->
  challengeName = $routeParams.challengeName
  for challenge in $rootScope.challengesCompleted.items
    if challenge.details.name is challengeName
      console.log 'Found:'
      console.log challenge
      $scope.challenge = challenges
]).controller('DictionarySelectCtrl', ['$scope', 'apiFactory', '$location', ($scope, apiFactory, $location) ->
  $scope.dictionaryName = {name:''}
  $scope.dictionaryCreate = ->
    cmd = 
      title: $scope.dictionaryName.name
      userName: window.userName
    api.send 'DictionaryCreate', cmd, (dictionaryCreated) ->
      console.log 'Created new dictionary:'
      console.log dictionaryCreated

  api = apiFactory $scope
  $scope.dictionaryList = 
    items: []
  api.send 'DictionaryList', {page:1}, (dictionaryList) ->
    $scope.dictionaryList = dictionaryList

  $scope.page = 1
  $scope.newer = ->
    unless $scope.page is 1 then --$scope.page
    api.send 'DictionaryList', {page:$scope.page}, (dictionaryList) ->
      $scope.dictionaryList = dictionaryList

  $scope.older = ->
    api.send 'DictionaryList', {page:++$scope.page}, (dictionaryList) ->
      $scope.dictionaryList = dictionaryList      

  $scope.select = (dictionary) ->
    $location.path('/definitionAdd').search(dictionary: dictionary)      

]).controller('DefinitionAddCtrl', ['$scope', 'apiFactory', '$route', '$routeParams', '$location', ($scope, apiFactory, $route, $routeParams, $location) ->
  api = apiFactory $scope
  $scope.dictionary = $routeParams.dictionary || $location.path '/dictionarySelect'
  $scope.definitionAdd = ->
    if $scope.dictionary?
      cmd = 
        word: $scope.word
        definition: $scope.definition
        dictionary: $scope.dictionary
      api.send 'DefinitionAdd', cmd, (definitionAdded) ->
        console.log 'A definition was added successfully:'
        console.log definitionAdded
])


'''
  $rootScope.$on 'ChallengeSubmitAnswerCorrectForFinishedUsers', (event, message) ->
    answer =
      className: 'answerCorrect normColor'
      userName: message.userName
      answer: message.answer

  $rootScope.$on 'ChallengeSubmitAnswerIncorrectForFinishedUsers', (event, message) ->
    answer =
      className: 'answerIncorrect normColor'
      userName: message.userName
      answer: message.answer

  $rootScope.$on 'ChallengeCompleted', (event, message) ->
    console.log 'Got ChallengedCompleted'
    #$location.path '/challengeCompleted' 
'''    