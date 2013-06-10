mg = require 'mongoose'

dictionarySchema = mg.Schema({
  title:  String,
  author: String,
  words: [
    { word: String, definition: String }
  ]
  meta: {
    votes: Number,
    favs:  Number
  }
})

Dictionary = mg.model 'Dictionary', dictionarySchema

mg.connect 'mongodb://localhost:27017/learnlocity'

module.exports = Dictionary