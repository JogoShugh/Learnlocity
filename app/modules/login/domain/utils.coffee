StringIsNotNullOrWhiteSpace = (value) ->
  if not value? 
    return false
  return /\S/.test(value)

class StringValidator
  constructor: (@errors=[], @fieldName="", @value="") ->

  addError: (message) ->
    errorMessage = "#{@fieldName} " + message
    @errors.push errorMessage

  field: (fieldName, value) ->
    @fieldName = fieldName
    @value = value
    return @

  isNotWhiteSpace: ->
    StringIsNotNullOrWhiteSpace @value

  notEmpty: ->
    if not @isNotWhiteSpace()
      @addError "cannot be empty"
    return @
  
  max: (length) ->
    if @isNotWhiteSpace()
      if @value.length > length
        @addError "cannot be more than " + length + " characters"
    return @

  min: (length) ->
    if @isNotWhiteSpace()
      if @value.length < length
        @addError "cannot be fewer than " + length + " characters"
    return @    

  matches: (compare, fieldCompareName) ->
    if @isNotWhiteSpace()
      if @value != compare
        @addError "must match " + fieldCompareName

module.exports =
  StringValidator: StringValidator
  StringIsNotNullOrWhiteSpace: StringIsNotNullOrWhiteSpace