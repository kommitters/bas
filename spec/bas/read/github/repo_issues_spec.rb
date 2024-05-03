# frozen_string_literal: true

require "bas/read/github/use_case/repo_issues"

RSpec.describe Read::Github::RepoIssues do
  before do
    config = {
      app_id: "123456",
      installation_id: "78910",
      secret_path: "secrets_file_path.pem",
      repo: "Organization/Repository"
    }

    @read = described_class.new(config)
  end

  describe "attributes and arguments" do
    it { expect(described_class).to respond_to(:new).with(1).arguments }

    it { expect(@read).to respond_to(:config) }
    it { expect(@read).to respond_to(:execute).with(0).arguments }
  end

  describe ".execute" do
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

    it "read issues from the Github repo when there are no 'issues'" do
      allow(octokit).to receive(:public_send).and_return(empty_response)

      read_data = @read.execute

      expect(read_data).to be_an_instance_of(Read::Github::Types::Response)
      expect(read_data.results).to be_an_instance_of(Array)
      expect(read_data.results.length).to eq(0)
    end

    it "read issues from the Github repo when there are 'issues'" do
      allow(octokit).to receive(:public_send).and_return(response)

      read_data = @read.execute

      expect(read_data).to be_an_instance_of(Read::Github::Types::Response)
      expect(read_data.results).to be_an_instance_of(Array)
      expect(read_data.results.length).to eq(1)
    end
  end
end
