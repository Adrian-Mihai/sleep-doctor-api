module Extract
  class Exercises < Extract::Base
    EXERCISE_FILE_PATH = '/Volumes/GoogleDrive/My Drive/samsunghealth_ardelean.adrian.mihai_202202201504/com.samsung.shealth.exercise.202202201504.csv'.freeze

    def initialize(exercise_file_path: EXERCISE_FILE_PATH)
      @exercise_file_content = CSV.read(exercise_file_path)
    end

    private

    def columns
      {
        uuid: 58,
        start_time: 23,
        type: 24,
        duration: 19,
        heart_rate: 28,
        calorie: 42,
        end_time: 57
      }
    end

    def process_raw_data
      @exercise_file_content[2..]&.map do |row|
        next unless valid_row?(row)

        extract_data(row)
      end
    end

    def valid_row?(row)
      row[columns[:uuid]].present? &&
        row[columns[:start_time]].present? &&
        row[columns[:type]].present? &&
        row[columns[:duration]].present? &&
        row[columns[:heart_rate]].present? &&
        row[columns[:calorie]].present? &&
        row[columns[:end_time]].present?
    end

    def extract_data(row)
      {
        uuid: row[columns[:uuid]],
        start_time: row[columns[:start_time]],
        type: row[columns[:type]],
        duration: row[columns[:duration]],
        heart_rate: row[columns[:heart_rate]],
        calorie: row[columns[:calorie]].to_f.round(2),
        end_time: row[columns[:end_time]]
      }
    end
  end
end
