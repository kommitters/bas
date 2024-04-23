# frozen_string_literal: true

require_relative './base'
require_relative './types/response'

module Read
  class Default < Read::Base
    def execute
      Read::Types::Response.new()
    end
  end
end
