requiredir = require 'require-dir'
modules = requiredir './modules', 
  filter: '.*module\.*js'
  recurse: true

module.exports = modules