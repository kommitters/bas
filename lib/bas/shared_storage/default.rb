# frozen_string_literal: true

require_relative "base"
require_relative "types/read"

module Bas
  module SharedStorage
    ##
    # The SharedStorage::Default class serves as a shared storage implementation for bots
    # who don't read from a <b>shared storage</b>".
    #
    class Default < Bas::SharedStorage::Base
      def read
        Bas::SharedStorage::Types::Read.new
      end
    end
  end
end
