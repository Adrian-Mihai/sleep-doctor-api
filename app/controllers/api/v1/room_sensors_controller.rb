module Api
  module V1
    class RoomSensorsController < ApplicationController
      def create
        user = User.find_by!(uuid: params[:user_id])
        room_sensors_file = user.room_sensors_files.create!(uuid: SecureRandom.uuid, zip_file: params[:file])
        DelayedServiceCaller.perform_later(ProcessRoomSensorsFile.name, { uuid: room_sensors_file.uuid })
        render json: { uuid: room_sensors_file.uuid, status: room_sensors_file.status }, status: :created
      end
    end
  end
end
