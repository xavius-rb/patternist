# frozen_string_literal: true

require 'patternist/controllers/actionpack/restful'

module Patternist
  # Base module for all controllers in the Patternist framework.
  module Controller
    def self.included(base)
      base.include Controllers::ActionPack::Restful
    end
  end
end
