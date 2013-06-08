'use strict';

/* Directives */

angular.module('learnlocity.directives', []).
  directive('appVersion', ['version', 'blah', function(version, blah) {
    return function(scope, elm, attrs) {
      elm.text(version);
      console.log(blah);
    };
  }])
  .directive('jq:animate', function(jQueryExpression, templateElement) { 
    return function(instanceElement) {
      instanceElement.show('slow'); 
    } 
  });


