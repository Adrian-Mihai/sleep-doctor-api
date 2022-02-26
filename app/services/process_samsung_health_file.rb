class ProcessSamsungHealthFile
  def initialize(uuid:)
    @samsung_health_file = SamsungHealthFile.find_by(uuid: uuid)
  end

  def perform
    @samsung_health_file.update!(status: PersonalFile::PROCESSING)

    create_sleep_sessions

    self
  end

  private

  def create_sleep_sessions
    user.sleep_sessions.create(Extract::Sleep.new(uuid: @samsung_health_file.uuid).perform)
  end

  def user
    return @user if defined? @user

    @user = @samsung_health_file.user
  end
end
