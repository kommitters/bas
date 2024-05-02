# frozen_string_literal: true

require_relative "../utils/exceptions/function_not_implemented"

module Write
  ##
  # The Write::Base class serves as the foundation for implementing specific data write components within
  # the Write module. Operating as an interface, this class defines essential attributes and methods,
  # providing a blueprint for creating custom write components tailored to different data storages.
  #
  class Base
    attr_reader :config, :process_response

    # Initializes the write with essential configuration parameters.
    #
    def initialize(config, process_response)
      @config = config
      @process_response = process_response
    end

    # A method meant to execute the write request to an specific <b>common storage</b>.
    # Must be overridden by subclasses, with specific logic based on the storage destination.
    #
    # <br>
    # <b>raises</b> <tt>Utils::Exceptions::FunctionNotImplemented</tt> when missing implementation.
    #
    def execute
      raise Utils::Exceptions::FunctionNotImplemented
    end
  end
end
