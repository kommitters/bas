# frozen_string_literal: true

module Domain
  ##
  # The Domain::Email class provides a domain-specific representation of an Email object.
  # It encapsulates information about an email, including the subject, the sender, and the date.
  #
  class Email
    attr_reader :subject, :sender
    attr_accessor :date

    ATTRIBUTES = %w[subject sender date].freeze

    # Initializes a Domain::Email instance with the specified subject, sender, and date.
    #
    # <br>
    # <b>Params:</b>
    # * <tt>String</tt> email subject.
    # * <tt>String</tt> Email of the sender.
    # * <tt>String</tt> Reception date
    #
    def initialize(subject, sender, date)
      @subject = subject
      @sender = sender
      @date = parse_to_datetime(date)
    end

    private

    def parse_to_datetime(date)
      DateTime.parse(date).to_time
    end
  end
end
