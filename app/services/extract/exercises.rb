module Extract
  class Exercises < Extract::Base
    EXERCISE_FILE_PATH = '*/com.samsung.shealth.exercise.*.csv'.freeze

    private

    def unzip
      Zip::File.open_buffer(@samsung_health_file.zip_file.download) do |zip_file|
        @exercise_file_content = CSV.parse(zip_file.glob(EXERCISE_FILE_PATH).first.get_input_stream.read)
      end
    end

    def columns
      {
        uuid: 58,
        start_time: 23,
        type: 24,
        duration: 19,
        min_heart_rate: 38,
        mean_heart_rate: 28,
        max_heart_rate: 32,
        calorie: 42,
        end_time: 57
      }
    end

    def process_raw_data
      @exercise_file_content[2..]&.map do |row|
        next unless valid_row?(row)
        next if row[columns[:type]].to_i.zero?

        extract_data(row)
      end
    end

    def valid_row?(row)
      row[columns[:uuid]].present? &&
        row[columns[:start_time]].present? &&
        row[columns[:type]].present? &&
        row[columns[:duration]].present? &&
        row[columns[:min_heart_rate]].present? &&
        row[columns[:mean_heart_rate]].present? &&
        row[columns[:max_heart_rate]].present? &&
        row[columns[:calorie]].present? &&
        row[columns[:end_time]].present?
    end

    def extract_data(row)
      {
        uuid: row[columns[:uuid]],
        start_time: row[columns[:start_time]],
        exercise_type: row[columns[:type]].to_i,
        duration: row[columns[:duration]],
        min_heart_rate: row[columns[:min_heart_rate]].to_f.round(2),
        mean_heart_rate: row[columns[:mean_heart_rate]].to_f.round(2),
        max_heart_rate: row[columns[:max_heart_rate]].to_f.round(2),
        burned_calorie: row[columns[:calorie]].to_f.round(2),
        end_time: row[columns[:end_time]]
      }
    end
  end
end
