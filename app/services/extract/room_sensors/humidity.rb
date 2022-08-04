module Extract
  module RoomSensors
    class Humidity < Extract::RoomSensors::Base
      private

      def extract_data(row)
        {
          start_time: Time.parse(row['date']).utc.strftime('%F %T %z'),
          end_time: (Time.parse(row['date']).utc.end_of_minute).strftime('%F %T %z'),
          min: (row['humidity_min'] || row['humidity']).to_f.round(2),
          mean: (row['humidity_mean'] || row['humidity']).to_f.round(2),
          max: (row['humidity_max'] || row['humidity']).to_f.round(2)
        }
      end
    end
  end
end
