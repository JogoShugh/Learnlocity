bus = require './bus'
# TODO fix this hack
db = require './db'

db.connect()

class LearnlocityService
  constructor: ->
    # These all get "setter injected":
    @NotifySourceClient = null
    @NotifyAllClients = null
    @Join = null
    @NotifyRoom = null
    @_challenges = []
    @_onlineMembers = []

  processMessage: (messageName, messageConstructorArguments) ->
    bus.processMessage messageName, messageConstructorArguments

svc = new LearnlocityService()
module.exports = svc

# Load the modules which depend on service
require './modules'