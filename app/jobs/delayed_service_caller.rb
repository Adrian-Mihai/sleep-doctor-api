class DelayedServiceCaller < ApplicationJob
  def perform(service_name, params)
    service = service_name.constantize
    service.new(params).perform
  end
end
