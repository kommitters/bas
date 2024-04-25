# frozen_string_literal: true

require_relative './base'
require_relative '../read/postgres'
require_relative '../write/postgres'

module Bot
  class HumanizePto < Bot::Base
    def read
      reader = Read::Postgres.new(config[:read_options])

      reader.execute
    end

    def process(read_response)
    end

    def write(process_response)
      write = Write::Postgres.new(config[:write_options], process_response)

      write.execute
    end
  end
end
