# frozen_string_literal: true

module Domain
  ##
  # The Domain::Notification class provides a domain-specific representation of a Notification object.
  # It encapsulates the notification text.
  #
  class Notification
    attr_reader :notification

    ATTRIBUTES = %w[notification].freeze

    # Initializes a Domain::Notification instance with the specified notification text.
    #
    # <br>
    # <b>Params:</b>
    # * <tt>String</tt> notification
    #
    def initialize(notification)
      @notification = notification
    end
  end
end
