module.exports =
  modules: []

  addModule: (moduleName) ->
    @modules.push moduleName
    console.log 'module added:' + moduleName

  registerSubscriber: (topic, subscriber) ->
    console.log 'reg subscriber:'
    console.log topic
    console.log subscriber

  registerHandler: (message, handler) ->
    console.log 'reg handler'
    console.log message
    console.log handler