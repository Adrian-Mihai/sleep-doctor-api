module Api
  module V1
    class UsersController < ApplicationController
      def create
        user = User.create!(sanitize_params.merge(uuid: SecureRandom.uuid))
        render json: { uuid: user.uuid, email: user.email }, status: :created
      end

      private

      def sanitize_params
        params.require(:user).permit(:email, :age, :password, :password_confirmation, :terms_and_conditions)
      end
    end
  end
end
