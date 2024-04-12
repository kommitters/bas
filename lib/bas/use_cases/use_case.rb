# frozen_string_literal: true

module UseCases
  ##
  # The UseCases::UseCase class represents a generic structure for use cases within the system. It encapsulates the
  # logic flow by coordinating the execution of its components to fulfill a specific use case.
  #
  class UseCase
    attr_reader :read, :serialize, :formatter, :process

    # Initializes the use case with the necessary components.
    #
    # <br>
    # <b>Params:</b>
    # * <tt>Usecases::Types::Config</tt> config, The components required to instantiate a use case.
    #
    def initialize(config)
      @read = config.read
      @serialize = config.serialize
      @formatter = config.formatter
      @process = config.process
    end

    # Executes the use case by orchestrating the sequential execution of the read, serialize, formatter, and process.
    #
    # <br>
    # <b>returns</b> <tt>Process::Discord::Types::Response</tt>
    #
    def perform
      response = read.execute

      serialization = serialize.execute(response)

      formatted_payload = formatter.format(serialization)

      process.execute(formatted_payload)
    end
  end
end
