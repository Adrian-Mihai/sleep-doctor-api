module Api
  module V1
    class DataController < ApplicationController
      def index
        return render json: {}, status: :bad_request if params[:type].blank?

        relation = "#{params[:type]}_values"
        return render json: {}, status: :bad_request unless user.respond_to?(relation)

        data = if params[:extended] == 'true'
                 payload = user.public_send(relation).order(:start_time).pluck(:payload)
                 payload.flatten!
                 payload.map do |record|
                   record['start_time'] = Time.parse(record['start_time']).localtime.strftime('%F %T %z')
                   record['end_time'] = Time.parse(record['end_time']).localtime.strftime('%F %T %z')
                   record
                 end
               else
                 payload = user.public_send(relation).order(:start_time).pluck(:start_time, :min, :mean, :max, :end_time)
                 payload.map do |start_time, min, mean, max, end_time|
                   {
                     start_time: start_time.localtime.strftime('%F %T %z'),
                     min: min,
                     mean: mean,
                     max: max,
                     end_time: end_time.localtime.strftime('%F %T %z')
                   }
                 end
               end

        render json: data, status: :ok
      end

      private

      def user
        return @user if defined? @user

        @user = User.find_by!(uuid: params[:user_id])
      end
    end
  end
end
