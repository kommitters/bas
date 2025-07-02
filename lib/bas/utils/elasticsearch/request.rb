# frozen_string_literal: true

require "elasticsearch"

module Utils
  module Elasticsearch
    ##
    # This module is a ElasticsearchDB utility to make requests to a Elasticsearch database.
    #
    module Request
      # Implements the request process logic to the ElasticsearchDB index.
      #
      # <br>
      # <b>Params:</b>
      # * <tt>connection</tt> Connection parameters to the database: `host`, `port`, `index`, `user`, `password`.
      # * <b>query</b>:
      #   * <tt>String</tt>: String with the Elasticsearch query to be executed.
      #   * <tt>Hash</tt>: Hash with the Elasticsearch query to be executed.
      # * <tt>method</tt>: Method to be executed.
      #                    Allowed methods are: `:search`, `:index`, `:update`, `:create_mapping`.
      #
      # <br>
      # <b>returns</b> <tt>Elasticsearch::Response</tt>
      #
      class << self
        def execute(params)
          client = ::Elasticsearch::Client.new(
            host: params[:connection][:host],
            port: params[:connection][:port],
            user: params[:connection][:user],
            password: params[:connection][:password],
            api_versioning: false,
            transport_options: build_ssl_options(params[:connection])
          )

          perform_request(params, client)
        end

        private

        def build_ssl_options(connection_params)
          ssl_options = {}
          ssl_options[:ca_file] = connection_params[:ca_file] if connection_params[:ca_file]
          ssl_options[:verify] = connection_params[:ssl_verify] if connection_params.key?(:ssl_verify)
          { ssl: ssl_options }
        end

        def perform_request(params, client)
          case params[:method]
          when :index
            index_document(params, client)
          when :search
            search(params, client)
          when :update
            update_documents(params, client)
          when :create_mapping
            create_mapping(params, client)
          end
        end

        def search(params, client)
          search_params = { index: params[:index] }
          search_params[:size] = 1 # return only one document
          if params[:query].is_a?(Hash)
            search_params[:body] = params[:query]
          else
            search_params[:q] = params[:query]
          end

          client.search(**search_params)
        end

        def index_document(params, client)
          client.index(index: params[:index], body: params[:body])
        end

        def update_documents(params, client)
          client.update_by_query(index: params[:index], body: params[:body], wait_for_completion: true, refresh: true)
        end

        def create_mapping(params, client)
          return if client.indices.exists?(index: params[:index])

          client.indices.create(index: params[:index], body: params[:body])
        end
      end
    end
  end
end
