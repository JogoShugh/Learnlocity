// Generated by CoffeeScript 1.3.3
(function() {

  module.exports = function(source, target) {
    var prop, _results;
    target = target || global;
    _results = [];
    for (prop in source) {
      _results.push(target[prop] = source[prop]);
    }
    return _results;
  };

}).call(this);
