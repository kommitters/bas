# frozen_string_literal: true

require_relative './base'
require_relative '../read/default'
require_relative '../process/pto_today'
require_relative '../write/postgres'

module Bot
  class FetchPtoFromNotion < Bot::Base
    def read
      reader = Read::Default.new()

      reader.execute
    end

    def process(read_response)
      processer = Process::PtoToday.new(config[:process_options], read_response)

      processer.execute
    end

    def write(process_response)
      write = Write::Postgres.new(config[:write_options], process_response)

      write.execute
    end
  end
end
