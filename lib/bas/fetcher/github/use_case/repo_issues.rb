# frozen_string_literal: true

require_relative "../base"

module Fetcher
  module Github
    ##
    # This class is an implementation of the Fetcher::Github::Base interface, specifically designed
    # for fetching issues from a Github repository.
    #
    class RepoIssues < Github::Base
      def fetch
        execute("list_issues", config[:repo])
      end
    end
  end
end
