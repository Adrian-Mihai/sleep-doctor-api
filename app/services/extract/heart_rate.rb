module Extract
  class HeartRate < Extract::Base
    HEART_RATE_FILE_PATH = '*/com.samsung.shealth.tracker.heart_rate.*.csv'.freeze

    private

    def unzip; end

    def columns
      {
        uuid: 15,
        start_time: 3,
        min: 9,
        heart_rate: 16,
        max: 8,
        end_time: 14,
        binning_data: 5
      }
    end

    def process_raw_data
      data = []
      Zip::File.open_buffer(@samsung_health_file.zip_file.download) do |zip_file|
        heart_rate_file_content = CSV.parse(zip_file.glob(HEART_RATE_FILE_PATH).first.get_input_stream.read)

        data = heart_rate_file_content[2..]&.map do |row|
          next unless valid_row?(row)

          binning_data_file = zip_file.glob("**/#{row[columns[:binning_data]]}").first
          next if binning_data_file.nil?

          heart_rate = extract_data(row)
          heart_rate[:payload] = JSON.parse(binning_data_file.get_input_stream.read, symbolize_names: true).map do |binning_data|
            {
              start_time: Time.at(binning_data[:start_time] / 1000).utc.strftime('%F %T %z'),
              min: binning_data[:heart_rate_min].to_f.round(2),
              mean: binning_data[:heart_rate].to_f.round(2),
              max: binning_data[:heart_rate_max].to_f.round(2),
              end_time: Time.at(binning_data[:end_time] / 1000).utc.strftime('%F %T %z')
            }
          end
          heart_rate
        end
      end
      data
    end

    def valid_row?(row)
      row[columns[:uuid]].present? &&
        row[columns[:binning_data]].present? &&
        row[columns[:start_time]].present? &&
        row[columns[:min]].present? &&
        row[columns[:heart_rate]].present? &&
        row[columns[:max]].present? &&
        row[columns[:end_time]].present?
    end

    def extract_data(row)
      {
        uuid: row[columns[:uuid]],
        start_time: row[columns[:start_time]],
        min: row[columns[:min]].to_f.round(2),
        mean: row[columns[:heart_rate]].to_f.round(2),
        max: row[columns[:max]].to_f.round(2),
        end_time: row[columns[:end_time]],
        payload: []
      }
    end
  end
end
