class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound do |e|
    render json: { error: e.message }, status: :not_found
  end

  rescue_from ActiveRecord::RecordInvalid do |e|
    render json: { error: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  rescue_from CustomerService::NotFound do |e|
    render json: { error: e.message }, status: :unprocessable_entity
  end

  rescue_from CustomerService::Unavailable do |e|
    render json: { error: e.message }, status: :service_unavailable
  end

  rescue_from Orders::Publishers::PublishFailed do |e|
    render json: { error: e.message }, status: :service_unavailable
  end
end
