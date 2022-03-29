module Extract
  class Sleep < Extract::Base
    MINIMUM_SLEEP_DURATION = 4

    SLEEP_FILE_PATH = '*/com.samsung.shealth.sleep.[0-9]*.csv'.freeze
    SLEEP_STAGE_FILE_PATH = '*/com.samsung.health.sleep_stage.[0-9]*.csv'.freeze
    SLEEP_COMBINED_FILE_PATH = '*/com.samsung.shealth.sleep_combined.[0-9]*.csv'.freeze

    private

    def unzip
      Zip::File.open_buffer(@samsung_health_file.zip_file.download) do |zip_file|
        @sleep_file_content = CSV.parse(zip_file.glob(SLEEP_FILE_PATH).first.get_input_stream.read)
        @sleep_stage_file_content = CSV.parse(zip_file.glob(SLEEP_STAGE_FILE_PATH).first.get_input_stream.read)
        @sleep_combined_file_content = CSV.parse(zip_file.glob(SLEEP_COMBINED_FILE_PATH).first.get_input_stream.read)
      end
    end

    def columns
      {
        uuid: 34,
        mental_recovery: 1,
        physical_recovery: 15,
        movements_duration: 17,
        efficiency: 22,
        score: 23,
        cycle: 21,
        duration: 24,
        start_time: 25,
        end_time: 33,
        combined_id: 13,
        sleep_combined: {
          uuid: 31,
          mental_recovery: 2,
          physical_recovery: 17,
          movements_duration: 19,
          efficiency: 26,
          score: 27,
          cycle: 25,
          duration: 29,
          start_time: 1,
          end_time: 30
        },
        sleep_stage: {
          uuid: 10,
          start_time: 0,
          sleep_id: 1,
          stage: 5,
          end_time: 9
        }
      }
    end

    def process_raw_data
      data = (process_sleep_file || []).compact
      data += ((process_combined_sleep_file || [])).compact
      data.map { |sleep_record| sleep_record.merge(sleep_stages_attributes: extract_sleep_stages(sleep_record)) }
    end

    def process_sleep_file
      @sleep_file_content[2..]&.map do |row|
        next if row[columns[:combined_id]].present?
        next unless valid_row?(row) && grater_than_minimum_sleep_duration?(row[columns[:duration]].to_i)

        extract_sleep_data(row)
      end
    end

    def process_combined_sleep_file
      @sleep_combined_file_content[2..]&.map do |row|
        sleep_duration = row[columns.dig(:sleep_combined, :duration)].to_i
        next unless valid_combined_row?(row) && grater_than_minimum_sleep_duration?(sleep_duration)

        extract_sleep_combined_data(row)
      end
    end

    def valid_row?(row)
      row[columns[:uuid]].present? &&
        row[columns[:mental_recovery]].present? &&
        row[columns[:physical_recovery]].present? &&
        row[columns[:movements_duration]].present? &&
        row[columns[:efficiency]].present? &&
        row[columns[:score]].present? &&
        row[columns[:cycle]].present? &&
        row[columns[:duration]].present? &&
        row[columns[:start_time]].present? &&
        row[columns[:end_time]].present?
    end

    def valid_combined_row?(row)
      row[columns.dig(:sleep_combined, :uuid)].present? &&
        row[columns.dig(:sleep_combined, :mental_recovery)].present? &&
        row[columns.dig(:sleep_combined, :physical_recovery)].present? &&
        row[columns.dig(:sleep_combined, :movements_duration)].present? &&
        row[columns.dig(:sleep_combined, :efficiency)].present? &&
        row[columns.dig(:sleep_combined, :score)].present? &&
        row[columns.dig(:sleep_combined, :cycle)].present? &&
        row[columns.dig(:sleep_combined, :duration)].present? &&
        row[columns.dig(:sleep_combined, :start_time)].present? &&
        row[columns.dig(:sleep_combined, :end_time)].present?
    end

    def valid_sleep_stage_row?(row)
      row[columns.dig(:sleep_stage, :uuid)] &&
        row[columns.dig(:sleep_stage, :start_time)] &&
        row[columns.dig(:sleep_stage, :stage)] &&
        row[columns.dig(:sleep_stage, :end_time)]
    end

    def grater_than_minimum_sleep_duration?(sleep_duration)
      sleep_duration >= MINIMUM_SLEEP_DURATION * 60
    end

    def extract_sleep_data(row)
      {
        uuid: row[columns[:uuid]],
        mental_recovery: row[columns[:mental_recovery]].to_i,
        physical_recovery: row[columns[:physical_recovery]].to_i,
        movement_duration: row[columns[:movements_duration]].to_i,
        efficiency: row[columns[:efficiency]].to_i,
        score: row[columns[:score]],
        cycle: row[columns[:cycle]],
        duration: row[columns[:duration]],
        start_time: row[columns[:start_time]],
        end_time: row[columns[:end_time]]
      }
    end

    def extract_sleep_combined_data(row)
      {
        uuid: row[columns.dig(:sleep_combined, :uuid)],
        mental_recovery: row[columns.dig(:sleep_combined, :mental_recovery)].to_i,
        physical_recovery: row[columns.dig(:sleep_combined, :physical_recovery)].to_i,
        movement_duration: row[columns.dig(:sleep_combined, :movements_duration)].to_i,
        efficiency: row[columns.dig(:sleep_combined, :efficiency)].to_i,
        score: row[columns.dig(:sleep_combined, :score)],
        cycle: row[columns.dig(:sleep_combined, :cycle)],
        duration: row[columns.dig(:sleep_combined, :duration)],
        start_time: row[columns.dig(:sleep_combined, :start_time)],
        end_time: row[columns.dig(:sleep_combined, :end_time)]
      }
    end

    def extract_sleep_stages(sleep_record)
      sleep_stages_rows = find_sleep_stages(sleep_record[:uuid])
      if sleep_stages_rows.empty?
        sleep_com_records = find_sleep_combined_records(sleep_record[:uuid])
        stages_array = sleep_com_records.map { |sleep_com_record| find_sleep_stages(sleep_com_record[columns[:uuid]]) }
        sleep_stages_rows = stages_array.flatten(1)
      end

      sleep_stages = sleep_stages_rows.map do |row|
        next unless valid_sleep_stage_row?(row)

        {
          uuid: row[columns.dig(:sleep_stage, :uuid)],
          start_time: row[columns.dig(:sleep_stage, :start_time)],
          stage: row[columns.dig(:sleep_stage, :stage)][-1].to_i,
          end_time: row[columns.dig(:sleep_stage, :end_time)]
        }
      end
      sleep_stages.compact
    end

    def find_sleep_stages(sleep_record_uuid)
      @sleep_stage_file_content.find_all { |row| row[columns.dig(:sleep_stage, :sleep_id)] == sleep_record_uuid }
    end

    def find_sleep_combined_records(sleep_record_uuid)
      @sleep_file_content.find_all { |row| row[columns[:combined_id]] == sleep_record_uuid }
    end
  end
end
