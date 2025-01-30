# frozen_string_literal: true

require "bas/utils/github/octokit_client"

RSpec.describe Utils::Github::OctokitClient do
  let(:client) { instance_double("Octokit::Client") }
  let(:repo) { "test/repo" }
  let(:mock_private_key) do
    <<~PEM
      -----BEGIN RSA PRIVATE KEY-----
      MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDHSL4AcINc2QAa
      WeaFLwkX2I/AXfkn/vP5LIX7Zue6JdOyhcv/Ux7OpUtM8/MkEbOSh6XIgsi4OKoK
      WuEgWWmjVSTTtKsM1JVufLsy9ULQJqQxBsTNlt62H4L3PNEgBjJ0KgGmH2dL7ode
      NLkqOjNphoYbecEjzmOmJQpi02gZv6AXKFdY44YzbuiN/dPqMaMQwws+EKO+Ixp1
      klSj7lzLrqDHDg14H0cgR+rV0jduJ+GkVe+ZwojaC5BAJq0Ykb3B8z1Sb050L3jT
      EQuENUZDUocpw8X281RUuFXaLTipxuwbBkftAWvO3i52IG6f5nWgIpjbaxTL84Rg
      f1DlQR/XAgMBAAECggEAKalud18OR2niWJ/0zmEf8IlIvDmpLhBh5vTE6eMAjOz9
      jfPkyvMQnLj3vhW9/gtpVDfhk8Krvb+y5MlNCVtH92qEcXHy1JLYzqlq5WNa3XNG
      ni1BFY3173M1CQUA30YMZDan85fbG4e5axtwnoBeYTBLdxEELL0oHgLeYfy6Za9I
      hWjelRg2tRVAlJAOapWgLtiGdeIZfQec25aV53hfzxyKR1TXP8pPTrXJpby6sArc
      o95TuhrorKY58tLx17ZPndD5GgyGHzGRrWN7cucftPIM+CU9Ov/oK0Tq5hXIdl5M
      yyi0AztnXwLLW/F3V/kZBAWz5+6JAtAdu5jIdVS6wQKBgQDpif77I76bxz1NBt8x
      U6Iy3sW5jwbsyZhkC2FuOd10+NeuX6hotF2uLH+sWZ7f5TMq4usxALFW0F4EbaoE
      Rw8TRgO92wv3C8LG/OZgkZ4lFIZdS/xYwfcBO18UpE30RKn8DUJ7DQZoIxq+HzA8
      pwMtiFTKwnRbMU5YicrhbnAQdwKBgQDac1nA/nBjHuVJWwyRPJelLSyfiRjvkVLn
      O/517lSO0aftwPg2+tjgeilJPN7vVZTKzzAxq1kBUPGHZJqUeiM30DYlhHlxPEwE
      dh+9fpDgpPIh8LiyKwFikRQ65RqUwV06nbjBH5gpIEwXoRUqwG7R1bieLYvP1RuC
      p0q8Ec2joQKBgCXCLfuk19iP6hVeGw/6marn4cgSm+gE4CKsxF/x8yBKa3TB+pST
      NOJIR4wyIUHJ6O/yKFyP5BxJLCpDIM34PzO6ijhUBic3O5K4qPbMFGmiW+cRtgcT
      tT/5vXG07vWjdGhQLIOAo5yKsHQ0zrO/vP/Lnwn5Tp6/5g7imG7CUFQZAoGAflpo
      GNRTB1IwhzyNyVgF0rmNbP2sma0yCaPO7EGdUTp9amzKZWq0lSqzxLPbsw2KUcCD
      fMdCZRt/iLOtIaJ/ymG5X/v/Dns08QOuGjoh7H4bu3v0KMHtPCj0TZiExnQNy8C8
      w5/VsDwJJ0W564+AyghXj86CZwU5s1m2RY/6pOECgYBxLaFybXTUi8xs68jdNgB9
      ui9dXooycsO5xc1wbowxGAcNxkvcl4BcpuW1BQNwDgYeuR07u2YwcehfBQ/ZF1wT
      AFjGplfIUIyQfS6Du8PgcGZFpqKFvQoYitMmj0riqrggeNNdt8Ntbr6txxy/osNV
      O5pPt/hOqHch2SF+LgfxNw==
      -----END RSA PRIVATE KEY-----
    PEM
  end

  let(:params) do
    { app_id: "123456", private_pem: mock_private_key, organization: "test-org" }
  end

  before do
    allow(Octokit::Client).to receive(:new).and_return(client)
    allow(client).to receive(:repository).with(repo).and_return({ name: "test-repo" })

    installation = double("Sawyer::Resource", id: 123_456)
    allow(client).to receive(:find_organization_installation).with("test-org").and_return(installation)

    allow(client).to receive(:create_app_installation_access_token).with(123_456).and_return({ token: "mock_access_token" })
  end

  describe "#repository_info" do
    it "retrieves repository information successfully" do
      client_instance = described_class.new(params)
      expect(client_instance.repository_info(repo)).to eq({ name: "test-repo" })
    end

    context "when the repository does not exist" do
      it "returns an error" do
        allow(client).to receive(:repository).with(repo).and_raise(Octokit::NotFound)
        client_instance = described_class.new(params)
        expect(client_instance.repository_info(repo)).to include(error: "Octokit::NotFound")
      end
    end
  end

  describe "#execute" do
    it "returns a client instance" do
      client_instance = described_class.new(params)
      expect(client_instance.execute).to include(client: client)
    end

    context "when JWT generation fails" do
      it "returns an error" do
        allow(JWT).to receive(:encode).and_raise(JWT::EncodeError)
        client_instance = described_class.new(params)
        expect(client_instance.execute).to include(error: /JWT::EncodeError/)
      end
    end

    context "when the organization installation is not found" do
      it "returns an error" do
        allow(client).to receive(:find_organization_installation).and_raise(Octokit::NotFound)
        client_instance = described_class.new(params)
        expect(client_instance.execute).to include(error: "Octokit::NotFound")
      end
    end

    context "when the access token cannot be created" do
      it "returns an error" do
        allow(client).to receive(:create_app_installation_access_token).and_raise(Octokit::Unauthorized)
        client_instance = described_class.new(params)
        expect(client_instance.execute).to include(error: /Unauthorized/)
      end
    end
  end
end
