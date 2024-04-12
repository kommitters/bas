# frozen_string_literal: true

RSpec.describe Serialize::Base do
  describe ".execute" do
    let(:testing_class) { Class.new { include Serialize::Base } }

    it "provides no implementation for the method" do
      instace = testing_class.new
      data = []
      expect { instace.execute(data) }.to raise_exception(Domain::Exceptions::FunctionNotImplemented)
    end
  end
end
