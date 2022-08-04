module Extract
  module RoomSensors
    class Temperature < Extract::RoomSensors::Base
      private

      def extract_data(row)
        {
          start_time: Time.parse(row['date']).utc.strftime('%F %T %z'),
          end_time: (Time.parse(row['date']).utc.end_of_minute).strftime('%F %T %z'),
          min: (row['temperature_min'] || row['temperature']).to_f.round(2),
          mean: (row['temperature_mean'] || row['temperature']).to_f.round(2),
          max: (row['temperature_max'] || row['temperature']).to_f.round(2)
        }
      end
    end
  end
end
