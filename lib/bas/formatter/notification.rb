# frozen_string_literal: true

require_relative "../domain/notification"
require_relative "./exceptions/invalid_data"
require_relative "./base"
require_relative "./types/response"

module Formatter
  ##
  # This class implements methods from the Formatter::Base module, tailored to format the
  # Domain::Notification structure for a Process.
  class Notification < Base
    # Implements the logic for building a formatted notification message
    #
    # <br>
    # <b>Params:</b>
    # * <tt>List<Domain::Notification></tt> notifications_list: list of serialized notifications.
    #
    # <br>
    # <b>raises</b> <tt>Formatter::Exceptions::InvalidData</tt> when invalid data is provided.
    #
    # <br>
    # <b>returns</b> <tt>Formatter::Types::Response</tt> formatter response: standard output for
    # the formatted payload suitable for a Process.
    #
    def format(notifications_list)
      raise Formatter::Exceptions::InvalidData unless notifications_list.all? do |notification|
        notification.is_a?(Domain::Notification)
      end

      Formatter::Types::Response.new(notifications_list[0].notification)
    end
  end
end
