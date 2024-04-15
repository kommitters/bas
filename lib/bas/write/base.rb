# frozen_string_literal: true

require_relative "../domain/exceptions/function_not_implemented"

module Write
  ##
  # The Write::Base class serves as the foundation for implementing specific data writers within the Write module.
  # Operating as an interface, this class defines essential attributes and methods, providing a blueprint for creating
  # custom writers.
  #
  class Base
    attr_reader :config

    # Initializes the writer with essential configuration parameters.
    #
    def initialize(config = {})
      @config = config
    end

    # A method meant to execute the write request to an specific destination depending on the implementation.
    # Must be overridden by subclasses, with specific logic based on the use case.
    #
    # <br>
    # <b>raises</b> <tt>Domain::Exceptions::FunctionNotImplemented</tt> when missing implementation.
    #
    def execute(_process_response)
      raise Domain::Exceptions::FunctionNotImplemented
    end

    protected

    def write(_method, _data)
      raise Domain::Exceptions::FunctionNotImplemented
    end
  end
end
