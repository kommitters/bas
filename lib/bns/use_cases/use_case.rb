# frozen_string_literal: true

module UseCases
  ##
  # The UseCases::UseCase class represents a generic structure for use cases within the system. It encapsulates the
  # logic flow by coordinating the execution of its components to fulfill a specific use case.
  #
  class UseCase
    attr_reader :fetcher, :mapper, :formatter, :dispatcher

    # Initializes the use case with the necessary components.
    #
    # <br>
    # <b>Params:</b>
    # * <tt>Usecases::Types::Config</tt> config, The components required to instantiate a use case.
    #
    def initialize(config)
      @fetcher = config.fetcher
      @mapper = config.mapper
      @formatter = config.formatter
      @dispatcher = config.dispatcher
    end

    # Executes the use case by orchestrating the sequential execution of the fetcher, mapper, formatter, and dispatcher.
    #
    # <br>
    # <b>returns</b> <tt>Dispatcher::Discord::Types::Response</tt>
    #
    def perform
      response = fetcher.fetch

      mappings = mapper.map(response)

      formatted_payload = formatter.format(mappings)

      dispatcher.dispatch(formatted_payload)
    end
  end
end
