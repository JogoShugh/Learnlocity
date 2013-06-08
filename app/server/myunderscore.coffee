_ = require 'underscore'

_.mixin
    skipTake: (array, options) -> 
        options = _.extend({skip:0, limit:0}, options || {}) 
        return _(array)
            .chain()
            .rest(options.skip)
            .first(options.limit || array.length - options.skip)
            .value()

module.exports = _            