# frozen_string_literal: true

RSpec.describe Mapper::Notion::BirthdayToday do
  before do
    @mapper = described_class.new
    fetcher_config = {
      base_url: "https://api.notion.com",
      database_id: "c17e556d16c84272beb4ee73ab709631",
      secret: "secret_BELfDH6cf4Glc9NLPLxvsvdl9iZVD4qBCyMDXqch51B",
      filter: {
        "filter": {
          "or": [
            {
              "property": "BD_this_year",
              "date": {
                "equals": "2024-01-24"
              }
            }
          ]
        },
        "sorts": []
      }
    }
    @fetcher = Fetcher::Notion::BirthdayToday.new(fetcher_config)
  end

  describe "attributes and arguments" do
    it { expect(described_class).to respond_to(:new).with(0).arguments }
    it { expect(@mapper).to respond_to(:map).with(1).arguments }
  end

  describe ".map" do
    it "maps the given data into a domain specific one" do
      VCR.use_cassette("/notion/birthdays/fetch_with_filter") do
        birthdays_response = @fetcher.fetch

        mapped_data = @mapper.map(birthdays_response)

        are_birthdays = mapped_data.all? { |element| element.is_a?(Domain::Birthday) }

        expect(mapped_data).to be_an_instance_of(Array)
        expect(mapped_data.length).to eq(1)
        expect(are_birthdays).to be_truthy
      end
    end
  end
end
