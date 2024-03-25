# frozen_string_literal: true

require_relative "../domain/exceptions/function_not_implemented"

module Fetcher
  ##
  # The Fetcher::Base class serves as the foundation for implementing specific data fetchers within the Fetcher module.
  # Operating as an interface, this class defines essential attributes and methods, providing a blueprint for creating
  # custom fetchers tailored to different data sources.
  #
  class Base
    attr_reader :config

    # Initializes the fetcher with essential configuration parameters.
    #
    def initialize(config)
      @config = config
    end

    # A method meant to fetch data from an specific source depending on the implementation.
    # Must be overridden by subclasses, with specific logic based on the use case.
    #
    # <br>
    # <b>raises</b> <tt>Domain::Exceptions::FunctionNotImplemented</tt> when missing implementation.
    #
    def fetch
      raise Domain::Exceptions::FunctionNotImplemented
    end

    protected

    # A method meant to execute the fetch request, retrieven the required data
    # from an specific filter configuration depending on the use case implementation.
    # Must be overridden by subclasses, with specific logic based on the use case.
    #
    # <br>
    # <b>raises</b> <tt>Domain::Exceptions::FunctionNotImplemented</tt> when missing implementation.
    #
    def execute
      raise Domain::Exceptions::FunctionNotImplemented
    end
  end
end
