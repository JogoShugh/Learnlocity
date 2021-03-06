// Generated by CoffeeScript 1.6.2
(function() {
  var StringIsNotNullOrWhiteSpace, StringValidator;

  StringIsNotNullOrWhiteSpace = function(value) {
    if (value == null) {
      return false;
    }
    return /\S/.test(value);
  };

  StringValidator = (function() {
    function StringValidator(errors, fieldName, value) {
      this.errors = errors != null ? errors : [];
      this.fieldName = fieldName != null ? fieldName : "";
      this.value = value != null ? value : "";
    }

    StringValidator.prototype.addError = function(message) {
      var errorMessage;

      errorMessage = ("" + this.fieldName + " ") + message;
      return this.errors.push(errorMessage);
    };

    StringValidator.prototype.field = function(fieldName, value) {
      this.fieldName = fieldName;
      this.value = value;
      return this;
    };

    StringValidator.prototype.isNotWhiteSpace = function() {
      return StringIsNotNullOrWhiteSpace(this.value);
    };

    StringValidator.prototype.notEmpty = function() {
      if (!this.isNotWhiteSpace()) {
        this.addError("cannot be empty");
      }
      return this;
    };

    StringValidator.prototype.max = function(length) {
      if (this.isNotWhiteSpace()) {
        if (this.value.length > length) {
          this.addError("cannot be more than " + length + " characters");
        }
      }
      return this;
    };

    StringValidator.prototype.min = function(length) {
      if (this.isNotWhiteSpace()) {
        if (this.value.length < length) {
          this.addError("cannot be fewer than " + length + " characters");
        }
      }
      return this;
    };

    StringValidator.prototype.matches = function(compare, fieldCompareName) {
      if (this.isNotWhiteSpace()) {
        if (this.value !== compare) {
          return this.addError("must match " + fieldCompareName);
        }
      }
    };

    return StringValidator;

  })();

  module.exports = {
    StringValidator: StringValidator,
    StringIsNotNullOrWhiteSpace: StringIsNotNullOrWhiteSpace
  };

}).call(this);
