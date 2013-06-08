_ = require './myunderscore'

module.exports =
    storage: null
    _debugCallback: null

    setStorage: (mongoDbClientStorage) ->
        @storage = mongoDbClientStorage

    setDebugReporter: (debugCallback) ->
        @_debugCallback = debugCallback

    debug: (message) ->
        if @_debugCallback?
            @_debugCallback message

    store: (obj, key, stringify, callback) ->
        typeName = obj.constructor.name        
        @storage.collection typeName, (err, collection) =>
            if err?              
                @debug "ERROR: _store:collection: " + err  
                callback err, null
                return
            else 
                @debug "typeName: " + typeName + ": " + key + ': ' + obj
                obj.key = key
                collection.insert obj, (err, result) ->
                    if err?
                        callback err, null
                    else
                        callback null, key

    find: (query, done) ->
        skip = query.skip || 0
        limit = query.limit || null
        collection = @storage.collection query.from
        sort = query.sort
        values = []
        where = query.where || {}
        select = null
        collapseSelect = true
        if query.collapseSelect?
            collapseSelect = query.collapseSelect
        if query.select?
            select = {}
            for field in query.select
                select[field] = true
        else
            select = {}
        keys = _.keys select
        findExec = collection.find(where, select).skip(skip)
        if sort?
            findExec = findExec.sort sort
        if limit?
            findExec = findExec.limit(limit)                    
        findExec.stream()   
            .on 'data', (row) ->
                obj = null
                if keys.length > 0
                    obj = _.pick row, keys
                else
                    obj = row
                values.push obj
            .on 'end', ->
                if collapseSelect is true and keys.length is 1
                    key = keys[0]
                    values = _.pluck values, key
                if done?
                    done(values)                        