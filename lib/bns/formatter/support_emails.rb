# frozen_string_literal: true

require_relative "../domain/email"
require_relative "./exceptions/invalid_data"
require_relative "./base"

module Formatter
  ##
  # This class implements methods from the Formatter::Base module, tailored to format the
  # Domain::Email structure for a dispatcher.
  class SupportEmails < Base
    DEFAULT_TIME_ZONE = "+00:00"

    # Initializes the formatter with essential configuration parameters.
    #
    # <b>timezone</b> : expect an string with the time difference relative to the UTC. Example: "-05:00"
    def initialize(config = {})
      super(config)

      @timezone = config[:timezone] || DEFAULT_TIME_ZONE
      @frecuency = config[:frecuency]
    end

    # Implements the logic for building a formatted payload with the given template for support emails.
    #
    # <br>
    # <b>Params:</b>
    # * <tt>List<Domain::Email></tt> support_emails_list: list of support emails.
    #
    # <br>
    # <b>raises</b> <tt>Formatter::Exceptions::InvalidData</tt> when invalid data is provided.
    #
    # <br>
    # <b>returns</b> <tt>String</tt> payload: formatted payload suitable for a Dispatcher.
    #
    def format(support_emails_list)
      raise Formatter::Exceptions::InvalidData unless support_emails_list.all? do |support_email|
        support_email.is_a?(Domain::Email)
      end

      process_emails(support_emails_list).reduce("") do |payload, support_email|
        payload + build_template(Domain::Email::ATTRIBUTES, support_email)
      end
    end

    private

    def process_emails(emails)
      emails.each { |email| email.date = at_timezone(email.date) }
      emails.filter! { |email| email.date > time_window } unless @frecuency.nil?

      format_timestamp(emails)
    end

    def format_timestamp(emails)
      emails.each { |email| email.date = email.date.strftime("%F %r") }
    end

    def time_window
      date_time = Time.now - (60 * 60 * @frecuency)

      at_timezone(date_time)
    end

    def at_timezone(date)
      Time.at(date, in: @timezone)
    end
  end
end
