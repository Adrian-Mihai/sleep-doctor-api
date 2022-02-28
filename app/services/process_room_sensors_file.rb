class ProcessRoomSensorsFile
  def initialize(uuid:)
    @room_sensors_file = RoomSensorsFile.find_by(uuid: uuid)
  end

  def perform
    @room_sensors_file.update!(status: PersonalFile::PROCESSING)

    user.temperature_values.create(Extract::RoomSensors::Temperature.new(uuid: @room_sensors_file.uuid).perform)
    user.humidity_values.create(Extract::RoomSensors::Humidity.new(uuid: @room_sensors_file.uuid).perform)
    user.co2_values.create(Extract::RoomSensors::Co2.new(uuid: @room_sensors_file.uuid).perform)

    @room_sensors_file.update!(status: PersonalFile::PROCESSED)

    self
  end

  private

  def user
    return @user if defined? @user

    @user = @room_sensors_file.user
  end
end
