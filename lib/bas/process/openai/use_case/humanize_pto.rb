# frozen_string_literal: true

require_relative "../base"

module Process
  module OpenAI
    ##
    # This class is an implementation of the Process::OpenAI::Base interface, specifically designed
    # to humanize formatted PTO messages for better understanding.
    #
    class HumanizePto < OpenAI::Base
      # Implements the data process to humanize formatted PTO messages.
      #
      def execute(format_response)
        messages = [
          {
            "role": "user",
            "content": content(format_response.data)
          }
        ]

        process(messages)
      end

      private

      def content(data)
        today = Time.now.utc.strftime("%A, %F").to_s

        <<~MESSAGE
          The following message is too complex for a human to read since it has specific dates formatted as YYYY-MM-DD:

          \"#{data}\"

          Create a text that gives the same message in a more human-readable and context-valuable fashion for a human.
          Use the current date (#{today}) to provide context.
          Try grouping information and using bullet points to make it easier to read the information at a quick glance.
          Additionally, keep in mind that we work from Monday to Friday - not weekends.
          Please, just give the PTOs message and avoid the intro message such as \"Here is a reader-friendly message\".
        MESSAGE
      end
    end
  end
end
