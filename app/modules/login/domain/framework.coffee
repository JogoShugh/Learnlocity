module.exports =
  modules: []

  messageHandlers: {}
  eventSubscribers: []

  addModule: (moduleName) ->
    @modules.push moduleName
    console.log 'module added:' + moduleName

  registerSubscriber: (topic, subscriber) ->
    @eventSubscribers.push 
      topic: topic
      callback: subscriber

  registerHandler: (message, handler) ->
    @messageHandlers[message] = handler

  send: (messageName, message) ->
    handler = @messageHandlers[messageName]
    if handler?
      handler message
    else 
      console.log 'No handler found for message name: ' + messageName