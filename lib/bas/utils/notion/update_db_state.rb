# frozen_string_literal: true

require "httparty"
require_relative "request"

module Utils
  module Notion
    ##
    # This module is a Notion utility for sending update status to notion databases.
    #
    module UpdateDbState
      # Implements the request process logic to Notion.
      #
      # <br>
      # <b>Params:</b>
      # * <tt>property</tt> Name of the db property to be updated.
      # * <tt>page_id</tt> Id of the page to be updated.
      # * <tt>state</tt> State to be updated
      # * <tt>secret</tt> Notion secret.
      #
      # <br>
      # <b>returns</b> <tt>HTTParty::Response</tt>
      #

      def self.execute(data)
        params = build_params(data)

        Utils::Notion::Request.execute(params)
      end

      def self.build_params(data)
        {
          endpoint: "pages/#{data[:page_id]}",
          secret: data[:secret],
          method: "patch",
          body: body(data)
        }
      end

      def self.body(data)
        { properties: { data[:property] => { select: { name: data[:state] } } } }
      end
    end
  end
end
