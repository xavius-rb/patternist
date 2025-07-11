# frozen_string_literal: true

require_relative 'patternist/version'

module Patternist
  class Error < StandardError; end
  class NotImplementedError < Error; end
  class NameError < Error; end
  class FormatError < Error; end
end
