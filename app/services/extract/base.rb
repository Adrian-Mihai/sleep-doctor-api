require 'zip'
require 'csv'

module Extract
  class Base
    def initialize(uuid:)
      @samsung_health_file = SamsungHealthFile.find_by(uuid: uuid)
    end

    def perform
      unzip
      data = process_raw_data || []
      data.compact!
      data.sort_by { |record| record[sort_column] }
    end

    private

    def unzip
      raise NotImplementedError, 'Implement in subclass'
    end

    def columns
      raise NotImplementedError, 'Implement in subclass'
    end

    def process_raw_data
      raise NotImplementedError, 'Implement in subclass'
    end

    def valid_row?(_row)
      raise NotImplementedError, 'Implement in subclass'
    end

    def extract_data(_row)
      raise NotImplementedError, 'Implement in subclass'
    end

    def sort_column
      :start_time
    end
  end
end
