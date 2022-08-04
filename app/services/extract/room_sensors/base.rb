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

        Zip::File.open_buffer(@room_sensors_file.zip_file.download) do |zip_file|
          zip_file.each do |file|
            content = CSV.parse(file.get_input_stream.read, headers: true)&.sort_by { |row| Time.parse(row['date']) }
            next if content.nil?

            utc_date = Time.parse(content.first['date']).utc
            start_time = utc_date.beginning_of_hour
            end_time = utc_date.end_of_hour
            record = { uuid: SecureRandom.uuid, start_time: start_time.strftime('%F %T'), end_time: end_time.strftime('%F %T'), min: nil, mean: nil, max: nil, payload: [] }

            content[1..]&.each do |row|
              utc_date = Time.parse(row['date']).utc

              if utc_date >= end_time
                record[:min] = record[:payload].pluck(:min).min
                record[:mean] = (record[:payload].pluck(:mean).sum.to_f / record[:payload].count).round(2)
                record[:max] = record[:payload].pluck(:max).max
                records << record

                start_time = utc_date.beginning_of_hour
                end_time = utc_date.end_of_hour
                record = { uuid: SecureRandom.uuid, start_time: start_time.strftime('%F %T'), end_time: end_time.strftime('%F %T'), min: nil, mean: nil, max: nil, payload: [] }
              end

              record[:payload] << extract_data(row)
            end

            record[:min] = record[:payload].pluck(:min).min
            record[:mean] = (record[:payload].pluck(:mean).sum.to_f / record[:payload].count).round(2)
            record[:max] = record[:payload].pluck(:max).max
            records << record
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
