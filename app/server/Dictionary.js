// Generated by CoffeeScript 1.6.2
(function() {
  var Dictionary, Word;

  Word = (function() {
    function Word(word, definition, exampleSentence) {
      this.word = word;
      this.definition = definition;
      this.exampleSentence = exampleSentence != null ? exampleSentence : '';
    }

    return Word;

  })();

  Dictionary = (function() {
    function Dictionary(words) {
      if (words == null) {
        words = [];
      }
      this.importWords(words);
    }

    Dictionary.prototype._words = [];

    Dictionary.prototype.allWords = function() {
      return this._words;
    };

    Dictionary.prototype.importWords = function(words) {
      var word, _i, _len, _results, _words;

      _words = [];
      _results = [];
      for (_i = 0, _len = words.length; _i < _len; _i++) {
        word = words[_i];
        _results.push(this._words.push(new Word(word.word, word.definition, word.exampleSentence)));
      }
      return _results;
    };

    Dictionary.prototype.addWord = function(word, definition, exampleSentence) {
      if (exampleSentence == null) {
        exampleSentence = '';
      }
      return this._words.push(new Word(word, definition, exampleSentence));
    };

    Dictionary.prototype.getWord = function(index) {
      return this._words[index];
    };

    Dictionary.prototype.getRandomWord = function() {
      var word;

      return word = this._words[Math.floor(Math.random() * this._words.length)];
    };

    Dictionary.prototype.wordCount = function() {
      return this._words.length;
    };

    return Dictionary;

  })();

  module.exports = Dictionary;

}).call(this);
