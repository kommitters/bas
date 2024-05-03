# frozen_string_literal: true

require_relative "../domain/exceptions/function_not_implement"

module Serialize
  ##
  # The Serialize::Base module serves as the foundation for implementing specific data shaping logic within the
  # Serialize module. Defines essential methods, that provide a blueprint for organizing or shaping data in a manner
  # suitable for downstream formatting processes.
  #
  module Base
    # An method meant to prepare or organize the data coming from an implementation of the Read::Base interface.
    # Must be overridden by subclasses, with specific logic based on the use case.
    #
    # <br>
    # <b>Params:</b>
    # * <tt>Read::Notion::Types::Response</tt> response: Response produced by a reader.
    #
    # <br>
    #
    # <b>raises</b> <tt>Domain::Exceptions::FunctionNotImplement</tt> when missing implementation.
    # <br>
    #
    # <b>returns</b> <tt>List<Domain::></tt> Serialize list of data, ready to be formatted.
    #
    def execute(_response)
      raise Domain::Exceptions::FunctionNotImplement
    end
  end
end
