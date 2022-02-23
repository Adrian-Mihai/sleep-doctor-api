module Extract
  class Steps < Extract::Base
    STEPS_FILE_PATH = '/Volumes/GoogleDrive/My Drive/samsunghealth_ardelean.adrian.mihai_202202201504/com.samsung.shealth.tracker.pedometer_day_summary.202202201504.csv'.freeze

    def initialize(step_file_path: STEPS_FILE_PATH)
      @step_file_content = CSV.read(step_file_path)
    end

    private

    def columns
      {
        uuid: 17,
        date: 18,
        run: 4,
        walk: 12,
        calories: 11
      }
    end

    def process_raw_data
      @step_file_content[2..]&.map do |row|
        next unless valid_row?(row)

        extract_data(row)
      end
    end

    def valid_row?(row)
      row[columns[:uuid]].present? &&
        row[columns[:date]].present? &&
        row[columns[:run]].present? &&
        row[columns[:walk]].present? &&
        row[columns[:calories]].present?
    end

    def extract_data(row)
      {
        uuid: row[columns[:uuid]],
        date: Time.at(row[columns[:date]].to_i / 1000).utc.strftime('%F %T'),
        run: row[columns[:run]],
        walk: row[columns[:walk]],
        calories: row[columns[:calories]].to_f.round(2)
      }
    end

    def sort_column
      :date
    end
  end
end
