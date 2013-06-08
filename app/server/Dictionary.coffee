class Word
    constructor: (@word, @definition, @exampleSentence='') ->

class Dictionary
    constructor: (words=[]) ->
        @importWords words

    _words: []

    allWords: ->
        return @_words

    importWords: (words) ->
        _words = []
        for word in words
            @_words.push new Word(word.word, word.definition, word.exampleSentence)

    addWord: (word, definition, exampleSentence='') ->
        @_words.push(new Word(word, definition, exampleSentence))

    getWord: (index) ->
        return @_words[index]

    getRandomWord: ->
        word = @_words[Math.floor(Math.random() * @_words.length)]

    wordCount: ->
        return @_words.length

module.exports = Dictionary