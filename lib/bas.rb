# frozen_string_literal: true

require_relative "bas/version"
require_relative "bas/bot/base"
require_relative "bas/shared_storage/base"
require_relative "bas/shared_storage/default"
require_relative "bas/shared_storage/postgres"

module Bas
  class Error < StandardError; end
end
