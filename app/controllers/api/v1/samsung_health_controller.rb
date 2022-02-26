module Api
  module V1
    class SamsungHealthController < ApplicationController
      def create
        user = User.find_by!(uuid: params[:user_id])
        samsung_health_file = user.samsung_health_files.create!(uuid: SecureRandom.uuid, zip_file: params[:file])
        DelayedServiceCaller.perform_later(ProcessSamsungHealthFile.name, { uuid: samsung_health_file.uuid })
        render json: { uuid: samsung_health_file.uuid, status: samsung_health_file.status }, status: :created
      end
    end
  end
end
