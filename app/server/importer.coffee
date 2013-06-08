module.exports = (source, target) ->
  target = target || global
  for prop of source
    target[prop] = source[prop]