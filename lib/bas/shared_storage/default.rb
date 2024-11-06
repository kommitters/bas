# frozen_string_literal: true

require_relative "base"
require_relative "types/read"

module SharedStorage
  ##
  # The SharedStorage::Default class serves as a shared storage implementation for bots
  # who don't read from a <b>shared storage</b>".
  #
  class Default < SharedStorage::Base
    def read
      Types::Read.new
    end
  end
end
