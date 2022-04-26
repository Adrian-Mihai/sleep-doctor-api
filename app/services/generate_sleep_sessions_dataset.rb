class GenerateSleepSessionsDataset
  attr_reader :errors

  SLEEP_SESSIONS_BATCH_SIZE = 1000

  def initialize(user_uuid:, allow_missing_values:)
    @errors = []
    @user = User.find_by!(uuid: user_uuid)
    @allow_missing_values = allow_missing_values
  rescue ActiveRecord::RecordNotFound => e
    @errors << "#{e.model} not found"
  end

  def sleep_sessions_dataset
    return @sleep_sessions_dataset if defined? @sleep_sessions_dataset

    @sleep_sessions_dataset = []
    @user.sleep_sessions.includes(:sleep_stages).order(:start_time).find_in_batches(batch_size: SLEEP_SESSIONS_BATCH_SIZE) do |sleep_sessions|
      sleep_sessions.each_with_index do |sleep_session, index|
        next if index.zero?

        temperature = calculate_mean_values(room_temperature_dataset, sleep_session.start_time, sleep_session.end_time, :night_time)
        humidity = calculate_mean_values(room_humidity_dataset, sleep_session.start_time, sleep_session.end_time, :night_time)
        co2_level = calculate_mean_values(room_co2_level_dataset, sleep_session.start_time, sleep_session.end_time, :night_time)
        night_time_heart_rate = calculate_mean_values(heart_rate_dataset, sleep_session.start_time, sleep_session.end_time, :night_time)

        day_time_heart_rate = calculate_mean_values(heart_rate_dataset, sleep_sessions[index - 1].end_time, sleep_session.start_time, :day_time)
        day_time_stress_level = calculate_mean_values(stress_level_dataset, sleep_sessions[index - 1].end_time, sleep_session.start_time, :day_time)

        exercises = calculate_daily_exercises(sleep_sessions[index - 1].end_time, sleep_session.start_time)

        next if invalid_values?(temperature, humidity, co2_level, night_time_heart_rate, day_time_heart_rate, day_time_stress_level)

        payload = {
          start_time: sleep_session.start_time.localtime.strftime('%F %T %z'),
          mental_recovery: sleep_session.mental_recovery,
          physical_recovery: sleep_session.physical_recovery,
          awake_stage_duration: calculate_sleep_stage_duration(sleep_session, awake_stage),
          light_sleep_stage_duration: calculate_sleep_stage_duration(sleep_session, light_sleep_stage),
          deep_sleep_stage_duration: calculate_sleep_stage_duration(sleep_session, deep_sleep_stage),
          rem_stage_duration: calculate_sleep_stage_duration(sleep_session, rem_stage),
          sleep_cycles: sleep_session.cycle,
          awake_movement_duration: sleep_session.movement_duration,
          sleep_session_duration: sleep_session.duration,
        }

        payload.merge!(night_time_heart_rate.transform_keys { |k| "night_time_mean_heart_rate_(#{k})" })
        payload.merge!(temperature.transform_keys { |k| "night_time_room_mean_temperature_(#{k})" })
        payload.merge!(humidity.transform_keys { |k| "night_time_room_mean_humidity_(#{k})" })
        payload.merge!(co2_level.transform_keys { |k| "night_time_room_mean_co2_level_(#{k})" })
        payload.merge!(day_time_heart_rate.transform_keys { |k| "day_time_mean_heart_rate_(#{k})" })
        payload.merge!(day_time_stress_level.transform_keys { |k| "day_time_mean_stress_level_(#{k})" })

        payload[:exercise_sessions_burned_calories] = exercises[:burned_calories]
        payload[:exercise_sessions_duration] = exercises[:duration]
        payload[:score] = sleep_session.score
        payload[:end_time] = sleep_session.end_time.localtime.strftime('%F %T %z')

        @sleep_sessions_dataset << payload.stringify_keys
      end
    end
    replace_missing_values_with_mean if allow_missing_values?

    @sleep_sessions_dataset
  end

  def valid?
    @errors.empty?
  end

  private

  def invalid_values?(temperature, humidity, co2_level, night_time_heart_rate, day_time_heart_rate, day_time_stress_level)
    return true if temperature.nil? || humidity.nil? || co2_level.nil? || night_time_heart_rate.nil? || day_time_heart_rate.nil? || day_time_stress_level.nil?
    return false if temperature.size == 4 && humidity.size == 4 && co2_level.size == 4 && night_time_heart_rate.size == 4 && day_time_heart_rate.size == 4 && day_time_stress_level.size == 4

    true
  end

  def calculate_mean_values(dataset, start_time, end_time, time)
    subset = dataset.find_all { |record| (start_time..end_time).cover?(record[:start_time]) }
    return if subset.empty? && !allow_missing_values?

    periods = time == :day_time ? split_day_time_in_periods(start_time) : split_night_time_in_periods(end_time)
    periods.map do |period|
      period_values = subset.find_all { |record| (period.first..period.last).cover?(record[:start_time]) }
      next if period_values.empty? && !allow_missing_values?

      ["#{period.first.strftime('%H')}-#{(period.last + 1).strftime('%H')}", calculate_mean_value(period_values)]
    end.compact.to_h
  end

  def split_day_time_in_periods(start_time)
    start_period = start_time.at_beginning_of_day + 7.hours
    periods = []
    4.times do
      end_period = start_period + 4.hours
      periods << [start_period, (end_period - 1)]
      start_period = end_period
    end
    periods
  end

  def split_night_time_in_periods(end_time)
    start_period = end_time.at_beginning_of_day - 1.hour
    periods = []
    4.times do
      end_period = start_period + 2.hours
      periods << [start_period, (end_period - 1)]
      start_period = end_period
    end
    periods
  end

  def calculate_daily_exercises(start_time, end_time)
    exercises = exercises_dataset.find_all { |record| (start_time..end_time).cover?(record[:start_time]) }
    burned_calories = exercises.sum { |exercise| exercise[:burned_calorie] }
    duration = exercises.sum { |exercise| exercise[:duration] }

    { burned_calories: burned_calories, duration: milliseconds_to_minutes(duration) }
  end

  def milliseconds_to_minutes(duration)
    (duration.to_f / 60000).round
  end

  def room_temperature_dataset
    return @room_temperature_dataset if defined? @room_temperature_dataset

    @room_temperature_dataset = @user.temperature_values.order(:start_time).pluck(:start_time, :mean, :end_time)
    @room_temperature_dataset.map! do |start_time, mean, end_time|
      {
        start_time: start_time,
        mean: mean,
        end_time: end_time
      }
    end
  end

  def room_humidity_dataset
    return @room_humidity_dataset if defined? @room_humidity_dataset

    @room_humidity_dataset = @user.humidity_values.order(:start_time).pluck(:start_time, :mean, :end_time)
    @room_humidity_dataset.map! do |start_time, mean, end_time|
      {
        start_time: start_time,
        mean: mean,
        end_time: end_time
      }
    end
  end

  def room_co2_level_dataset
    return @room_co2_level_dataset if defined? @room_co2_level_dataset

    @room_co2_level_dataset = @user.co2_values.order(:start_time).pluck(:start_time, :mean, :end_time)
    @room_co2_level_dataset.map! do |start_time, mean, end_time|
      {
        start_time: start_time,
        mean: mean,
        end_time: end_time
      }
    end
  end

  def heart_rate_dataset
    return @heart_rate_dataset if defined? @heart_rate_dataset

    @heart_rate_dataset = @user.heart_rate_values.order(:start_time).pluck(:start_time, :mean, :end_time)
    @heart_rate_dataset.map! do |start_time, mean, end_time|
      {
        start_time: start_time,
        mean: mean,
        end_time: end_time
      }
    end
  end

  def stress_level_dataset
    return @stress_level_dataset if defined? @stress_level_dataset

    @stress_level_dataset = @user.stress_values.order(:start_time).pluck(:start_time, :mean, :end_time)
    @stress_level_dataset.map! do |start_time, mean, end_time|
      {
        start_time: start_time,
        mean: mean,
        end_time: end_time
      }
    end
  end

  def exercises_dataset
    return @exercises_dataset if defined? @exercises_dataset

    @exercises_dataset = @user.exercises.order(:start_time).pluck(:start_time, :burned_calorie, :duration, :end_time)
    @exercises_dataset.map! do |start_time, burned_calorie, duration, end_time|
      {
        start_time: start_time,
        burned_calorie: burned_calorie,
        duration: duration,
        end_time: end_time
      }
    end
  end

  def calculate_sleep_stage_duration(sleep_session, sleep_stage)
    stages = sleep_session.sleep_stages.find_all { |record| record.stage == sleep_stage }.pluck(:start_time, :end_time)
    stages.map! { |start_time, end_time| (end_time - start_time) / 1.minute }
    stages.sum.round
  end

  def awake_stage
    SleepStage.stages.index(SleepStage::AWAKEN)
  end

  def light_sleep_stage
    SleepStage.stages.index(SleepStage::LIGHT_SLEEP)
  end

  def deep_sleep_stage
    SleepStage.stages.index(SleepStage::DEEP_SLEEP)
  end

  def rem_stage
    SleepStage.stages.index(SleepStage::REM)
  end

  def calculate_mean_value(values)
    return 0 if values.count.zero?

    (values.sum { |record| record[:mean] } / values.count).round(2)
  end

  def allow_missing_values?
    @allow_missing_values == 'true'
  end

  def replace_missing_values_with_mean
    @sleep_sessions_dataset.each_with_index do |sleep_session, index|
      subset = []
      up_index = index
      down_index = index

      5.times do
        up_index += 1
        down_index -= 1
        subset << @sleep_sessions_dataset[up_index] unless @sleep_sessions_dataset[up_index].nil?
        subset << @sleep_sessions_dataset[down_index] unless down_index.negative?
      end

      night_time_mean_heart_rate_23_01 = (subset.pluck('night_time_mean_heart_rate_(23-01)').sum / subset.count).round(2)
      night_time_mean_heart_rate_01_03 = (subset.pluck('night_time_mean_heart_rate_(01-03)').sum / subset.count).round(2)
      night_time_mean_heart_rate_03_05 = (subset.pluck('night_time_mean_heart_rate_(03-05)').sum / subset.count).round(2)
      night_time_mean_heart_rate_05_07 = (subset.pluck('night_time_mean_heart_rate_(05-07)').sum / subset.count).round(2)

      night_time_room_mean_temperature_23_01 = (subset.pluck('night_time_room_mean_temperature_(23-01)').sum / subset.count).round(2)
      night_time_room_mean_temperature_01_03 = (subset.pluck('night_time_room_mean_temperature_(01-03)').sum / subset.count).round(2)
      night_time_room_mean_temperature_03_05 = (subset.pluck('night_time_room_mean_temperature_(03-05)').sum / subset.count).round(2)
      night_time_room_mean_temperature_05_07 = (subset.pluck('night_time_room_mean_temperature_(05-07)').sum / subset.count).round(2)

      night_time_room_mean_humidity_23_01 = (subset.pluck('night_time_room_mean_humidity_(23-01)').sum / subset.count).round(2)
      night_time_room_mean_humidity_01_03 = (subset.pluck('night_time_room_mean_humidity_(01-03)').sum / subset.count).round(2)
      night_time_room_mean_humidity_03_05 = (subset.pluck('night_time_room_mean_humidity_(03-05)').sum / subset.count).round(2)
      night_time_room_mean_humidity_05_07 = (subset.pluck('night_time_room_mean_humidity_(05-07)').sum / subset.count).round(2)

      night_time_room_mean_co2_level_23_01 = (subset.pluck('night_time_room_mean_co2_level_(23-01)').sum / subset.count).round(2)
      night_time_room_mean_co2_level_01_03 = (subset.pluck('night_time_room_mean_co2_level_(01-03)').sum / subset.count).round(2)
      night_time_room_mean_co2_level_03_05 = (subset.pluck('night_time_room_mean_co2_level_(03-05)').sum / subset.count).round(2)
      night_time_room_mean_co2_level_05_07 = (subset.pluck('night_time_room_mean_co2_level_(05-07)').sum / subset.count).round(2)

      day_time_mean_heart_rate_07_11 = (subset.pluck('day_time_mean_heart_rate_(07-11)').sum / subset.count).round(2)
      day_time_mean_heart_rate_11_15 = (subset.pluck('day_time_mean_heart_rate_(11-15)').sum / subset.count).round(2)
      day_time_mean_heart_rate_15_19 = (subset.pluck('day_time_mean_heart_rate_(15-19)').sum / subset.count).round(2)
      day_time_mean_heart_rate_19_23 = (subset.pluck('day_time_mean_heart_rate_(19-23)').sum / subset.count).round(2)

      day_time_mean_stress_level_07_11 = (subset.pluck('day_time_mean_stress_level_(07-11)').sum / subset.count).round(2)
      day_time_mean_stress_level_11_15 = (subset.pluck('day_time_mean_stress_level_(11-15)').sum / subset.count).round(2)
      day_time_mean_stress_level_15_19 = (subset.pluck('day_time_mean_stress_level_(15-19)').sum / subset.count).round(2)
      day_time_mean_stress_level_19_23 = (subset.pluck('day_time_mean_stress_level_(19-23)').sum / subset.count).round(2)

      sleep_session['night_time_mean_heart_rate_(23-01)'] = night_time_mean_heart_rate_23_01 if sleep_session['night_time_mean_heart_rate_(23-01)'].zero?
      sleep_session['night_time_mean_heart_rate_(01-03)'] = night_time_mean_heart_rate_01_03 if sleep_session['night_time_mean_heart_rate_(01-03)'].zero?
      sleep_session['night_time_mean_heart_rate_(03-05)'] = night_time_mean_heart_rate_03_05 if sleep_session['night_time_mean_heart_rate_(03-05)'].zero?
      sleep_session['night_time_mean_heart_rate_(05-07)'] = night_time_mean_heart_rate_05_07 if sleep_session['night_time_mean_heart_rate_(05-07)'].zero?

      sleep_session['night_time_room_mean_temperature_(23-01)'] = night_time_room_mean_temperature_23_01 if sleep_session['night_time_room_mean_temperature_(23-01)'].zero?
      sleep_session['night_time_room_mean_temperature_(01-03)'] = night_time_room_mean_temperature_01_03 if sleep_session['night_time_room_mean_temperature_(01-03)'].zero?
      sleep_session['night_time_room_mean_temperature_(03-05)'] = night_time_room_mean_temperature_03_05 if sleep_session['night_time_room_mean_temperature_(03-05)'].zero?
      sleep_session['night_time_room_mean_temperature_(05-07)'] = night_time_room_mean_temperature_05_07 if sleep_session['night_time_room_mean_temperature_(05-07)'].zero?

      sleep_session['night_time_room_mean_humidity_(23-01)'] = night_time_room_mean_humidity_23_01 if sleep_session['night_time_room_mean_humidity_(23-01)'].zero?
      sleep_session['night_time_room_mean_humidity_(01-03)'] = night_time_room_mean_humidity_01_03 if sleep_session['night_time_room_mean_humidity_(01-03)'].zero?
      sleep_session['night_time_room_mean_humidity_(03-05)'] = night_time_room_mean_humidity_03_05 if sleep_session['night_time_room_mean_humidity_(03-05)'].zero?
      sleep_session['night_time_room_mean_humidity_(05-07)'] = night_time_room_mean_humidity_05_07 if sleep_session['night_time_room_mean_humidity_(05-07)'].zero?

      sleep_session['night_time_room_mean_co2_level_(23-01)'] = night_time_room_mean_co2_level_23_01 if sleep_session['night_time_room_mean_co2_level_(23-01)'].zero?
      sleep_session['night_time_room_mean_co2_level_(01-03)'] = night_time_room_mean_co2_level_01_03 if sleep_session['night_time_room_mean_co2_level_(01-03)'].zero?
      sleep_session['night_time_room_mean_co2_level_(03-05)'] = night_time_room_mean_co2_level_03_05 if sleep_session['night_time_room_mean_co2_level_(03-05)'].zero?
      sleep_session['night_time_room_mean_co2_level_(05-07)'] = night_time_room_mean_co2_level_05_07 if sleep_session['night_time_room_mean_co2_level_(05-07)'].zero?

      sleep_session['day_time_mean_heart_rate_(07-11)'] = day_time_mean_heart_rate_07_11 if sleep_session['day_time_mean_heart_rate_(07-11)'].zero?
      sleep_session['day_time_mean_heart_rate_(11-15)'] = day_time_mean_heart_rate_11_15 if sleep_session['day_time_mean_heart_rate_(11-15)'].zero?
      sleep_session['day_time_mean_heart_rate_(15-19)'] = day_time_mean_heart_rate_15_19 if sleep_session['day_time_mean_heart_rate_(15-19)'].zero?
      sleep_session['day_time_mean_heart_rate_(19-23)'] = day_time_mean_heart_rate_19_23 if sleep_session['day_time_mean_heart_rate_(19-23)'].zero?

      sleep_session['day_time_mean_stress_level_(07-11)'] = day_time_mean_stress_level_07_11 if sleep_session['day_time_mean_stress_level_(07-11)'].zero?
      sleep_session['day_time_mean_stress_level_(11-15)'] = day_time_mean_stress_level_11_15 if sleep_session['day_time_mean_stress_level_(11-15)'].zero?
      sleep_session['day_time_mean_stress_level_(15-19)'] = day_time_mean_stress_level_15_19 if sleep_session['day_time_mean_stress_level_(15-19)'].zero?
      sleep_session['day_time_mean_stress_level_(19-23)'] = day_time_mean_stress_level_19_23 if sleep_session['day_time_mean_stress_level_(19-23)'].zero?
    end
  end
end
