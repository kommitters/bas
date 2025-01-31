# frozen_string_literal: true

require "bas/utils/imap/request"
require "webmock/rspec"
require "ostruct"

RSpec.describe Utils::Imap::Request do
  let(:params) do
    {
      refresh_token: "test_refresh_token",
      client_id: "test_client_id",
      client_secret: "test_client_secret",
      token_uri: "https://example.com/token",
      email_domain: "imap.gmail.com",
      email_port: 993,
      user_email: "test@example.com",
      inbox: "INBOX"
    }
  end

  let(:query) { "ALL" }
  let(:imap_client) { instance_double("Net::IMAP") }
  let(:message_double) { double("Message", attr: { "ENVELOPE" => "test email content" }) }

  describe "#execute" do
    context "when token refresh is successful" do
      before do
        stub_request(:post, params[:token_uri])
          .with(body: {
                  "grant_type" => "refresh_token",
                  "refresh_token" => params[:refresh_token],
                  "client_id" => params[:client_id],
                  "client_secret" => params[:client_secret]
                })
          .to_return(
            status: 200,
            body: '{"access_token": "test_access_token"}',
            headers: { 'Content-Type': "application/json" }
          )

        allow(Net::IMAP).to receive(:new).with(params[:email_domain], port: params[:email_port],
                                                                      ssl: true).and_return(imap_client)
        allow(imap_client).to receive(:authenticate).with("XOAUTH2", params[:user_email], "test_access_token")
        allow(imap_client).to receive(:examine).with(params[:inbox])
        allow(imap_client).to receive(:search).with(query).and_return([1])
        allow(imap_client).to receive(:fetch).with(1, "ENVELOPE").and_return([message_double])
        allow(imap_client).to receive(:logout)
        allow(imap_client).to receive(:disconnect)
      end

      it "retrieves emails successfully" do
        imap_request = described_class.new(params, query)
        result = imap_request.execute

        expect(result[:emails]).to eq([{ message_id: 1, message: "test email content" }])
      end
    end

    context "when refresh token fails" do
      before do
        stub_request(:post, params[:token_uri])
          .with(body: {
                  "grant_type" => "refresh_token",
                  "refresh_token" => params[:refresh_token],
                  "client_id" => params[:client_id],
                  "client_secret" => params[:client_secret]
                })
          .to_return(
            status: 400,
            body: '{"error": "invalid_grant"}',
            headers: { 'Content-Type': "application/json" }
          )
      end

      it "returns an error" do
        imap_request = described_class.new(params, query)
        result = imap_request.execute

        expect(result[:error].parsed_response).to eq({ "error" => "invalid_grant" })
      end
    end
  end
end
