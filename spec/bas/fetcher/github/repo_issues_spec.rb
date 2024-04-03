# frozen_string_literal: true

RSpec.describe Fetcher::Github::RepoIssues do
  before do
    config = {
      app_id: "123456",
      installation_id: "78910",
      secret_path: "secrets_file_path.pem",
      repo: "Organization/Repository"
    }

    @fetcher = described_class.new(config)
  end

  describe "attributes and arguments" do
    it { expect(described_class).to respond_to(:new).with(1).arguments }

    it { expect(@fetcher).to respond_to(:config) }
    it { expect(@fetcher).to respond_to(:fetch).with(0).arguments }
  end

  describe ".fetch" do
    let(:empty_response) { [] }
    let(:response) { [{ url: "repo_url" }] }

    let(:octokit) do
      stub = {
        create_app_installation_access_token: { token: "access_token" }
      }

      instance_double(Octokit::Client, stub)
    end

    before do
      allow(File).to receive(:read).and_return("private_pem")
      allow(OpenSSL::PKey::RSA).to receive(:new).and_return("private_key")
      allow(JWT).to receive(:encode).and_return("jwt_token")
      allow(Octokit::Client).to receive(:new).and_return(octokit)
    end

    it "fetch emails from the Github repo when there are not 'issues'" do
      allow(octokit).to receive(:public_send).and_return(empty_response)

      fetched_data = @fetcher.fetch

      expect(fetched_data).to be_an_instance_of(Fetcher::Github::Types::Response)
      expect(fetched_data.results).to be_an_instance_of(Array)
      expect(fetched_data.results.length).to eq(0)
    end

    it "fetch emails from the Github repo when there are 'issues'" do
      allow(octokit).to receive(:public_send).and_return(response)

      fetched_data = @fetcher.fetch

      expect(fetched_data).to be_an_instance_of(Fetcher::Github::Types::Response)
      expect(fetched_data.results).to be_an_instance_of(Array)
      expect(fetched_data.results.length).to eq(1)
    end
  end
end
