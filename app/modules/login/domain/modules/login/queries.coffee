db = require '../../db'

module.exports =
  authenticate: (credentials, callback) ->
    query =
      from: 'AccountRegister'
      where:
        $and: [
          { password : credentials.password },
          $or: [
            {userName: credentials.userNameOrEmail},
            {email: credentials.userNameOrEmail}
          ]
        ]
      select: 'userName'
    db.find query, (users) ->
      exists = users.length > 0
      callback null, exists