# frozen_string_literal: true

RSpec.describe Mapper::Base do
  describe ".map" do
    let(:testing_class) { Class.new { include Mapper::Base } }

    it "provides no implementation for the method" do
      instace = testing_class.new
      data = []
      expect { instace.map(data) }.to raise_exception(Domain::Exceptions::FunctionNotImplemented)
    end
  end
end
