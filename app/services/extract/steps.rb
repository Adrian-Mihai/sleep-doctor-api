require 'csv'

module Extract
  class Steps
    STEPS_FILE_PATH = '/Volumes/GoogleDrive/My Drive/samsunghealth_ardelean.adrian.mihai_202202201504/com.samsung.shealth.tracker.pedometer_step_count.202202201504.csv'.freeze

    def initialize(step_file_path: STEPS_FILE_PATH)
      @step_file_content = CSV.read(step_file_path)
      @data = []
    end

    def perform
      @step_file_content[2..]&.each do |row|
        next unless valid_row?(row)

        @data << extract_steps(row)
      end

      @data
    end

    private

    def columns
      {
        uuid: 17,
        start_time: 4,
        run: 2,
        walk: 3,
        calories: 12,
        end_time: 16
      }
    end

    def valid_row?(row)
      row[columns[:uuid]].present? &&
        row[columns[:start_time]].present? &&
        row[columns[:run]].present? &&
        row[columns[:walk]].present? &&
        row[columns[:calories]].present? &&
        row[columns[:end_time]].present?
    end

    def extract_steps(row)
      {
        uuid: row[columns[:uuid]],
        start_time: row[columns[:start_time]],
        run: row[columns[:run]],
        walk: row[columns[:walk]],
        calories: row[columns[:calories]].to_f.round(2),
        end_time: row[columns[:end_time]]
      }
    end
  end
end
