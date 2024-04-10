# frozen_string_literal: true

RSpec.describe Read::Notion::PtoNextWeek do
  before do
    @config = {
      database_id: "8187370982134ed099f9d14385aa81c9",
      secret: "secret_K5UCqm27GvAscTlaGJmS2se4fyM1K7is3OIZMw03NaC"
    }

    @read = described_class.new(@config)
  end

  describe "attributes and arguments" do
    it { expect(@read).to respond_to(:config) }

    it { expect(described_class).to respond_to(:new).with(1).arguments }
    it { expect(@read).to respond_to(:execute).with(0).arguments }
  end

  describe ".read" do
    it "read data from the given configured notion database" do
      VCR.use_cassette("/notion/pto_next_week/read_with_filter") do
        pto_reader = described_class.new(@config)
        readed_data = pto_reader.execute

        expect(readed_data).to be_an_instance_of(Read::Notion::Types::Response)
        expect(readed_data.results).to be_an_instance_of(Array)
        expect(readed_data.results.length).to eq(3)
      end
    end

    it "read empty data from the given configured notion database" do
      VCR.use_cassette("/notion/pto_next_week/read_with_empty_database") do
        config = @config
        config[:database_id] = "68bcbb5f76e14e5eb00ff6726bd90f6c"

        pto_reader = described_class.new(config)
        readed_data = pto_reader.execute

        expect(readed_data).to be_an_instance_of(Read::Notion::Types::Response)
        expect(readed_data.results).to be_an_instance_of(Array)
        expect(readed_data.results.length).to eq(0)
      end
    end

    it "raises an exception caused by invalid database_id provided" do
      VCR.use_cassette("/notion/pto_next_week/read_with_invalid_database_id") do
        config = @config
        config[:database_id] = "b68d11061aad43bd89f8f525ede2b598"
        pto_reader = described_class.new(config)

        expect do
          pto_reader.execute
        end.to raise_exception("Could not find database with ID: b68d1106-1aad-43bd-89f8-f525ede2b598. " \
                                "Make sure the relevant pages and databases are shared with your integration.")
      end
    end

    it "raises an exception caused by invalid or incorrect api_key provided" do
      VCR.use_cassette("/notion/pto_next_week/read_with_invalid_api_key") do
        config = @config
        config[:secret] = "secret_ZELfDH6cf4Glc9NLPLxvsvdl9iZVD4qBCyMDXqch51C"
        pto_reader = described_class.new(config)

        expect { pto_reader.execute }.to raise_exception("API token is invalid.")
      end
    end
  end
end
