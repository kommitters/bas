# frozen_string_literal: true

require_relative "../domain/exceptions/function_not_implemented"

module Process
  ##
  # Serves as a foundational structure for implementing specific process. Acting as an interface,
  # this class defines essential attributes and methods, providing a blueprint for creating custom
  # process tailored to different platforms or services.
  #
  class Base
    attr_reader :webhook, :name

    # Initializes the process with essential configuration parameters.
    #
    def initialize(config)
      @webhook = config[:webhook]
      @name = config[:name]
    end

    # A method meant to send messages to an specific destination depending on the implementation.
    # Must be overridden by subclasses, with specific logic based on the use case.
    #
    # <br>
    # <b>returns</b> a <tt>Discord::Response</tt>
    #
    def execute(_payload)
      raise Domain::Exceptions::FunctionNotImplemented
    end
  end
end
