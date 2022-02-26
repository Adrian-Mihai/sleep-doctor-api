class ProcessSamsungHealthFile
  def initialize(uuid:)
    @samsung_health_file = SamsungHealthFile.find_by(uuid: uuid)
  end

  def perform
    @samsung_health_file.update!(status: PersonalFile::PROCESSING)

    user.sleep_sessions.create(Extract::Sleep.new(uuid: @samsung_health_file.uuid).perform)
    user.heart_rate_values.create(Extract::HeartRate.new(uuid: @samsung_health_file.uuid).perform)
    user.stress_values.create(Extract::Stress.new(uuid: @samsung_health_file.uuid).perform)

    self
  end

  private

  def user
    return @user if defined? @user

    @user = @samsung_health_file.user
  end
end
