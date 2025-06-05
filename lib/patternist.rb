# frozen_string_literal: true

require_relative "patternist/version"

module Patternist
  # Base error class for all Patternist-related errors
  class Error < StandardError; end

  # Raised when a required method is not implemented
  class NotImplementedError < Error; end

  # Raised when a resource class cannot be inferred from controller name
  class NameError < Error; end

  # Raised when required parameters are missing or invalid
  class ParameterError < Error; end

  # Raised when a resource cannot be found
  class ResourceNotFoundError < Error; end

  # Raised when validation fails
  class ValidationError < Error; end
end
