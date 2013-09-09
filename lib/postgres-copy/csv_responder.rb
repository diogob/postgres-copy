module Responders
  module CsvResponder
    def to_csv
      controller.response_body = Enumerator.new do |y|
        controller.send(:end_of_association_chain).copy_to do |line|
          y << line
        end
      end
    end
  end
end
