module Api
  module V1
    class AuditLogsController < ApplicationController
      def index
        logs = AuditLog.where(tenant: current_user.tenant)
                       .includes(:user)
                       .recent
        logs = logs.where(auditable_type: params[:resource]) if params[:resource].present?
        logs = logs.where(user_id: params[:user_id]) if params[:user_id].present?
        logs = logs.where(action: params[:action_filter]) if params[:action_filter].present?
        paginated = logs.page(params[:page]).per(25)
        render json: {
          audit_logs: paginated.map { |l| log_json(l) },
          meta: { total: paginated.total_count, page: paginated.current_page, pages: paginated.total_pages }
        }
      end

      def show
        log = AuditLog.find(params[:id])
        render json: log_json(log)
      end

      private

      def log_json(l)
        {
          id: l.id, action: l.action,
          user: { id: l.user_id, name: l.user&.name },
          auditable_type: l.auditable_type, auditable_id: l.auditable_id,
          changes_data: l.changes_data, ip_address: l.ip_address,
          created_at: l.created_at
        }
      end
    end
  end
end
