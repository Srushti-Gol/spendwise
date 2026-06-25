class ApplicationController < ActionController::API
  include Pundit::Authorization

  before_action :authenticate_request!
  before_action :set_tenant

  rescue_from Pundit::NotAuthorizedError, with: :not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :bad_request

  attr_reader :current_user

  private

  def authenticate_request!
    token = request.headers["Authorization"]&.split(" ")&.last
    raise Pundit::NotAuthorizedError unless token

    payload = JWT.decode(token, jwt_secret, true, algorithm: "HS256").first
    @current_user = User.find(payload["user_id"])
  rescue JWT::DecodeError, ActiveRecord::RecordNotFound
    render json: { error: "Invalid or expired token" }, status: :unauthorized
  end

  def set_tenant
    ActsAsTenant.current_tenant = current_user&.tenant
  end

  def jwt_secret
    ENV.fetch("JWT_SECRET", "fallback_secret_change_in_production")
  end

  def audit(action, record, changes = {})
    AuditLog.record(
      user: current_user,
      action: action,
      record: record,
      changes: changes,
      ip: request.remote_ip
    )
  end

  def not_authorized
    render json: { error: "You are not authorized to perform this action" }, status: :forbidden
  end

  def not_found
    render json: { error: "Resource not found" }, status: :not_found
  end

  def bad_request(e)
    render json: { error: e.message }, status: :bad_request
  end
end
