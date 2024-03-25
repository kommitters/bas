# frozen_string_literal: true

module Dispatcher
  module Discord
    module Exceptions
      ##
      # Domain specific representation  when an invalid Discord webhook token is provided to Discord.
      #
      class InvalidWebookToken < StandardError
        def initialize(message = "The provided Webhook token is invalid.")
          super(message)
        end
      end
    end
  end
end
