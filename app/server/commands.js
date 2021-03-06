// Generated by CoffeeScript 1.6.2
(function() {
  var AccountRegister, ChallengeCreate, ChallengeJoin, ChallengeQuestion, ChallengeQuestionByIndex, ChallengeResume, ChallengeScoreboard, ChallengeSendChatMessage, ChallengeSpy, ChallengeSubmitAnswer, ChallengeSubmitAnswerResponse, ChallengeWatch, ChallengesActive, ChallengesCompleted, ChallengesOpen, DefinitionAdd, DefinitionsImport, DictionaryCreate, DictionaryList, Login, ScoreStatusInfo, importer;

  importer = require('./importer');

  importer(require('./utils'));

  module.exports = {
    AccountRegister: AccountRegister = (function() {
      function AccountRegister(userName, email, password, passwordConfirm, id, externalAuth) {
        this.userName = userName != null ? userName : '';
        this.email = email != null ? email : '';
        this.password = password != null ? password : '';
        this.passwordConfirm = passwordConfirm != null ? passwordConfirm : '';
        this.id = id != null ? id : '';
        this.externalAuth = externalAuth != null ? externalAuth : false;
      }

      AccountRegister.prototype.getValidationErrors = function() {
        var sv;

        sv = new StringValidator;
        sv.field('userName', this.userName).max(50).min(4).notEmpty();
        if (this.externalAuth) {
          return sv.errors;
        }
        sv.field('email', this.email).max(100).min(5).notEmpty();
        sv.field('password', this.password).max(50).min(8).notEmpty();
        sv.field('Confirm Password', this.passwordConfirm).matches(this.password, 'Password');
        return sv.errors;
      };

      return AccountRegister;

    })(),
    Login: Login = (function() {
      function Login(userNameOrEmail, password, externalAuth) {
        this.userNameOrEmail = userNameOrEmail != null ? userNameOrEmail : '';
        this.password = password != null ? password : '';
        this.externalAuth = externalAuth != null ? externalAuth : false;
      }

      Login.prototype.getValidationErrors = function() {
        var sv;

        sv = new StringValidator;
        sv.field("Username or Email", this.userNameOrEmail).notEmpty().max(100).min(4);
        if (this.externalAuth) {
          return sv.errors;
        }
        sv.field("Password", this.password).notEmpty().max(50).min(8);
        return sv.errors;
      };

      return Login;

    })(),
    ChallengesOpen: ChallengesOpen = (function() {
      function ChallengesOpen(userName) {
        this.userName = userName;
      }

      return ChallengesOpen;

    })(),
    ChallengesCompleted: ChallengesCompleted = (function() {
      function ChallengesCompleted(userName) {
        this.userName = userName;
      }

      return ChallengesCompleted;

    })(),
    ChallengesActive: ChallengesActive = (function() {
      function ChallengesActive(userName) {
        this.userName = userName;
      }

      return ChallengesActive;

    })(),
    ChallengesSendChatMessage: ChallengeSendChatMessage = (function() {
      function ChallengeSendChatMessage(userName, message, dateTime) {
        this.userName = userName != null ? userName : "";
        this.message = message != null ? message : '';
        this.dateTime = dateTime != null ? dateTime : null;
      }

      return ChallengeSendChatMessage;

    })(),
    ChallengeCreate: ChallengeCreate = (function() {
      function ChallengeCreate(userName, name, dictionary, isOpen, isGroup) {
        this.userName = userName != null ? userName : '';
        this.name = name != null ? name : '';
        this.dictionary = dictionary != null ? dictionary : '';
        this.isOpen = isOpen != null ? isOpen : false;
        this.isGroup = isGroup != null ? isGroup : false;
      }

      ChallengeCreate.prototype.getValidationErrors = function() {
        var sv;

        sv = new StringValidator;
        sv.field("Username", this.userName).notEmpty().max(50).min(4);
        sv.field("Name", this.name).notEmpty().max(50).min(5);
        sv.field('Dictionary', this.dictionary).notEmpty().max(100).min(5);
        return sv.errors;
      };

      return ChallengeCreate;

    })(),
    ChallengeJoin: ChallengeJoin = (function() {
      function ChallengeJoin(userName, name) {
        this.userName = userName != null ? userName : '';
        this.name = name != null ? name : '';
        this.created = new Date();
      }

      return ChallengeJoin;

    })(),
    ChallengeResume: ChallengeResume = (function() {
      function ChallengeResume(userName, name) {
        this.userName = userName != null ? userName : '';
        this.name = name != null ? name : '';
      }

      return ChallengeResume;

    })(),
    ChallengeSpy: ChallengeSpy = (function() {
      function ChallengeSpy(userName, name) {
        this.userName = userName != null ? userName : '';
        this.name = name != null ? name : '';
      }

      return ChallengeSpy;

    })(),
    ChallengeWatch: ChallengeWatch = (function() {
      function ChallengeWatch(userName, name) {
        this.userName = userName != null ? userName : '';
        this.name = name != null ? name : '';
      }

      return ChallengeWatch;

    })(),
    ChallengeQuestionByIndex: ChallengeQuestionByIndex = (function() {
      function ChallengeQuestionByIndex(name, index) {
        this.name = name != null ? name : '';
        this.index = index != null ? index : 0;
      }

      return ChallengeQuestionByIndex;

    })(),
    ChallengeQuestion: ChallengeQuestion = (function() {
      function ChallengeQuestion(name, index, definition, choices, answer) {
        this.name = name != null ? name : '';
        this.index = index != null ? index : 0;
        this.definition = definition != null ? definition : '';
        this.choices = choices != null ? choices : [];
        if (answer != null) {
          this.answer = answer;
        }
      }

      return ChallengeQuestion;

    })(),
    ChallengeSubmitAnswer: ChallengeSubmitAnswer = (function() {
      function ChallengeSubmitAnswer(name, userName, index, answer) {
        this.name = name != null ? name : '';
        this.userName = userName != null ? userName : '';
        this.index = index != null ? index : 0;
        this.answer = answer != null ? answer : '';
      }

      return ChallengeSubmitAnswer;

    })(),
    ChallengeSubmitAnswerResponse: ChallengeSubmitAnswerResponse = (function() {
      function ChallengeSubmitAnswerResponse(challengeName, challengePlayerName, choice, result, scoreStatusInfo) {
        this.challengeName = challengeName != null ? challengeName : '';
        this.challengePlayerName = challengePlayerName != null ? challengePlayerName : '';
        this.choice = choice != null ? choice : '';
        this.result = result != null ? result : false;
        this.scoreStatusInfo = scoreStatusInfo != null ? scoreStatusInfo : null;
      }

      return ChallengeSubmitAnswerResponse;

    })(),
    ScoreStatusInfo: ScoreStatusInfo = (function() {
      function ScoreStatusInfo(answersAttemptCount, answersCorrectCount, answersPercentage, streakCount, streakIsCorrect) {
        this.answersAttemptCount = answersAttemptCount != null ? answersAttemptCount : 0;
        this.answersCorrectCount = answersCorrectCount != null ? answersCorrectCount : 0;
        this.answersPercentage = answersPercentage != null ? answersPercentage : 0.0;
        this.streakCount = streakCount != null ? streakCount : 0;
        this.streakIsCorrect = streakIsCorrect != null ? streakIsCorrect : false;
      }

      return ScoreStatusInfo;

    })(),
    ChallengeScoreboard: ChallengeScoreboard = (function() {
      function ChallengeScoreboard(userName) {
        this.userName = userName != null ? userName : '';
      }

      return ChallengeScoreboard;

    })(),
    DefinitionsImport: DefinitionsImport = (function() {
      function DefinitionsImport() {}

      return DefinitionsImport;

    })(),
    DefinitionAdd: DefinitionAdd = (function() {
      function DefinitionAdd(word, definition, dictionary) {
        this.word = word != null ? word : '';
        this.definition = definition != null ? definition : '';
        this.dictionary = dictionary != null ? dictionary : '';
      }

      return DefinitionAdd;

    })(),
    DictionaryList: DictionaryList = (function() {
      function DictionaryList(page) {
        this.page = page != null ? page : 1;
      }

      return DictionaryList;

    })(),
    DictionaryCreate: DictionaryCreate = (function() {
      function DictionaryCreate(title, userName) {
        this.title = title != null ? title : '';
        this.userName = userName != null ? userName : '';
      }

      return DictionaryCreate;

    })()
  };

}).call(this);
