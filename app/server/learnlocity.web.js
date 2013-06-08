// Generated by CoffeeScript 1.3.3
(function() {
  var FACEBOOK_APP_ID, FACEBOOK_APP_SECRET, FacebookStrategy, LearnlocityServer, app, express, http, io, passport, server, _;

  express = require('express');

  app = express();

  http = require('http');

  LearnlocityServer = require('./learnlocityServer').LearnlocityServer;

  _ = require('./myunderscore');

  server = http.createServer(app);

  io = require('socket.io').listen(server);

  passport = require('passport');

  FacebookStrategy = require('passport-facebook').Strategy;

  FACEBOOK_APP_ID = '145122539006776';

  FACEBOOK_APP_SECRET = '94eb7e44b1945f31c2cbfb37dcf1f3ff';

  global.users = {};

  passport.use(new FacebookStrategy({
    clientID: FACEBOOK_APP_ID,
    clientSecret: FACEBOOK_APP_SECRET,
    callbackURL: 'http://localhost:8000/auth/facebook/callback',
    profileFields: ['id', 'displayName', 'username', 'photos', 'email', 'name', 'profileUrl']
  }, function(accessToken, refreshToken, profile, done) {
    console.log(profile);
    return done(null, profile);
  }));

  passport.serializeUser(function(user, done) {
    users[user.username] = user;
    return done(null, user.username);
  });

  passport.deserializeUser(function(id, done) {
    var user;
    user = users[id];
    return done(null, user);
  });

  app.configure(function() {
    app.use('/app', express["static"](__dirname + '/../'));
    app.use(passport.initialize());
    app.use(passport.session());
    return app.use(app.router);
  });

  app.get('/auth/facebook', passport.authenticate('facebook'));

  app.get('/auth/facebook/callback', passport.authenticate('facebook', {
    failureRedirect: '/auth/facebook'
  }), function(req, res) {
    console.log('res user:');
    console.log(req.user);
    console.log('-----');
    return res.redirect('/app/index.html#/?user=' + req.user.username);
  });

  server.listen(8000);

  io.sockets.on('connection', function(socket) {
    var join, learnlocityServer, notifyAllClients, notifyRoom, notifySourceClient, sourceClientId;
    console.log('started');
    learnlocityServer = new LearnlocityServer;
    sourceClientId = socket.id;
    notifyAllClients = function(topic, data) {
      return io.sockets.emit('message', [topic, data]);
    };
    notifySourceClient = function(topic, data) {
      return io.sockets.socket(sourceClientId).emit('message', [topic, data]);
    };
    join = function(room) {
      return socket.join(room);
    };
    notifyRoom = function(room, topic, data, includeSelf) {
      if (includeSelf == null) {
        includeSelf = false;
      }
      if (includeSelf) {
        return io.sockets["in"](room).emit('message', [topic, data]);
      } else {
        return socket.broadcast.to(room).emit('message', [topic, data]);
      }
    };
    learnlocityServer.NotifyAllClients = notifyAllClients;
    learnlocityServer.NotifySourceClient = notifySourceClient;
    learnlocityServer.Join = join;
    learnlocityServer.NotifyRoom = notifyRoom;
    learnlocityServer.NotifyRoomChannels = function(room, topic, data, includeSelf, mixInPropertiesMap) {
      var localData, subChannel, _i, _len, _ref, _results;
      if (includeSelf == null) {
        includeSelf = false;
      }
      if (mixInPropertiesMap == null) {
        mixInPropertiesMap = null;
      }
      this.NotifyRoom(room, topic, data, includeSelf);
      _ref = ['Watch', 'Spy'];
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        subChannel = _ref[_i];
        localData = _.clone(data);
        if ((mixInPropertiesMap != null) && (mixInPropertiesMap[subChannel] != null)) {
          _.extend(localData, mixInPropertiesMap[subChannel]);
        }
        _results.push(this.NotifyRoom(room + subChannel, topic, localData, includeSelf));
      }
      return _results;
    };
    return socket.on('message', function(data) {
      var commandClassName, commandConstructorArguments;
      commandClassName = data[0];
      commandConstructorArguments = data[1];
      console.log('socket.on message: ' + commandClassName + " -> " + commandConstructorArguments);
      return learnlocityServer.process(commandClassName, commandConstructorArguments);
    });
  });

}).call(this);
