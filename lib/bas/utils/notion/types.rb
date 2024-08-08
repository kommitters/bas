# frozen_string_literal: true

module Utils
  module Notion
    ##
    # This module is a Notion utility for formating standard notion types to
    # filter or create.
    #
    module Types
      def relation(id)
        { relation: [{ id: }] }
      end

      def select(name)
        { select: { name: } }
      end

      def rich_text(content, url = nil)
        text = { content: }

        text = text.merge({ link: { url: } }) unless url.nil?

        { rich_text: [{ text: }] }
      end

      def status(name)
        { status: { name: } }
      end

      def title(content)
        { title: [{ text: { content: } }] }
      end
    end
  end
end
