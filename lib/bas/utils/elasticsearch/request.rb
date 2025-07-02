# frozen_string_literal: true

require "elasticsearch"

module Utils
  module Elasticsearch
    ##
    # This module is a ElasticsearchDB utility to make requests to a Elasticsearch database.
    #
    module Request
      ALLOWED_METHODS = %i[search index].freeze

      # Implements the request process logic to the ElasticsearchDB index.
      #
      # <br>
      # <b>Params:</b>
      # * <tt>connection</tt> Connection parameters to the database: `host`, `port`, `index`, `user`, `password`.
      # * <b>query</b>:
      #   * <tt>String</tt>: String with the Elasticsearch query to be executed.
      #   * <tt>Array</tt>: Two element array, where the first element is the Elasticsearch query (string), and the
      #                     second one an array of elements to be interpolared in the query when using "$1, $2, ...".
      #
      # <br>
      # <b>returns</b> <tt>HTTParty::Response</tt>
      #
      class << self
        def execute(params)
          client = ::Elasticsearch::Client.new(
            host: params[:connection][:host],
            port: params[:connection][:port],
            user: params[:connection][:user],
            password: params[:connection][:password],
            api_versioning: false,
            transport_options: { ssl: { ca_file: params[:connection][:ca_file] } }
          )

          client.cluster.health
          perform_request(params, client)
        end

        private

        def perform_request(params, client)
          case params[:method]
          when :index
            index_document(params, client)
          when :search
            search(params, client)
          when :update
            update_document(params, client)
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

        def update_document(params, client)
          client.update(index: params[:index], id: params[:id], body: params[:body])
        end

        def create_mapping(params, client)
          return if client.indices.exists?(index: params[:index])

          client.indices.create(index: params[:index], body: params[:body])
        end
      end
    end
  end
end
