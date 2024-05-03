# frozen_string_literal: true

require_relative "../domain/exceptions/function_not_implement"

module Read
  ##
  # The Read::Base class serves as the foundation for implementing specific data readers within the Read module.
  # Operating as an interface, this class defines essential attributes and methods, providing a blueprint for creating
  # custom readers tailored to different data sources.
  #
  class Base
    attr_reader :config

    # Initializes the reader with essential configuration parameters.
    #
    def initialize(config)
      @config = config
    end

    # A method meant to execute the read request from an specific source depending on the implementation.
    # Must be overridden by subclasses, with specific logic based on the use case.
    #
    # <br>
    # <b>raises</b> <tt>Domain::Exceptions::FunctionNotImplement</tt> when missing implementation.
    #
    def execute
      raise Domain::Exceptions::FunctionNotImplement
    end

    protected

    # A method meant to read from the source, retrieven the required data
    # from an specific filter configuration depending on the use case implementation.
    # Must be overridden by subclasses, with specific logic based on the use case.
    #
    # <br>
    # <b>raises</b> <tt>Domain::Exceptions::FunctionNotImplement</tt> when missing implementation.
    #
    def read(*_filters)
      raise Domain::Exceptions::FunctionNotImplement
    end
  end
end
