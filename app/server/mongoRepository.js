// Generated by CoffeeScript 1.6.2
(function() {
  var _;

  _ = require('./myunderscore');

  module.exports = {
    storage: null,
    _debugCallback: null,
    setStorage: function(mongoDbClientStorage) {
      return this.storage = mongoDbClientStorage;
    },
    setDebugReporter: function(debugCallback) {
      return this._debugCallback = debugCallback;
    },
    debug: function(message) {
      if (this._debugCallback != null) {
        return this._debugCallback(message);
      }
    },
    store: function(obj, key, stringify, callback) {
      var typeName,
        _this = this;

      typeName = obj.constructor.name;
      return this.storage.collection(typeName, function(err, collection) {
        if (err != null) {
          _this.debug("ERROR: _store:collection: " + err);
          callback(err, null);
        } else {
          _this.debug("typeName: " + typeName + ": " + key + ': ' + obj);
          obj.key = key;
          return collection.insert(obj, function(err, result) {
            if (err != null) {
              return callback(err, null);
            } else {
              return callback(null, key);
            }
          });
        }
      });
    },
    find: function(query, done) {
      var collapseSelect, collection, field, findExec, keys, limit, select, skip, sort, values, where, _i, _len, _ref;

      skip = query.skip || 0;
      limit = query.limit || null;
      collection = this.storage.collection(query.from);
      sort = query.sort;
      values = [];
      where = query.where || {};
      select = null;
      collapseSelect = true;
      if (query.collapseSelect != null) {
        collapseSelect = query.collapseSelect;
      }
      if (query.select != null) {
        select = {};
        _ref = query.select;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          field = _ref[_i];
          select[field] = true;
        }
      } else {
        select = {};
      }
      keys = _.keys(select);
      findExec = collection.find(where, select).skip(skip);
      if (sort != null) {
        findExec = findExec.sort(sort);
      }
      if (limit != null) {
        findExec = findExec.limit(limit);
      }
      return findExec.stream().on('data', function(row) {
        var obj;

        obj = null;
        if (keys.length > 0) {
          obj = _.pick(row, keys);
        } else {
          obj = row;
        }
        return values.push(obj);
      }).on('end', function() {
        var key;

        if (collapseSelect === true && keys.length === 1) {
          key = keys[0];
          values = _.pluck(values, key);
        }
        if (done != null) {
          return done(values);
        }
      });
    }
  };

}).call(this);
