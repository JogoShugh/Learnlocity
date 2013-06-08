'use strict';

angular.module('learnlocity', ['learnlocity.filters', 'learnlocity.services', 'learnlocity.directives', 'learnlocity.controllers', 'ui.bootstrap'])
  .config(['$routeProvider', function($routeProvider) {
    $routeProvider.when('/', {templateUrl: 'partials/splash.html', controller: 'SplashCtrl'});
    $routeProvider.when('/home', {templateUrl: 'partials/home.html', controller: 'HomeCtrl'});
    $routeProvider.when('/mainMenu', {templateUrl: 'partials/mainMenu.html', controller: 'MainMenuCtrl'});
    $routeProvider.when('/groupChallenge', {templateUrl: 'partials/groupChallenge.html', controller: 'GroupChallengeCtrl'});
    $routeProvider.when('/challengePlay', {templateUrl: 'partials/challengePlay.html', controller: 'ChallengePlayCtrl'});
    $routeProvider.when('/challengeCompletedDetails', {templateUrl: 'partials/challengeCompletedDetails.html', controller: 'ChallengeCompletedCtrl'});
    $routeProvider.when('/scoreboard', {templateUrl: 'partials/scoreboard.html', controller: 'ChallengeScoreboardCtrl'});   
    $routeProvider.when('/dictionarySelect', {templateUrl: 'partials/dictionarySelect.html', controller: 'DictionarySelectCtrl'});
    $routeProvider.when('/definitionAdd', {templateUrl: 'partials/definitionAdd.html', controller: 'DefinitionAddCtrl'});
    $routeProvider.otherwise({redirectTo: '/'});
  }])
  .run(function(socket, $rootScope) {
    socket.on('error', function(errors) {
      console.log('Errors:')
      console.log(errors);
    });
    socket.on('message', function (data) {
      var messageClassName = data[0];
      var message = data[1];
      socket.invoke(messageClassName, message);
    });        
  });
  