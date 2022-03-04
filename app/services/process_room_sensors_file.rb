class ProcessRoomSensorsFile
  def initialize(uuid:)
    @room_sensors_file = RoomSensorsFile.find_by(uuid: uuid)
  end

  def perform
    @room_sensors_file.update!(status: PersonalFile::PROCESSING)
    destroy_old_values
    create_new_values
    @room_sensors_file.update!(status: PersonalFile::PROCESSED)

    self
  end

  private

  def user
    return @user if defined? @user

    @user = @room_sensors_file.user
  end

  def destroy_old_values
    user.temperature_values.destroy_all
    user.humidity_values.destroy_all
    user.co2_values.destroy_all
  end

  def create_new_values
    user.temperature_values.create(Extract::RoomSensors::Temperature.new(uuid: @room_sensors_file.uuid).perform)
    user.humidity_values.create(Extract::RoomSensors::Humidity.new(uuid: @room_sensors_file.uuid).perform)
    user.co2_values.create(Extract::RoomSensors::Co2.new(uuid: @room_sensors_file.uuid).perform)
  end
end
