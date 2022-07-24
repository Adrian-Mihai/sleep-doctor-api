class GenerateSleepSessionsDataset
  attr_reader :errors

  SLEEP_SESSION_COLUMNS = %i[id start_time mental_recovery physical_recovery
                             cycle movement_duration duration score end_time]
  SENSORS_READINGS_COLUMNS = %i[id start_time mean end_time]

  BATCH_SIZE = 1000

  def initialize(user_uuid:)
    @errors = []
    @user = User.find_by!(uuid: user_uuid)
  rescue ActiveRecord::RecordNotFound => e
    @errors << "#{e.model} not found"
  end

  def sleep_sessions_dataset
    return @sleep_sessions_dataset if defined? @sleep_sessions_dataset

    @sleep_sessions_dataset = []
    sleep_sessions.find_in_batches(batch_size: BATCH_SIZE) do |sleep_sessions|
      sleep_sessions.each_with_index do |sleep_session, index|
        next if index.zero?

        day_time_heart_rate = calculate_mean_values(heart_rate_dataset, sleep_sessions[index - 1].end_time, sleep_session.start_time, :day_time)
        day_time_stress_level = calculate_mean_values(stress_level_dataset, sleep_sessions[index - 1].end_time, sleep_session.start_time, :day_time)
        exercises = calculate_daily_exercises(sleep_sessions[index - 1].end_time, sleep_session.start_time)

        night_time_heart_rate = calculate_mean_values(heart_rate_dataset, sleep_session.start_time, sleep_session.end_time, :night_time)
        temperature_readings = calculate_mean_values(room_temperature_dataset, sleep_session.start_time, sleep_session.end_time, :night_time)
        humidity_readings = calculate_mean_values(room_humidity_dataset, sleep_session.start_time, sleep_session.end_time, :night_time)
        co2_level_readings = calculate_mean_values(room_co2_level_dataset, sleep_session.start_time, sleep_session.end_time, :night_time)

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
        payload.merge!(day_time_heart_rate.transform_keys { |k| "day_time_(#{k})_average_heart_rate" })
        payload.merge!(day_time_stress_level.transform_keys { |k| "day_time_(#{k})_average_stress_level" })
        payload[:exercise_sessions_burned_calories] = exercises[:burned_calories]
        payload[:exercise_sessions_duration] = exercises[:duration]
        payload.merge!(night_time_heart_rate.transform_keys { |k| "night_time_(#{k})_average_heart_rate" })
        payload.merge!(temperature_readings.transform_keys { |k| "night_time_(#{k})_average_room_temperature" })
        payload.merge!(humidity_readings.transform_keys { |k| "night_time_(#{k})_average_room_humidity" })
        payload.merge!(co2_level_readings.transform_keys { |k| "night_time_(#{k})_average_room_co2_level" })
        payload[:score] = sleep_session.score
        payload[:end_time] = sleep_session.end_time.localtime.strftime('%F %T %z')

        @sleep_sessions_dataset << payload.stringify_keys
      end
    end
    @sleep_sessions_dataset
  end

  def valid?
    @errors.empty?
  end

  private

  def sleep_sessions
    @user.sleep_sessions.select(SLEEP_SESSION_COLUMNS).includes(:sleep_stages)
  end

  def heart_rate_dataset
    return @heart_rate_dataset if defined? @heart_rate_dataset

    @heart_rate_dataset = []
    @user.heart_rate_values
         .select(SENSORS_READINGS_COLUMNS)
         .find_in_batches(batch_size: BATCH_SIZE) { |heart_rate_readings| @heart_rate_dataset += heart_rate_readings }
    @heart_rate_dataset
  end

  def stress_level_dataset
    return @stress_level_dataset if defined? @stress_level_dataset

    @stress_level_dataset = []
    @user.stress_values
         .select(SENSORS_READINGS_COLUMNS)
         .find_in_batches(batch_size: BATCH_SIZE) { |stress_level_readings| @stress_level_dataset += stress_level_readings }
    @stress_level_dataset
  end

  def exercises_dataset
    return @exercises_dataset if defined? @exercises_dataset

    @exercises_dataset = []
    @user.exercises
         .select(:id, :start_time, :burned_calorie, :duration, :end_time)
         .find_in_batches(batch_size: BATCH_SIZE) { |exercises| @exercises_dataset += exercises }
    @exercises_dataset
  end

  def room_temperature_dataset
    return @room_temperature_dataset if defined? @room_temperature_dataset

    @room_temperature_dataset = []
    @user.temperature_values
         .select(SENSORS_READINGS_COLUMNS)
         .find_in_batches(batch_size: BATCH_SIZE) { |temperature_readings| @room_temperature_dataset += temperature_readings }
    @room_temperature_dataset
  end

  def room_humidity_dataset
    return @room_humidity_dataset if defined? @room_humidity_dataset

    @room_humidity_dataset = []
    @user.humidity_values
         .select(SENSORS_READINGS_COLUMNS)
         .find_in_batches(batch_size: BATCH_SIZE) { |humidity_readings| @room_humidity_dataset += humidity_readings }
    @room_humidity_dataset
  end

  def room_co2_level_dataset
    return @room_co2_level_dataset if defined? @room_co2_level_dataset

    @room_co2_level_dataset = []
    @user.co2_values
         .select(SENSORS_READINGS_COLUMNS)
         .find_in_batches(batch_size: BATCH_SIZE) { |co2_readings| @room_co2_level_dataset += co2_readings }
    @room_co2_level_dataset
  end

  def calculate_mean_values(dataset, start_time, end_time, time)
    subset = dataset.find_all { |record| (start_time..end_time).cover?(record.start_time) }

    periods = time == :day_time ? split_day_time_in_periods(start_time) : split_night_time_in_periods(end_time)
    periods.map do |period|
      period_values = subset.find_all { |record| (period.first..period.last).cover?(record.start_time) }

      ["#{period.first.strftime('%H')}-#{(period.last + 1).strftime('%H')}", calculate_mean_value(period_values)]
    end.compact.to_h
  end

  def split_day_time_in_periods(start_time)
    start_period = start_time.at_beginning_of_day + 7.hours
    periods = []
    8.times do
      end_period = start_period + 2.hours
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

  def calculate_mean_value(values)
    return if values.count.zero?

    (values.sum(&:mean) / values.count).round(2)
  end

  def calculate_daily_exercises(start_time, end_time)
    exercises = exercises_dataset.find_all { |record| (start_time..end_time).cover?(record.start_time) }
    burned_calories = exercises.sum(&:burned_calorie)
    duration = exercises.sum(&:duration)

    { burned_calories: burned_calories, duration: milliseconds_to_minutes(duration) }
  end

  def milliseconds_to_minutes(duration)
    (duration.to_f / 60000).round
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
end
