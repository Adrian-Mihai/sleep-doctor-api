require 'csv'

module Extract
  class Stress
    STRESS_FILE_FILE_PATH = '/Volumes/GoogleDrive/My Drive/samsunghealth_ardelean.adrian.mihai_202202201504/com.samsung.shealth.stress.202202201504.csv'.freeze

    def initialize(stress_file_path: STRESS_FILE_FILE_PATH)
      @stress_file_content = CSV.read(stress_file_path)
    end

    def perform
      data = process_raw_data || []
      data.compact!
      data.sort_by { |record| record[:start_time] }
    end

    private

    def columns
      {
        uuid: 15,
        start_time: 0,
        score: 8,
        end_time: 14,
        binning_data: 2
      }
    end

    def process_raw_data
      @stress_file_content[2..]&.map do |row|
        next unless valid_row?(row)

        extract_data(row)
      end
    end

    def valid_row?(row)
      row[columns[:uuid]].present? &&
        row[columns[:start_time]].present? &&
        row[columns[:score]].present? &&
        row[columns[:end_time]].present?
    end

    def extract_data(row)
      stress = {
        uuid: row[columns[:uuid]],
        start_time: row[columns[:start_time]],
        value: row[columns[:score]],
        end_time: row[columns[:end_time]],
        details: []
      }

      if row[columns[:binning_data]].present?
        binning_data_file = Dir["/Volumes/GoogleDrive/My Drive/samsunghealth_ardelean.adrian.mihai_202202201504/jsons/*/*/#{row[columns[:binning_data]]}"].first
        return if binning_data_file.nil?

        stress[:details] = JSON.parse(File.read(binning_data_file), symbolize_names: true).map do |binning_data|
          {
            start_time: Time.at(binning_data[:start_time] / 1000).utc.strftime('%F %T'),
            score: binning_data[:score],
            end_time: Time.at(binning_data[:end_time] / 1000).utc.strftime('%F %T')
          }
        end
      end

      stress
    end
  end
end
