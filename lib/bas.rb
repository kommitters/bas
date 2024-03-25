# frozen_string_literal: true

require_relative "bas/version"
require_relative "bas/use_cases/use_cases"

module Bas # rubocop:disable Style/Documentation
  include UseCases
  class Error < StandardError; end
end
