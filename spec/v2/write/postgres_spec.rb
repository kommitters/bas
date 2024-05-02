# frozen_string_literal: true

require "v2/write/postgres"

RSpec.describe Write::Postgres do
  let(:pg_conn) { instance_double(PG::Connection) }
  let(:fail_process_result) { { error: { error: "error_message" } } }
  let(:success_process_result) { { success: { bas: [1, 2, 3] } } }

  before do
    @config = {
      connection: {
        host: "localhost",
        port: 5432,
        dbname: "bas",
        user: "postgres",
        password: "postgres"
      },
      db_table: "bas_table",
      bot_name: "BasBot"
    }

    pg_result = instance_double(PG::Result)

    allow(PG::Connection).to receive(:new).and_return(pg_conn)
    allow(pg_conn).to receive(:exec_params).and_return(pg_result)
  end

  describe ".execute" do
    it "save a success reponse" do
      writer = described_class.new(@config, success_process_result)

      expect(writer.execute).to_not be_nil
    end

    it "save a faile reponse" do
      writer = described_class.new(@config, fail_process_result)

      expect(writer.execute).to_not be_nil
    end
  end
end
