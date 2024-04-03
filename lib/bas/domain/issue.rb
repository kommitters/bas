# frozen_string_literal: true

module Domain
  ##
  # The Domain::Issue class provides a domain-specific representation of a Github issue object.
  # It encapsulates information about a repository issue, including the title, state, assignees,
  # description, and the repository url.
  #
  class Issue
    attr_reader :title, :state, :assignees, :description, :url

    ATTRIBUTES = %w[title state assignees description url].freeze

    def initialize(title, state, assignees, body, url)
      @title = title
      @state = state
      @assignees = assignees
      @description = body
      @url = url
    end
  end
end
