# frozen_string_literal: true

require_relative "../../domain/issue"
require_relative "../base"

module Serialize
  module Github
    ##
    # This class implementats the methods of the Serialize::Base module, specifically designed for
    # preparing or shaping Github issues data coming from a Read::Base implementation.
    class Issues
      include Base

      # Implements the logic for shaping the results from a reader response.
      #
      # <br>
      # <b>Params:</b>
      # * <tt>Read::Github::Types::Response</tt> github_response: Array of github issues data.
      #
      # <br>
      # <b>return</b> <tt>List<Domain::Issue></tt> serialized github issues to be used by a
      # Formatter::Base implementation.
      #
      def execute(github_response)
        return [] if github_response.results.empty?

        normalized_github_data = normalize_response(github_response.results)

        normalized_github_data.map do |issue|
          Domain::Issue.new(
            issue["title"], issue["state"], issue["assignees"], issue["body"], issue["url"]
          )
        end
      end

      private

      def normalize_response(results)
        return [] if results.nil?

        results.map do |value|
          {
            "title" => value[:title],
            "state" => value[:state],
            "assignees" => extract_assignees(value[:assignees]),
            "body" => value[:body],
            "url" => value[:url]
          }
        end
      end

      def extract_assignees(assignees)
        assignees.map { |assignee| assignee[:login] }
      end
    end
  end
end
