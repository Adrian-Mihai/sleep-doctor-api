class GenerateSleepSessionsDataset
  def initialize(user_uuid:)
    @errors = []
    @user = User.find_by!(uuid: user_uuid)
  rescue ActiveRecord::RecordNotFound => e
    @errors << "#{e.model} not found"
  end

  def sleep_sessions_dataset
    return @sleep_sessions_dataset if defined? @sleep_sessions_dataset

    @sleep_sessions_dataset = []
    @user.sleep_sessions.includes(:sleep_stages).order(:start_time).find_in_batches do |sleep_sessions|
      sleep_sessions.each_with_index do |sleep_session, index|
        next if index.zero?

        temperature = calculate_mean_value(room_temperature_dataset, sleep_session.start_time, sleep_session.end_time)
        humidity = calculate_mean_value(room_humidity_dataset, sleep_session.start_time, sleep_session.end_time)
        co2_level = calculate_mean_value(room_co2_level_dataset, sleep_session.start_time, sleep_session.end_time)
        heart_rate = calculate_mean_value(heart_rate_dataset, sleep_session.start_time, sleep_session.end_time)
        stress_level = calculate_mean_value(stress_level_dataset, sleep_sessions[index - 1].end_time, sleep_session.start_time)
        exercises = calculate_daily_exercises(sleep_sessions[index - 1].end_time, sleep_session.start_time)
        next if temperature.nil? || humidity.nil? || co2_level.nil? || heart_rate.nil? || stress_level.nil?

        @sleep_sessions_dataset << {
          start_time: sleep_session.start_time.localtime.strftime('%F %T %z'),
          mental_recovery: sleep_session.mental_recovery,
          physical_recovery: sleep_session.physical_recovery,
          awake_stage_duration: calculate_sleep_stage_duration(sleep_session, awake_stage),
          light_sleep_stage_duration: calculate_sleep_stage_duration(sleep_session, light_sleep_stage),
          deep_sleep_stage_duration: calculate_sleep_stage_duration(sleep_session, deep_sleep_stage),
          rem_stage_duration: calculate_sleep_stage_duration(sleep_session, rem_stage),
          cycle: sleep_session.cycle,
          sleep_session_duration: sleep_session.duration,
          room_mean_temperature: temperature,
          room_mean_humidity: humidity,
          room_mean_co2_level: co2_level,
          sleep_session_mean_heart_rate: heart_rate,
          day_time_mean_stress_level: stress_level,
          exercise_sessions_burned_calories: exercises[:burned_calories],
          exercise_sessions_duration: exercises[:duration],
          score: sleep_session.score,
          end_time: sleep_session.end_time.localtime.strftime('%F %T %z')
        }
      end
    end

    @sleep_sessions_dataset
  end

  def valid?
    @errors.empty?
  end

  private

  def calculate_mean_value(dataset, start_time, end_time)
    subset = dataset.find_all { |record| (start_time..end_time).cover?(record[:start_time]) }
    return if subset.empty?

    total = subset.sum { |record| record[:mean] }
    (total / subset.count).round(2)
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
end
