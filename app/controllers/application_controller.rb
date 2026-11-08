class ApplicationController < ActionController::API
  include Pundit::Authorization
  before_action :authenticate_user!
  before_action :set_tenant

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

  def authenticate_user!
    token = request.headers['Authorization']&.split(' ')&.last
    return render json: { error: 'Missing token' }, status: :unauthorized unless token

    decoded = JsonWebToken.decode(token)
    return render json: { error: 'Invalid token' }, status: :unauthorized unless decoded

    @current_user = User.find_by(id: decoded[:user_id], jti: decoded[:jti])
    render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_user
  end

  def current_user
    @current_user
  end

  def set_tenant
    ActsAsTenant.current_tenant = current_user&.tenant
  end

  def audit_action(action, record, changes: {})
    AuditLog.record(
      user: current_user,
      action: action,
      record: record,
      changes: changes,
      ip: request.remote_ip
    )
  end

  def user_not_authorized
    render json: { error: 'You are not authorized to perform this action' }, status: :forbidden
  end

  def record_not_found
    render json: { error: 'Record not found' }, status: :not_found
  end
end
