# frozen_string_literal: true

require_relative "./base"
require_relative "./types/response"

module Read
  ##
  # This class is an implementation of the Read::Base interface, specifically designed
  # for bots who don't read from a <b>common storage</b>".
  #
  class Default < Read::Base
    def execute
      Read::Types::Response.new
    end
  end
end
