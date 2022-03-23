module Api
  module V1
    class SleepSessionsController < ApplicationController
      def index
        temperature_dataset = user.temperature_values.order(:start_time).pluck(:start_time, :mean, :end_time)
        humidity_dataset = user.humidity_values.order(:start_time).pluck(:start_time, :mean, :end_time)
        co2_level_dataset = user.co2_values.order(:start_time).pluck(:start_time, :mean, :end_time)
        heart_rate_dataset = user.heart_rate_values.order(:start_time).pluck(:start_time, :mean, :end_time)

        payload = user.sleep_sessions.order(:start_time).pluck(:start_time, :mental_recovery, :physical_recovery,
                                                               :efficiency, :score, :cycle, :duration, :end_time)
        payload.map! do |start_time, mental_recovery, physical_recovery, efficiency, score, cycle, duration, end_time|
          temperature = extract_mean_value(temperature_dataset, start_time, end_time)
          humidity = extract_mean_value(humidity_dataset, start_time, end_time)
          co2_level = extract_mean_value(co2_level_dataset, start_time, end_time)
          heart_rate = extract_mean_value(heart_rate_dataset, start_time, end_time)
          next if temperature.nil? || humidity.nil? || co2_level.nil? || heart_rate.nil?

          {
            start_time: start_time.localtime.strftime('%F %T %z'),
            mental_recovery: mental_recovery,
            physical_recovery: physical_recovery,
            efficiency: efficiency,
            cycle: cycle,
            duration: duration,
            temperature: temperature,
            humidity: humidity,
            co2_level: co2_level,
            heart_rate: heart_rate,
            score: score,
            end_time: end_time.localtime.strftime('%F %T %z')
          }
        end
        payload.compact!

        render json: payload, status: :ok
      end

      private

      def user
        return @user if defined? @user

        @user = User.find_by!(uuid: params[:user_id])
      end

      def extract_mean_value(dataset, start_time, end_time)
        subset = dataset.find_all { |record| (start_time..end_time).cover?(record.first) }
        return if subset.empty?

        total = subset.sum { |record| record[1] }
        (total / subset.count).round(2)
      end
    end
  end
end
