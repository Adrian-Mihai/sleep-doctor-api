require 'zip'
require 'csv'

module Extract
  module RoomSensors
    class Base
      def initialize(uuid:)
        @room_sensors_file = RoomSensorsFile.find_by!(uuid: uuid)
      end

      def perform
        process_raw_data.sort_by { |record| record[:start_time] }
      end

      private

      def process_raw_data
        records = []
        record = { uuid: SecureRandom.uuid, start_time: nil, end_time: nil, min: nil, mean: nil, max: nil, payload: [] }

        Zip::File.open_buffer(@room_sensors_file.zip_file.download) do |zip_file|
          zip_file.each do |file|
            content = CSV.parse(file.get_input_stream.read, headers: true)
            content&.each do |row|
              date_time = Time.parse(row['date']).utc

              if date_time.min.zero?
                record = { uuid: SecureRandom.uuid, start_time: date_time.strftime('%F %T'), end_time: nil, min: nil, mean: nil, max: nil, payload: [] }
              end

              if date_time.min == 59
                record[:min] = record[:payload].pluck(:min).min
                record[:mean] = (record[:payload].pluck(:mean).sum.to_f / record[:payload].pluck(:mean).count).round(2)
                record[:max] = record[:payload].pluck(:max).max
                record[:end_time] = (date_time + 59).strftime('%F %T')
                records << record if record[:start_time].present? && record[:min].present? && record[:mean].present? && record[:max].present? && record[:end_time].present?
              end

              record[:payload] << extract_data(row)
            end
          end
        end
        records
      end

      def extract_data(_row)
        raise NotImplementedError, 'Implement in subclass'
      end
    end
  end
end
