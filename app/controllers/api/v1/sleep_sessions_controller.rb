module Api
  module V1
    class SleepSessionsController < ApplicationController
      def index
        service = GenerateSleepSessionsDataset.new(user_uuid: params[:user_id])
        return render json: service.errors, status: :unprocessable_entity unless service.valid?

        render json: service.sleep_sessions_dataset, status: :ok
      end
    end
  end
end
