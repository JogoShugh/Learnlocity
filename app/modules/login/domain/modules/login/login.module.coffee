fw = require '../../framework'

'''
class LoginModule
  constructor: (registerHandler, registerSubscriber) ->
    console.log 'handler:'
    console.log registerHandler
    console.log 'subscriber:'
    console.log registerSubscriber
'''

fw.registerHandler 'Login', (loginCommand) ->
  console.log 'here is the command:' + loginCommand

fw.registerSubscriber 'LoginCompleted', (loginCompleted) ->
  console.log 'it completed:' + loginCompleted