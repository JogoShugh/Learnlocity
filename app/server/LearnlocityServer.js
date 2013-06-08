// Generated by CoffeeScript 1.3.3
(function() {
  var Challenge, ChallengeAnswerScored, ChallengePlayer, ChallengeState, ChallengeStateFactory, Definitions, LearnlocityServer, NUMBER_OF_QUESTIONS_PER_ROUND, commands, db, debug, dictClass, dictionary, handleError, importer, paginator, useDebug, _,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  importer = require('./importer');

  importer(require('./utils'));

  _ = require('./myunderscore');

  dictionary = require('./dictionarySchema');

  dictClass = require('./Dictionary');

  commands = require('./commands');

  db = require('./db');

  paginator = require('./paginator');

  NUMBER_OF_QUESTIONS_PER_ROUND = 3;

  useDebug = true;

  debug = function(data) {
    if (useDebug) {
      return console.log(data);
    }
  };

  db.connect();

  Challenge = (function() {

    function Challenge(userName, name) {
      this.userName = userName != null ? userName : '';
      this.name = name != null ? name : '';
      this._roundItems = [];
      this._players = [];
      this._wordsSeenAlready = [];
      this._generateRoundItems(NUMBER_OF_QUESTIONS_PER_ROUND);
      this.addPlayer(this.userName);
    }

    Challenge.prototype._randOrd = function() {
      return Math.round(Math.random()) - 0.5;
    };

    Challenge.prototype.addPlayer = function(userName) {
      return this._players.push([userName, new Array(NUMBER_OF_QUESTIONS_PER_ROUND)]);
    };

    Challenge.prototype._savePlayerAnswer = function(userName, index, answer, correct) {
      var p, player, _i, _len, _ref;
      player = null;
      _ref = this._players;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        p = _ref[_i];
        if (p[0] === userName) {
          player = p;
        }
      }
      if (player != null) {
        return player[1][index] = {
          "answer": answer,
          "correct": correct
        };
      }
    };

    Challenge.prototype.questionByIndex = function(index) {
      return this._roundItems[index];
    };

    Challenge.prototype.submitAnswer = function(userName, index, answer) {
      var correct, question;
      if (index > this._roundItems.length) {
        return false;
      }
      question = this.questionByIndex(index);
      if (!(question != null)) {
        throw "Cannot submit answer for index: " + index;
      }
      correct = answer === question[0].word;
      this._savePlayerAnswer(userName, index, answer, correct);
      return correct;
    };

    Challenge.prototype.submitAnswer = function(userName, index, answer) {
      var correct, question;
      if (index > this._roundItems.length) {
        return false;
      }
      question = this.questionByIndex(index);
      if (!(question != null)) {
        throw "Cannot submit answer for index: " + index;
      }
      correct = answer === question[0].word;
      this._savePlayerAnswer(userName, index, answer, correct);
      return correct;
    };

    Challenge.prototype.scoreDetails = function() {
      return this._players;
    };

    Challenge.prototype._generateRoundItems = function(numberOfQuestions) {
      var choices, i, word, _i, _ref, _results;
      this._roundItems = [];
      _results = [];
      for (i = _i = 0, _ref = numberOfQuestions - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        word = this._getRandomUnseenWord();
        choices = this._getAnswerChoices(word).sort(this._randOrd);
        _results.push(this._roundItems.push([word, choices]));
      }
      return _results;
    };

    Challenge.prototype._getRandomUnseenWord = function() {
      var word;
      word = dict.getRandomWord();
      while (this._hasWordBeenSeenAlready(word)) {
        word = dict.getRandomWord();
      }
      return word;
    };

    Challenge.prototype._hasWordBeenSeenAlready = function(word) {
      return __indexOf.call(this._wordsSeenAlready, word) >= 0;
    };

    Challenge.prototype._registerSeenWord = function(word) {
      if (!_hasWordBeenSeenAlready(word)) {
        return this._wordsSeenAlready.push(word);
      }
    };

    Challenge.prototype._getAnswerChoices = function(currentWord) {
      var choices, i, word, _i;
      choices = [];
      for (i = _i = 0; _i <= 2; i = ++_i) {
        word = dict.getRandomWord();
        while (word === currentWord) {
          word = dict.getRandomWord();
        }
        choices.push(word.word);
      }
      choices.push(currentWord.word);
      return choices;
    };

    return Challenge;

  })();

  ChallengePlayer = (function() {

    function ChallengePlayer(userName) {
      this.userName = userName;
    }

    return ChallengePlayer;

  })();

  ChallengeState = (function() {

    function ChallengeState(userName, name, roundItems) {
      this.userName = userName;
      this.name = name;
      this.roundItems = roundItems;
      this.created = new Date();
    }

    return ChallengeState;

  })();

  ChallengeStateFactory = (function() {

    function ChallengeStateFactory() {}

    ChallengeStateFactory.prototype.create = function(userName, name, dictName, callback) {
      var _this = this;
      this.userName = userName != null ? userName : '';
      this.name = name != null ? name : '';
      if (dictName == null) {
        dictName = 'GRE Words';
      }
      console.log(dictionary);
      return dictionary.findOne({
        title: dictName
      }, function(err, dict) {
        var state;
        if (err != null) {
          return console.log('ERROR: ' + err);
        } else {
          console.log('dict:');
          console.log(dict.words);
          _this._dict = new dictClass(dict.words);
          console.log(_this._dict);
          _this._roundItems = [];
          _this._wordsSeenAlready = [];
          _this._generateRoundItems(NUMBER_OF_QUESTIONS_PER_ROUND);
          state = new ChallengeState(_this.userName, _this.name, _this._roundItems);
          return callback(state);
        }
      });
    };

    ChallengeStateFactory.prototype._randOrd = function() {
      return Math.round(Math.random()) - 0.5;
    };

    ChallengeStateFactory.prototype._generateRoundItems = function(numberOfQuestions) {
      var choices, i, word, _i, _ref, _results;
      this._roundItems = [];
      _results = [];
      for (i = _i = 0, _ref = numberOfQuestions - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        word = this._getRandomUnseenWord();
        choices = this._getAnswerChoices(word).sort(this._randOrd);
        _results.push(this._roundItems.push([word, choices]));
      }
      return _results;
    };

    ChallengeStateFactory.prototype._getRandomUnseenWord = function() {
      var word;
      word = this._dict.getRandomWord();
      while (this._hasWordBeenSeenAlready(word)) {
        word = this._dict.getRandomWord();
      }
      return word;
    };

    ChallengeStateFactory.prototype._hasWordBeenSeenAlready = function(word) {
      return __indexOf.call(this._wordsSeenAlready, word) >= 0;
    };

    ChallengeStateFactory.prototype._getAnswerChoices = function(currentWord) {
      var choices, i, word, _i;
      choices = [];
      for (i = _i = 0; _i <= 2; i = ++_i) {
        word = this._dict.getRandomWord();
        while (word === currentWord) {
          word = this._dict.getRandomWord();
        }
        choices.push(word.word);
      }
      choices.push(currentWord.word);
      return choices;
    };

    return ChallengeStateFactory;

  })();

  ChallengeAnswerScored = (function() {

    function ChallengeAnswerScored(name, index, correct, userName) {
      this.name = name != null ? name : '';
      this.index = index != null ? index : 0;
      this.correct = correct != null ? correct : false;
      this.userName = userName != null ? userName : '';
      this.created = new Date();
    }

    return ChallengeAnswerScored;

  })();

  LearnlocityServer = (function() {

    function LearnlocityServer() {
      this.ChallengesCompleted = __bind(this.ChallengesCompleted, this);

      this.ChallengesOpen = __bind(this.ChallengesOpen, this);

      this.Login = __bind(this.Login, this);

      this.AccountRegister = __bind(this.AccountRegister, this);
      this.NotifySourceClient = null;
      this.NotifyAllClients = null;
      this.Join = null;
      this.NotifyRoom = null;
      this._challenges = [];
      this._onlineMembers = [];
    }

    LearnlocityServer.prototype.send = function(cmd, callback) {
      return this[cmd.constructor.name](cmd, callback);
    };

    LearnlocityServer.prototype.invoke = function(commandName, cmd) {
      return this[commandName](cmd);
    };

    LearnlocityServer.prototype.process = function(commandClassName, commandConstructorArguments) {
      var cmd, key, value;
      cmd = new commands[commandClassName];
      for (key in commandConstructorArguments) {
        value = commandConstructorArguments[key];
        cmd[key] = value;
      }
      return this.invoke(commandClassName, cmd);
    };

    LearnlocityServer.prototype.AccountRegister = function(cmd, callback) {
      var errors,
        _this = this;
      if (callback == null) {
        callback = null;
      }
      errors = cmd.getValidationErrors();
      if (errors.length > 0) {
        this.NotifySourceClient("ErrorOccurred", errors);
        return;
      }
      return this._userExistsAlready(cmd, function(duplicateName) {
        if (duplicateName === true) {
          return _this.NotifySourceClient("ErrorOccurred", "Please try a different username. An account by that name already exists.");
        } else {
          return db.store(cmd, cmd.username, false, function(err, user) {
            if (err != null) {
              return _this.NotifySourceClient("ErrorOccurred", err);
            } else {
              _this.NotifySourceClient("AccountRegisterSucceeded", cmd.userName);
              if (callback != null) {
                return callback();
              }
            }
          });
        }
      });
    };

    LearnlocityServer.prototype.Login = function(cmd, notifySourceClient) {
      var errors,
        _this = this;
      if (global.users[cmd.userNameOrEmail] != null) {
        cmd.externalAuth = true;
      }
      errors = cmd.getValidationErrors();
      if (errors.length > 0) {
        callback("ErrorOccurred", errors);
        return;
      }
      return db.userAuthenticate(cmd, function(err, authenticated) {
        var registerCmd, user;
        if (err != null) {
          debug("It blew up:" + err);
          notifySourceClient("ErrorOccurred", err);
        } else {
          if (authenticated) {
            _this._onlineMembers.push(cmd.userNameOrEmail);
            user = {
              userName: cmd.userNameOrEmail
            };
            if (cmd.externalAuth) {
              user.profile = global.users[cmd.userNameOrEmail];
            }
            return _this.NotifySourceClient('LoginSucceeded', user);
          } else {
            if (cmd.externalAuth) {
              registerCmd = new commands.AccountRegister(cmd.userNameOrEmail, cmd.userNameOrEmail, cmd.userNameOrEmail, cmd.userNameOrEmail, "", true);
              return _this.AccountRegister(registerCmd, function() {
                return _this.NotifySourceClient("LoginSucceeded", cmd.userNameOrEmail);
              });
            } else {
              return _this.NotifySourceClient("LoginFailed", "Could not authenticate user with username or email of " + cmd.userNameOrEmail);
            }
          }
        }
      });
    };

    LearnlocityServer.prototype.ChallengesOpen = function(query) {
      var _this = this;
      return db.challengesOpenFind(query, function(challengesOpen) {
        return _this.NotifySourceClient('ChallengesOpenSent', challengesOpen);
      });
    };

    LearnlocityServer.prototype.ChallengesCompleted = function(query) {
      var _this = this;
      return db.challengesCompletedFind(query, function(challengesCompleted) {
        return _this.NotifySourceClient('ChallengesCompletedSent', challengesCompleted);
      });
    };

    LearnlocityServer.prototype.ChallengesActive = function(query) {
      var _this = this;
      return db.challengesActiveFind(query, function(challengesActive) {
        return _this.NotifySourceClient('ChallengesActiveSent', challengesActive);
      });
    };

    LearnlocityServer.prototype.ChallengeCreate = function(cmd) {
      var challengeState, errors, factory,
        _this = this;
      errors = cmd.getValidationErrors();
      console.log(errors);
      if (errors.length > 0) {
        return false;
      }
      factory = new ChallengeStateFactory();
      return challengeState = factory.create(cmd.userName, cmd.name, cmd.dictionary, function(challengeState) {
        return db.challengeStateStore(challengeState, function(err, challengeName) {
          var challengeJoin;
          console.log('ChallengeCreate error: ' + err);
          if (err != null) {
            debug("ChallengeCreate error: " + err);
            return _this.NotifySourceClient("ErrorOccurred", err);
          } else {
            challengeJoin = new commands.ChallengeJoin(cmd.userName, cmd.name);
            return db.challengeJoinStore(challengeJoin, function(err, rowKey) {
              var questions;
              if (err != null) {
                debug("_challengeJoinStore:" + err);
                return _this.NotifySourceClient("ErrorOccurred", err);
              } else {
                debug("ChallengeCreate worked: " + challengeName);
                _this.Join(challengeName);
                _this.NotifySourceClient("ChallengeCreateSucceeded", challengeName);
                questions = db.getAllQuestions(challengeState);
                _this.NotifySourceClient("ChallengeQuestionsSent", questions);
                return _this.NotifyAllClients("ChallengeCreated", {
                  userName: challengeState.userName,
                  name: challengeName,
                  created: challengeState.created
                });
              }
            });
          }
        });
      });
    };

    LearnlocityServer.prototype.ChallengeJoin = function(cmd) {
      var _this = this;
      return db.findChallengeByName(cmd.name, function(challengeState) {
        var questions;
        if (challengeState != null) {
          _this.Join(challengeState.name);
          questions = db.getAllQuestions(challengeState);
          _this.NotifySourceClient("ChallengeQuestionsSent", questions);
          return db.challengeJoinStore(cmd, function(err, rowKey) {
            var challengeJoin;
            if (err != null) {
              debug("_challengeJoinStore:" + err);
              return _this.NotifySourceClient("ErrorOccurred", err);
            } else {
              challengeJoin = {
                name: cmd.name,
                userName: cmd.userName,
                message: "" + cmd.userName + " joined " + cmd.name + "!"
              };
              if ((global.users[cmd.userName] != null) && (global.users[cmd.userName].photos != null) && users[cmd.userName].photos.length > 0) {
                challengeJoin.userAvatarUrl = global.users[cmd.userName].photos[0].value;
              }
              _this.NotifyRoomChannels(challengeState.name, 'ChallengeJoined', challengeJoin);
              return db.findChallengeJoinsByChallengeName(cmd.name, function(challengeJoins) {
                var _i, _len, _results;
                _results = [];
                for (_i = 0, _len = challengeJoins.length; _i < _len; _i++) {
                  challengeJoin = challengeJoins[_i];
                  if ((users[challengeJoin.userName] != null) && (global.users[challengeJoin.userName].photos != null) && users[challengeJoin.userName].photos.length > 0) {
                    challengeJoin.userAvatarUrl = global.users[challengeJoin.userName].photos[0].value;
                  }
                  challengeJoin.message = "" + challengeJoin.userName + " joined " + challengeJoin.name + "!";
                  _results.push(_this.NotifySourceClient('ChallengeJoined', challengeJoin));
                }
                return _results;
              });
            }
          });
        }
      });
    };

    LearnlocityServer.prototype.ChallengeResume = function(cmd) {
      var _this = this;
      return db.findChallengeByName(cmd.name, function(challengeState) {
        var challengeJoin, questions;
        if (challengeState != null) {
          _this.Join(challengeState.name);
          questions = db.getAllQuestions(challengeState);
          _this.NotifySourceClient("ChallengeQuestionsSent", questions);
          challengeJoin = {
            name: cmd.name,
            userName: cmd.userName,
            message: "" + cmd.userName + " joined " + cmd.name + "!"
          };
          if ((global.users[cmd.userName] != null) && (global.users[cmd.userName].photos != null) && global.users[cmd.userName].photos.length > 0) {
            challengeJoin.userAvatarUrl = global.users[cmd.userName].photos[0].value;
          }
          _this.NotifySourceClient(challengeState.name, 'ChallengeJoined', challengeJoin);
          return db.findChallengeJoinsByChallengeName(cmd.name, function(challengeJoins) {
            var findScorings, _i, _len;
            for (_i = 0, _len = challengeJoins.length; _i < _len; _i++) {
              challengeJoin = challengeJoins[_i];
              if ((global.users[challengeJoin.userName] != null) && (global.users[challengeJoin.userName].photos != null) && global.users[challengeJoin.userName].photos.length > 0) {
                challengeJoin.userAvatarUrl = global.users[challengeJoin.userName].photos[0].value;
              }
              challengeJoin.message = "" + challengeJoin.userName + " joined " + challengeJoin.name + "!";
              _this.NotifySourceClient('ChallengeJoined', challengeJoin);
            }
            findScorings = {
              from: 'ChallengeAnswerScored',
              where: {
                name: cmd.name
              },
              done: function(challengeAnswerScorings) {
                var challengeAnswerScored, _j, _len1, _results;
                _results = [];
                for (_j = 0, _len1 = challengeAnswerScorings.length; _j < _len1; _j++) {
                  challengeAnswerScored = challengeAnswerScorings[_j];
                  if (challengeAnswerScored.userName === !cmd.userName) {
                    delete challengeAnswerScored.answer;
                  }
                  _results.push(_this.NotifySourceClient('ChallengeAnswerScored', challengeAnswerScored, true));
                }
                return _results;
              }
            };
            return db.find(findScorings);
          });
        }
      });
    };

    LearnlocityServer.prototype.ChallengeWatch = function(cmd) {
      var _this = this;
      return db.findChallengeByName(cmd.name, function(challengeState) {
        var questions;
        if (challengeState != null) {
          _this.Join(challengeState.name + 'Watch');
          questions = db.getAllQuestions(challengeState, true);
          _this.NotifySourceClient("ChallengeQuestionsSent", questions);
          _this.NotifySourceClient("ChallengeWatched", {
            name: cmd.name
          });
          return db.findChallengeJoinsByChallengeName(cmd.name, function(challengeJoins) {
            var challengeJoin, _i, _len, _results;
            _results = [];
            for (_i = 0, _len = challengeJoins.length; _i < _len; _i++) {
              challengeJoin = challengeJoins[_i];
              if ((global.users[challengeJoin.userName] != null) && (global.users[challengeJoin.userName].photos != null) && global.users[challengeJoin.userName].photos.length > 0) {
                challengeJoin.userAvatarUrl = global.users[challengeJoin.userName].photos[0].value;
              }
              challengeJoin.message = "" + challengeJoin.userName + " joined " + challengeJoin.name + "!";
              _results.push(_this.NotifySourceClient('ChallengeJoined', challengeJoin));
            }
            return _results;
          });
        }
      });
    };

    LearnlocityServer.prototype.ChallengeSpy = function(cmd) {
      var _this = this;
      return db.findChallengeByName(cmd.name, function(challengeState) {
        var questions;
        if (challengeState != null) {
          _this.Join(challengeState.name + 'Spy');
          questions = db.getAllQuestions(challengeState, true);
          _this.NotifySourceClient("ChallengeQuestionsSent", questions);
          _this.NotifySourceClient("ChallengeSpied", {
            name: cmd.name
          });
          return db.findChallengeJoinsByChallengeName(cmd.name, function(challengeJoins) {
            var challengeJoin, _i, _len, _results;
            _results = [];
            for (_i = 0, _len = challengeJoins.length; _i < _len; _i++) {
              challengeJoin = challengeJoins[_i];
              if ((global.users[challengeJoin.userName] != null) && (global.users[challengeJoin.userName].photos != null) && global.users[challengeJoin.userName].photos.length > 0) {
                challengeJoin.userAvatarUrl = global.users[challengeJoin.userName].photos[0].value;
              }
              challengeJoin.message = "" + challengeJoin.userName + " joined " + challengeJoin.name + "!";
              _results.push(_this.NotifySourceClient('ChallengeJoined', challengeJoin));
            }
            return _results;
          });
        }
      });
    };

    LearnlocityServer.prototype.ChallengeScoreboard = function(query) {
      var _this = this;
      return db.challengeScoreboardSummary(query, function(challengeScoreboard) {
        return _this.NotifySourceClient('ChallengeScoreboardSent', challengeScoreboard);
      });
    };

    LearnlocityServer.prototype.ChallengeScoreboardAll = function(query) {
      var _this = this;
      return db.challengeScoreboardSummary(query, function(challengeScoreboard) {
        return _this.NotifyAllClients('ChallengeScoreboardSent', challengeScoreboard);
      });
    };

    LearnlocityServer.prototype.ChallengeSubmitAnswer = function(cmd) {
      var _this = this;
      return db.findChallengeByName(cmd.name, function(challenge) {
        if (challenge != null) {
          return db.challengeSubmitAnswerStore(cmd, function(err, rowKey) {
            var challengeAnswerScored, challengeAnswerScoredSave, correct;
            if (err != null) {
              debug("ERROR: _challengeSubmitAnswer:" + err);
              return _this.NotifySourceClient("ErrorOccurred", err);
            } else {
              correct = _this._answerIsCorrect(cmd, challenge);
              challengeAnswerScored = new ChallengeAnswerScored(cmd.name, cmd.index, correct, cmd.userName);
              challengeAnswerScoredSave = new ChallengeAnswerScored(cmd.name, cmd.index, correct, cmd.userName);
              challengeAnswerScoredSave.answer = cmd.answer;
              return db.challengeAnswerScoredStore(challengeAnswerScoredSave, function() {
                _this.NotifyRoomChannels(cmd.name, 'ChallengeAnswerScored', challengeAnswerScored, false, {
                  Spy: {
                    answer: cmd.answer
                  }
                });
                challengeAnswerScored.answer = cmd.answer;
                _this.NotifySourceClient('ChallengeAnswerScored', challengeAnswerScored);
                if (cmd.index !== (NUMBER_OF_QUESTIONS_PER_ROUND - 1)) {
                  return;
                }
                return db.challengeCompletedDetailsFind(challenge, cmd.userName, function(challengeCompletedDetails) {
                  return db.challengeCompletedDetailsStore(challengeCompletedDetails, function() {
                    _this.NotifySourceClient('ChallengeCompletedDetails', challengeCompletedDetails);
                    _this.Join(challenge.name + 'Finished');
                    return _this.ChallengeScoreboardAll({});
                  });
                });
              });
            }
          });
        }
      });
    };

    LearnlocityServer.prototype._answerIsCorrect = function(challengeSubmitAnswer, challenge) {
      var answer, correct, index, selection;
      index = challengeSubmitAnswer.index;
      selection = challengeSubmitAnswer.answer;
      answer = challenge.roundItems[index];
      correct = false;
      if (selection === answer[0].word) {
        correct = true;
      }
      return correct;
    };

    LearnlocityServer.prototype.DefinitionsImport = function(definitionsImport) {
      var words;
      words = dict.allWords();
      return db.definitionsStore(new Definitions(words), function(err, rowKey) {
        if (err != null) {
          console.log('Error:');
          return console.log(err);
        } else {
          return console.log('Stored the definitions in: ' + rowKey);
        }
      });
    };

    LearnlocityServer.prototype.DictionaryList = function(args) {
      var _this = this;
      return db.dictionaryList(args, function(err, dictionaryList) {
        if (!handleError(err, 'DictionaryList')) {
          console.log(dictionaryList);
          return _this.NotifySourceClient('DictionaryListComplete', dictionaryList);
        }
      });
    };

    LearnlocityServer.prototype.DictionaryCreate = function(dictionaryCreate) {
      var _this = this;
      return db.dictionaryCreate(dictionaryCreate, function(err, dictionaryCreated) {
        if (!handleError(err, 'DictionaryCreate')) {
          console.log(dictionaryCreated);
          return _this.NotifySourceClient('DictionaryCreateComplete', dictionaryCreated);
        }
      });
    };

    LearnlocityServer.prototype.DefinitionAdd = function(definitionAdd) {
      var _this = this;
      console.log('add:');
      console.log(definitionAdd);
      return db.definitionStore(definitionAdd, function(err) {
        if (err != null) {
          console.log('Error in DefinitionAdd:');
          console.log(err);
        }
        return _this.NotifySourceClient('DefinitionAddComplete', {
          word: definitionAdd.word,
          success: true
        });
      });
    };

    return LearnlocityServer;

  })();

  Definitions = (function() {

    function Definitions(words) {
      this.words = words != null ? words : [];
    }

    return Definitions;

  })();

  handleError = function(err) {
    if (err != null) {
      console.log(err);
      return true;
    } else {
      return false;
    }
  };

  module.exports = {
    LearnlocityServer: LearnlocityServer
  };

}).call(this);
