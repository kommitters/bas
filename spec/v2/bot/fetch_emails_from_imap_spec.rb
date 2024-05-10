# frozen_string_literal: true

require "v2/bot/fetch_emails_from_imap"

RSpec.describe Bot::FetchEmailsFromImap do
  before do
    config = {
      process_options: {
        refresh_token: "refresh_token",
        client_id: "client_id",
        client_secret: "client_secret",
        token_uri: "token_uri",
        email_domain: "email_domain",
        email_port: "email_port",
        user_email: "user_email",
        search_email: "search_email",
        inbox: "inbox"
      },
      write_options: {
        connection: {
          host: "host",
          port: 5432,
          dbname: "bas",
          user: "postgres",
          password: "postgres"
        },
        db_table: "use_cases",
        bot_name: "FetchEmailsFromImap"
      }
    }

    @bot = described_class.new(config)
  end

  describe "attributes and arguments" do
    it { expect(described_class).to respond_to(:new).with(1).arguments }

    it { expect(@bot).to respond_to(:execute).with(0).arguments }
    it { expect(@bot).to respond_to(:read).with(0).arguments }
    it { expect(@bot).to respond_to(:process).with(1).arguments }
    it { expect(@bot).to respond_to(:write).with(1).arguments }

    it { expect(@bot).to respond_to(:read_options) }
    it { expect(@bot).to respond_to(:process_options) }
    it { expect(@bot).to respond_to(:write_options) }
  end

  describe ".read" do
    it { expect(@bot.read).to be_a Read::Types::Response }
  end

  describe ".process" do
    let(:response) { double("http_response") }
    let(:message) do
      double("message", sender: [{ "mailbox" => "user", "host" => "mail.com" }], date: "10/05/2024", subject: "test")
    end

    let(:imap) do
      stub = {
        authenticate: true,
        examine: true,
        logout: true,
        disconnect: true,
        search: [1, 2, 3, 4],
        fetch: [double("email", attr: { "ENVELOPE" => message })]
      }

      instance_double(Net::IMAP, stub)
    end

    let(:email) { { :message_id => 1, "sender" => "user@mail.com", "date" => "10/05/2024", "subject" => "test" } }

    before do
      @read_response = Read::Types::Response.new

      allow(HTTParty).to receive(:post).and_return(response)
      allow(Net::IMAP).to receive(:new).and_return(imap)
    end

    it "returns a success hash with list of emails" do
      allow(response).to receive(:[]).and_return(nil, "ABCDEFG123456")

      processed = @bot.process(@read_response)

      expect(processed[:success][:emails]).to include(email)
    end

    it "returns an error hash when the access_token can not be requested" do
      allow(response).to receive(:[]).and_return(true)

      processed = @bot.process(@read_response)

      expect(processed).to eq({ error: { error: response } })
    end

    it "returns an error hash when the imap request fails" do
      allow(response).to receive(:[]).and_return(nil)
      allow(imap).to receive(:search).and_raise(StandardError)

      processed = @bot.process(@read_response)

      expect(processed).to eq({ error: { error: "StandardError" } })
    end
  end

  describe ".write" do
    let(:pg_conn) { instance_double(PG::Connection) }

    let(:email) { { :message_id => 1, "sender" => "user@mail.com", "date" => "10/05/2024", "subject" => "test" } }
    let(:error_response) { { "object" => "error", "status" => 404, "message" => "not found" } }

    before do
      pg_result = instance_double(PG::Result)

      allow(PG::Connection).to receive(:new).and_return(pg_conn)
      allow(pg_conn).to receive(:exec_params).and_return(pg_result)
    end

    it "save the process success response in a postgres table" do
      process_response = { success: { emails: [email] } }

      expect(@bot.write(process_response)).to_not be_nil
    end

    it "save the process fail response in a postgres table" do
      process_response = { error: { message: error_response, status_code: 404 } }

      expect(@bot.write(process_response)).to_not be_nil
    end
  end
end
