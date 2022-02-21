require 'csv'

module Extract
  class HeartRate
    HEART_RATE_FILE_PATH = '/Volumes/GoogleDrive/My Drive/samsunghealth_ardelean.adrian.mihai_202202201504/com.samsung.shealth.tracker.heart_rate.202202201504.csv'.freeze

    def initialize(heart_rate_file_path: HEART_RATE_FILE_PATH)
      @heart_rate_file_content = CSV.read(heart_rate_file_path)
      @data = []
    end

    def perform
      @heart_rate_file_content[2..]&.each do |row|
        next unless valid_row?(row)

        @data << extract_heart_rate_data(row)
      end

      @data
    end

    private

    def columns
      {
        uuid: 15,
        start_time: 3,
        heart_rate: 16,
        end_time: 14,
        binning_data: 5
      }
    end

    def valid_row?(row)
      row[columns[:uuid]].present? &&
        row[columns[:start_time]].present? &&
        row[columns[:heart_rate]].present? &&
        row[columns[:end_time]].present?
    end

    def extract_heart_rate_data(row)
      heart_rate = {
        uuid: row[columns[:uuid]],
        start_time: row[columns[:start_time]],
        value: row[columns[:heart_rate]],
        end_time: row[columns[:end_time]],
        details: []
      }

      if row[columns[:binning_data]].present?
        binning_data_file = Dir["/Volumes/GoogleDrive/My Drive/samsunghealth_ardelean.adrian.mihai_202202201504/jsons/*/*/#{row[columns[:binning_data]]}"].first
        return if binning_data_file.nil?

        heart_rate[:details] = JSON.parse(File.read(binning_data_file), symbolize_names: true).map do |binning_data|
          {
            start_time: Time.at(binning_data[:start_time] / 1000).utc.strftime('%F %T'),
            heart_rate: binning_data[:heart_rate],
            end_time: Time.at(binning_data[:end_time] / 1000).utc.strftime('%F %T')
          }
        end
      end

      heart_rate
    end
  end
end
