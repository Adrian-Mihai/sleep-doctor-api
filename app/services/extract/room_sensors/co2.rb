module Extract
  module RoomSensors
    class Co2 < Extract::RoomSensors::Base
      private

      def extract_data(row)
        {
          start_time: Time.parse(row['date']).utc.strftime('%F %T'),
          end_time: (Time.parse(row['date']).utc + 59).strftime('%F %T'),
          min: (row['co2_min'] || row['co2'] || row['air_quality']).to_f.round(2),
          mean: (row['co2_mean'] || row['co2'] || row['air_quality']).to_f.round(2),
          max: (row['co2_max'] || row['co2'] || row['air_quality']).to_f.round(2)
        }
      end
    end
  end
end
