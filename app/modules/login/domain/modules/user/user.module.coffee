fw = require '../../framework'

'''
class LoginModule
  constructor: (registerHandler, registerSubscriber) ->
    console.log 'handler:'
    console.log registerHandler
    console.log 'subscriber:'
    console.log registerSubscriber
'''
fw.addModule 'user'

console.log 'handler:'
console.log fw.registerHandler
console.log 'subscriber:'
console.log fw.registerSubscriber