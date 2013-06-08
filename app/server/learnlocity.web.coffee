express = require('express')
app = express()
http = require 'http'
LearnlocityServer = require('./learnlocityServer').LearnlocityServer
_ = require './myunderscore'
server = http.createServer app
io = require('socket.io').listen server

passport = require 'passport'
FacebookStrategy = require('passport-facebook').Strategy

FACEBOOK_APP_ID = '145122539006776'
FACEBOOK_APP_SECRET = '94eb7e44b1945f31c2cbfb37dcf1f3ff'

global.users = {}

passport.use new FacebookStrategy {
    clientID: FACEBOOK_APP_ID,
    clientSecret: FACEBOOK_APP_SECRET,
    callbackURL: 'http://localhost:8000/auth/facebook/callback'
    profileFields: ['id', 'displayName', 'username', 'photos', 'email', 'name', 'profileUrl']
  }, (accessToken, refreshToken, profile, done) ->
        console.log profile   
        done(null, profile)

passport.serializeUser (user, done) ->
    users[user.username] = user
    done null, user.username

passport.deserializeUser (id, done) ->
    user = users[id]
    done null, user

app.configure ->
    app.use '/app', express.static(__dirname + '/../')
    app.use passport.initialize()
    app.use passport.session()
    app.use app.router

app.get '/auth/facebook', passport.authenticate 'facebook'

app.get '/auth/facebook/callback', passport.authenticate('facebook', 
    { failureRedirect: '/auth/facebook' }), (req, res) ->
        console.log 'res user:'
        console.log req.user
        console.log '-----'
        res.redirect '/app/index.html#/?user=' + req.user.username

server.listen 8000

io.sockets.on 'connection', (socket) ->
    console.log 'started'
    learnlocityServer = new LearnlocityServer

    sourceClientId = socket.id
    
    notifyAllClients = (topic, data) ->
        io.sockets.emit 'message', [topic, data]

    notifySourceClient = (topic, data) ->
        io.sockets.socket(sourceClientId).emit 'message', [topic, data]
    
    join = (room) ->
       socket.join room

    notifyRoom = (room, topic, data, includeSelf=false) ->
        if includeSelf
            io.sockets.in(room).emit 'message', [topic, data]
        else
            socket.broadcast.to(room).emit 'message', [topic, data]

    learnlocityServer.NotifyAllClients = notifyAllClients
    learnlocityServer.NotifySourceClient = notifySourceClient
    learnlocityServer.Join = join
    learnlocityServer.NotifyRoom = notifyRoom
    learnlocityServer.NotifyRoomChannels = (room, topic, data, includeSelf=false, mixInPropertiesMap=null) ->        
        @NotifyRoom room, topic, data, includeSelf
        for subChannel in ['Watch', 'Spy']
            localData = _.clone data
            if mixInPropertiesMap? and mixInPropertiesMap[subChannel]?
                _.extend localData, mixInPropertiesMap[subChannel]
            @NotifyRoom room + subChannel, topic, localData, includeSelf

    socket.on 'message', (data) ->    
        commandClassName = data[0]
        commandConstructorArguments = data[1]
        console.log ('socket.on message: ' + commandClassName + " -> " + commandConstructorArguments)    
        learnlocityServer.process commandClassName, commandConstructorArguments