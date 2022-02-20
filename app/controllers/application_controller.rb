class ApplicationController < ActionController::API
  def version
    version = File.read('VERSION').strip
    render json: { version: version }, status: :ok
  end
end
