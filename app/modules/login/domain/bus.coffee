module.exports =
  messageTypes: {}
  messageHandlers: {}
  eventSubscribers: []

  registerMessage: (messageName, messageConstructor) ->
    @messageTypes[messageName] = messageConstructor

  listen: (topic, subscriberCallback) ->
    @eventSubscribers.push 
      topic: topic
      callback: subscriberCallback

  on: (message, callback) ->
    @messageHandlers[message] = callback

  send: (messageName, message) ->
    handler = @messageHandlers[messageName]
    if handler?
      handler message
    else
      console.log 'No handler found for message name: ' + messageName

  processMessage: (messageName, messageConstructorArguments) ->
    # TODO: error trap
    cmd = new @messageTypes[messageName]
    for key, value of messageConstructorArguments
        cmd[key] = value
    @send messageName, cmd