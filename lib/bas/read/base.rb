# frozen_string_literal: true

require_relative "../utils/exceptions/function_not_implemented"

module Read
  ##
  # The Read::Base class serves as the foundation for implementing specific data read components within
  # the Read module. Operating as an interface, this class defines essential attributes and methods,
  # providing a blueprint for creating custom read components tailored to different data sources.
  #
  class Base
    attr_reader :config

    # Initializes the read with essential configuration parameters.
    #
    def initialize(config = {})
      @config = config
    end

    # A method meant to execute the read request from an specific <b>common storage</b>.
    # Must be overridden by subclasses, with specific logic based on the storage source.
    #
    # <br>
    # <b>raises</b> <tt>Utils::Exceptions::FunctionNotImplemented</tt> when missing implementation.
    #
    def execute
      raise Utils::Exceptions::FunctionNotImplemented
    end
  end
end
