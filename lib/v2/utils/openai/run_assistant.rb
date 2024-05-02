# frozen_string_literal: true

module Utils
  module OpenAI
    ##
    # This module is an OpenAI utility for using an already created OpenAI Assistant
    # and get an AI response depending on the Assistant's intructions and prompt.
    #
    module RunAssitant
      OPENAI_BASE_URL = "https://api.openai.com"
      DEFAULT_N_CHOICES = 1

      # Implements the request process logic to the OpenAI Assitant.
      #
      # <br>
      # <b>Params:</b>
      # * <tt>assistant_id</tt> Assistant id
      # * <tt>prompt</tt> Text that communicates to AI to provide it more context.
      # * <tt>secret</tt> OpenAI Secret API Key.
      #
      # <br>
      # <b>returns</b> <tt>HTTParty::Response</tt>
      #
      def self.execute(params)
        @params = params

        run = create_thread_and_run
        puts "RUN:::"
        puts run.inspect
        return run unless run.code == 200

        run = run.parsed_response
        run_fetched = poll_run(run)
        return run_fetched unless run_fetched["status"] == "completed"

        list_messages(run_fetched)
      end

      # Creates an OpenAI Thread and a Run using the given assistant_id and prompt.
      #
      def self.create_thread_and_run
        url = "#{OPENAI_BASE_URL}/v1/threads/runs"

        HTTParty.post(url, { body:, headers: })
      end

      # Retrieve the list of messages of a thread.
      #
      def self.list_messages(run)
        url = "#{OPENAI_BASE_URL}/v1/threads/#{run["thread_id"]}/messages"

        HTTParty.get(url, { headers: })
      end

      # Request body
      #
      def self.body
        {
          assistant_id: @params[:assistant_id],
          thread: {
            messages: [
              role: "user",
              content: @params[:prompt]
            ]
          }
        }.to_json
      end

      # Request headers
      #
      def self.headers
        {
          "Authorization" => "Bearer #{@params[:secret]}",
          "Content-Type" => "application/json",
          "OpenAI-Beta" => "assistants=v2"
        }
      end

      # Polls the Run until it is processed.
      #
      def self.poll_run(run) # rubocop:disable Metrics/MethodLength
        url = "#{OPENAI_BASE_URL}/v1/threads/#{run["thread_id"]}/runs/#{run["id"]}"

        while true
          run_fetched = HTTParty.get(url, { headers: })
          status = run_fetched["status"]

          case status
          when "queued", "in_progress", "cancelling" then sleep 1 # Wait one second and poll again
          when "completed", "requires_action", "cancelled", "failed", "expired" then break
          else
            puts "Unknown status response: #{status}"
          end
        end

        run_fetched
      end
    end
  end
end
