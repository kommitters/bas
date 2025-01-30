# frozen_string_literal: true

require "bas/utils/google/send_email"

RSpec.describe Utils::GoogleService::SendEmail do
  let(:params) do
    {
      refresh_token: "refresh_token",
      client_id: "client_id",
      client_secret: "client_secret",
      user_email: "user@mail.com",
      recipient_email: ["recipient1@mail.com"],
      subject: "email subject",
      message: "email message"
    }
  end

  let(:refresh_object) do
    instance_double("Google::Auth::UserRefreshCredentials", fetch_access_token!: nil, access_token: "ABCD1234")
  end
  let(:gmail_service) do
    instance_double("Google::Apis::GmailV1::GmailService", send_user_message: nil, authorization: nil)
  end

  before do
    stub_const("Google::Apis::GmailV1::GmailService", Class.new)
    stub_const("Google::Auth::UserRefreshCredentials", Class.new)

    allow(Google::Auth::UserRefreshCredentials).to receive(:new).and_return(refresh_object)
    allow(Google::Apis::GmailV1::GmailService).to receive(:new).and_return(gmail_service)
  end

  describe ".execute" do
    subject(:service) { described_class.new(params) }

    context "when an error occurs" do
      before do
        allow(gmail_service).to receive(:authorization=).and_raise(StandardError, "Mocked error")
      end

      it "returns an error message" do
        expect(service.execute).to eq({ error: "Mocked error" })
      end
    end

    context "when email is sent successfully" do
      before do
        allow(gmail_service).to receive(:authorization=).and_return(nil)
      end

      it "sends the email and returns an empty response" do
        expect(service.execute).to eq({ send_email: nil })
      end
    end
  end
end
