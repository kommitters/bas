# frozen_string_literal: true

require_relative "../domain/exceptions/function_not_implemented"
require "erb"

module Formatter
  ##
  # The Formatter::Base module serves as the foundation for implementing specific data presentation logic
  # within the Formatter module. Defines essential methods, that provide a blueprint for creating custom
  # formatters tailored to different use cases.
  #
  class Base
    attr_reader :template

    # Initializes the fetcher with essential configuration parameters.
    #
    def initialize(config = {})
      @config = config
      @template = config[:template]
    end

    # This method is designed to provide a specified format for data from any implementation of
    # the Mapper::Base interface.
    # Must be overridden by subclasses, with specific logic based on the use case.
    #
    # <br>
    # <b>Params:</b>
    # * <tt>List<Domain::></tt> domain_data: List of specific domain objects depending on the use case.
    #
    # <br>
    # <b>raises</b> <tt>Domain::Exceptions::FunctionNotImplemented</tt> when missing implementation.
    #
    # <b>returns</b> <tt>String</tt> Formatted payload suitable for a Dispatcher::Base implementation.
    #
    def format(_domain_data)
      raise Domain::Exceptions::FunctionNotImplemented
    end

    protected

    def build_template(attributes, instance)
      formated_template = format_template(attributes, instance)

      "#{ERB.new(formated_template).result(binding)}\n"
    end

    def format_template(attributes, _instance)
      attributes.reduce(template) do |formated_template, attribute|
        formated_template.gsub(attribute, "<%= instance.#{attribute} %>")
      end
    end
  end
end
