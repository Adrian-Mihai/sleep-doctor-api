module Extract
  class Stress < Extract::Base
    STRESS_FILE_FILE_PATH = '*/com.samsung.shealth.stress.*.csv'.freeze

    private

    def unzip; end

    def columns
      {
        uuid: 15,
        start_time: 0,
        min: 7,
        score: 8,
        max: 6,
        end_time: 14,
        binning_data: 2
      }
    end

    def process_raw_data
      data = []
      Zip::File.open_buffer(@samsung_health_file.zip_file.download) do |zip_file|
        stress_file_content = CSV.parse(zip_file.glob(STRESS_FILE_FILE_PATH).first.get_input_stream.read)

        data = stress_file_content[2..]&.map do |row|
          next unless valid_row?(row)

          binning_data_file = zip_file.glob("**/#{row[columns[:binning_data]]}").first
          next if binning_data_file.nil?

          stress = extract_data(row)
          stress[:payload] = JSON.parse(binning_data_file.get_input_stream.read, symbolize_names: true).map do |binning_data|
            {
              start_time: Time.at(binning_data[:start_time] / 1000).utc.strftime('%F %T'),
              min: binning_data[:score_min].to_f.round(2),
              mean: binning_data[:score].to_f.round(2),
              max: binning_data[:score_max].to_f.round(2),
              end_time: Time.at(binning_data[:end_time] / 1000).utc.strftime('%F %T')
            }
          end
          stress
        end
      end
      data
    end

    def valid_row?(row)
      row[columns[:uuid]].present? &&
        row[columns[:binning_data]].present? &&
        row[columns[:start_time]].present? &&
        row[columns[:min]].present? &&
        row[columns[:score]].present? &&
        row[columns[:max]].present? &&
        row[columns[:end_time]].present?
    end

    def extract_data(row)
      {
        uuid: row[columns[:uuid]],
        start_time: row[columns[:start_time]],
        min: row[columns[:min]].to_f.round(2),
        mean: row[columns[:score]].to_f.round(2),
        max: row[columns[:max]].to_f.round(2),
        end_time: row[columns[:end_time]],
        payload: []
      }
    end
  end
end
