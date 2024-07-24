# frozen_string_literal: true

module Utils
  module Notion
    module Types
      def multi_select(name)
        { "multi_select" => [{ "name" => name }] }
      end

      def relation(id)
        { relation: [{ id: }] }
      end

      def select(name)
        { select: { name: } }
      end

      def rich_text(content)
        { rich_text: [{ text: { content: } }] }
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
