# frozen_string_literal: true

require_relative "bns/version"
require_relative "bns/use_cases/use_cases"

module Bns # rubocop:disable Style/Documentation
  include UseCases
  class Error < StandardError; end
end
