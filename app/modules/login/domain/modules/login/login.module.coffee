bus = require '../../bus'
utils = require '../../utils'
service = require '../../service'
queries = require './queries'

class Login
  constructor: (@userNameOrEmail='', @password='', @externalAuth=false) ->

  getValidationErrors: ->
    sv = new utils.StringValidator

    sv.field("Username or Email", @userNameOrEmail)
      .notEmpty()
      .max(100)
      .min(4)

    if @externalAuth
      return sv.errors

    sv.field("Password", @password)
      .notEmpty()
      .max(50)
      .min(8)

    return sv.errors

bus.registerMessage 'Login', Login

bus.on 'Login', (cmd) ->
  console.log 'here is the command:' + cmd
  if global.users[cmd.userNameOrEmail]?
    cmd.externalAuth = true

  errors = cmd.getValidationErrors()
  if errors.length > 0
    console.log 'ErrorOccurred'
    console.log errors
    return
  console.log errors
  queries.authenticate cmd, (err, authenticated) =>
    if err?
      debug "It blew up:" + err
      service.NotifySourceClient "ErrorOccurred", err
      return
    else
      if authenticated
        console.log 'svc:'
        console.log service
        service._onlineMembers.push(cmd.userNameOrEmail) # TODO hack
        user = userName: cmd.userNameOrEmail
        if cmd.externalAuth
          user.profile = global.users[cmd.userNameOrEmail]
        service.NotifySourceClient 'LoginSucceeded', user
      else
        if cmd.externalAuth
          console.log 'Ex auth not supported yet'
          '''
          registerCmd = new commands.AccountRegister(cmd.userNameOrEmail,
            cmd.userNameOrEmail, cmd.userNameOrEmail,
              cmd.userNameOrEmail, "", true)
          @AccountRegister registerCmd, =>
            @NotifySourceClient "LoginSucceeded", cmd.userNameOrEmail
          '''
        else
          service.NotifySourceClient "LoginFailed",
            "Could not authenticate user with username or email of "
            + cmd.userNameOrEmail