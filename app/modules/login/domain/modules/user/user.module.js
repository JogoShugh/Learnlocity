// Generated by CoffeeScript 1.3.3
(function() {
  var fw;

  fw = require('../../framework');

  'class LoginModule\n  constructor: (registerHandler, registerSubscriber) ->\n    console.log \'handler:\'\n    console.log registerHandler\n    console.log \'subscriber:\'\n    console.log registerSubscriber';


  fw.addModule('user');

  console.log('handler:');

  console.log(fw.registerHandler);

  console.log('subscriber:');

  console.log(fw.registerSubscriber);

}).call(this);
