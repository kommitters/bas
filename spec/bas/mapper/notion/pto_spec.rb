# frozen_string_literal: true

RSpec.describe Mapper::Notion::PtoToday do
  before do
    @mapper = described_class.new
    fetcher_config = {
      base_url: "https://api.notion.com",
      database_id: "b68d11061aad43bd89f8f525ede2b598",
      secret: "secret_ZELfDH6cf4Glc9NLPLxvsvdl9iZVD4qBCyMDXqch51C",
      filter: {
        "filter": {
          "and": [
            {
              property: "Desde?",
              date: {
                "on_or_before": "2024-01-24"
              }
            },
            {
              property: "Hasta?",
              date: {
                "on_or_after": "2024-01-24"
              }
            }
          ]
        },
        "sorts": []
      }
    }
    @fetcher = Fetcher::Notion::PtoToday.new(fetcher_config)
  end

  describe "attributes and arguments" do
    it { expect(described_class).to respond_to(:new).with(0).arguments }
    it { expect(@mapper).to respond_to(:map).with(1).arguments }
  end

  describe ".map" do
    it "maps the given data into a domain specific one" do
      VCR.use_cassette("/notion/ptos/fetch_with_filter") do
        ptos_response = @fetcher.fetch
        mapped_data = @mapper.map(ptos_response)

        are_ptos = mapped_data.all? { |element| element.is_a?(Domain::Pto) }

        expect(mapped_data).to be_an_instance_of(Array)
        expect(mapped_data.length).to eq(3)
        expect(are_ptos).to be_truthy
      end
    end
  end
end
