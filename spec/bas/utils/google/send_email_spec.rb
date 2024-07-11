# frozen_string_literal: true

require "bas/utils/google/send_email"

RSpec.describe Utils::GoogleService::SendEmail do
  before do
    @params = {
      refresh_token: "refresh_token",
      client_id: "client_id",
      client_secret: "client_secret",
      user_email: "user@mail.com",
      recipient_email: ["recipient1@mail.com"],
      subject: "email subject",
      message: "email message"
    }

    @service = described_class.new(@params)
  end

  describe ".execute" do
    let(:refresh_object) { double("refresh", fetch_access_token!: nil, access_token: "ABCD1234") }
    let(:gmail_service) { double("service", send_user_message: nil, authorization: nil) }

    before do
      allow(Google::Auth::UserRefreshCredentials).to receive(:new).and_return(refresh_object)
      allow(Google::Apis::GmailV1::GmailService).to receive(:new).and_return(gmail_service)
    end

    it "should return an error message when an error is thrown" do
      allow(gmail_service).to receive(:authorization=).and_raise(StandardError)

      expect(@service.execute).to eq({ error: "StandardError" })
    end

    it "should send the email and return an empty response" do
      allow(gmail_service).to receive(:authorization=).and_return(nil)

      expect(@service.execute).to eq({ send_email: nil })
    end
  end
end
