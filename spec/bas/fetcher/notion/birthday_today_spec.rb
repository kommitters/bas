# frozen_string_literal: true

RSpec.describe Fetcher::Notion::BirthdayToday do
  before do
    @config = {
      database_id: "c17e556d16c84272beb4ee73ab709631",
      secret: "secret_BELfDH6cf4Glc9NLPLxvsvdl9iZVD4qBCyMDXqch51B"
    }

    @fetcher = described_class.new(@config)
  end

  describe "attributes and arguments" do
    it { expect(@fetcher).to respond_to(:config) }

    it { expect(described_class).to respond_to(:new).with(1).arguments }
    it { expect(@fetcher).to respond_to(:fetch).with(0).arguments }
  end

  describe ".fetch" do
    it "fetch data from the given configured notion database" do
      VCR.use_cassette("/notion/birthdays/fetch_with_filter") do
        birthdays_fetcher = described_class.new(@config)
        fetched_data = birthdays_fetcher.fetch

        expect(fetched_data).to be_an_instance_of(Fetcher::Notion::Types::Response)
        expect(fetched_data.results).to be_an_instance_of(Array)
        expect(fetched_data.results.length).to eq(1)
      end
    end

    it "fetch empty data from the given configured notion database" do
      VCR.use_cassette("/notion/birthdays/fetch_with_empty_database") do
        config = @config
        config[:database_id] = "a3de68d2848a4eceb9418ff6bf44d086"

        birthday_fetcher = described_class.new(config)
        fetched_data = birthday_fetcher.fetch

        expect(fetched_data).to be_an_instance_of(Fetcher::Notion::Types::Response)
        expect(fetched_data.results).to be_an_instance_of(Array)
        expect(fetched_data.results.length).to eq(0)
      end
    end

    it "raises an exception caused by invalid database_id provided" do
      VCR.use_cassette("/notion/birthdays/fetch_with_invalid_database_id") do
        config = @config
        config[:database_id] = "a17e556d16c84272beb4ee73ab709630"
        birthday_fetcher = described_class.new(@config)

        expected_exception = "Could not find database with ID: c17e556d-16c8-4272-beb4-ee73ab709631. " \
                             "Make sure the relevant pages and databases are shared with your integration."

        expect do
          birthday_fetcher.fetch
        end.to raise_exception(expected_exception)
      end
    end

    it "raise an exception caused by invalid or incorrect api_key provided" do
      VCR.use_cassette("/notion/birthdays/fetch_with_invalid_api_key") do
        config = @config
        config[:secret] = "secret_ZELfDH6cf4Glc9NLPLxvsvdl9iZVD4qBCyMDXqch51C"
        birthday_fetcher = described_class.new(config)

        expect { birthday_fetcher.fetch }.to raise_exception("API token is invalid.")
      end
    end
  end
end
