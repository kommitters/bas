# frozen_string_literal: true

RSpec.describe Fetcher::Imap::SupportEmails do
  before do
    config = {
      user: "user@mail.co",
      refresh_token: "123456789",
      client_id: "987654321",
      client_secret: "secret123",
      inbox: "INBOX",
      search_email: "support@mail.co"
    }

    @fetcher = described_class.new(config)
  end

  describe "attributes and arguments" do
    it { expect(described_class).to respond_to(:new).with(1).arguments }

    it { expect(@fetcher).to respond_to(:config) }
    it { expect(@fetcher).to respond_to(:fetch).with(0).arguments }
  end

  describe ".fetch" do
    let(:body) { "{\"access_token\":\"ABCDEFG\"}" }
    let(:response) { double("http_respose", body: body) }

    let(:imap) do
      stub = {
        authenticate: true,
        examine: true,
        logout: true,
        disconnect: true,
        search: [1, 2, 3, 4],
        fetch: [double("email", attr: { "ENVELOPE" => "email_envelope" })]
      }

      instance_double(Net::IMAP, stub)
    end

    before do
      allow(Net::HTTP).to receive(:post_form).and_return(response)
      allow(Net::IMAP).to receive(:new).and_return(imap)
    end

    it "fetch emails from the IMAP when there are results" do
      fetched_data = @fetcher.fetch

      expect(fetched_data).to be_an_instance_of(Fetcher::Imap::Types::Response)
      expect(fetched_data.results).to be_an_instance_of(Array)
      expect(fetched_data.results.length).to eq(4)
    end
  end
end
