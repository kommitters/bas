# frozen_string_literal: true

require_relative "../base"

module Read
  module Github
    ##
    # This class is an implementation of the Read::Github::Base interface, specifically designed
    # for reading issues from a Github repository.
    #
    class RepoIssues < Github::Base
      def execute
        read("list_issues", config[:repo])
      end
    end
  end
end
