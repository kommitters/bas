# frozen_string_literal: true

require_relative "../domain/birthday"
require_relative "./exceptions/invalid_data"
require_relative "./base"
require_relative "./types/response"

module Formatter
  ##
  # This class implements methods from the Formatter::Base module, tailored to format the
  # Domain::Birthday structure for a Process.
  class Birthday < Base
    # Implements the logic for building a formatted payload with the given template for birthdays.
    #
    # <br>
    # <b>Params:</b>
    # * <tt>List<Domain::Birthday></tt> birthdays_list: list of serialized birthdays.
    #
    # <br>
    # <b>raises</b> <tt>Formatter::Exceptions::InvalidData</tt> when invalid data is provided.
    #
    # <br>
    # <b>returns</b> <tt>Formatter::Types::Response</tt> formatter response: standard output for
    # the formatted payload suitable for a Process.
    #
    def format(birthdays_list)
      raise Formatter::Exceptions::InvalidData unless birthdays_list.all? do |brithday|
        brithday.is_a?(Domain::Birthday)
      end

      response = birthdays_list.reduce("") do |payload, birthday|
        payload + build_template(Domain::Birthday::ATTRIBUTES, birthday)
      end

      Formatter::Types::Response.new(response)
    end
  end
end
