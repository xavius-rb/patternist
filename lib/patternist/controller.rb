# frozen_string_literal: true

require 'patternist/controllers/actionpack/restful'

module Patternist
  # The Controller module provides a namespace for controller-related functionality
  module Controller
    def self.included(base)
      base.include Controllers::ActionPack::Restful
    end
  end
end
