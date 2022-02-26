module Api
  module V1
    class SamsungHealthController < ApplicationController
      def create
        user = User.find_by!(uuid: params[:user_id])
        samsung_health_file = user.samsung_health_files.create!(uuid: SecureRandom.uuid)
        samsung_health_file.zip_file.attach(params[:file])
        render json: { uuid: samsung_health_file.uuid }, status: :created
      end
    end
  end
end
