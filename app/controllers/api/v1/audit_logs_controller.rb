module Api
  module V1
    class AuditLogsController < ApplicationController
      def index
        authorize AuditLog
        logs = policy_scope(AuditLog).includes(:user)
                                      .order(created_at: :desc)
                                      .page(params[:page]).per(params[:per_page] || 50)
        logs = logs.where(auditable_type: params[:resource_type]) if params[:resource_type].present?
        logs = logs.where(user_id: params[:user_id]) if params[:user_id].present?
        render json: {
          audit_logs: logs.map { |l| log_json(l) },
          meta: { current_page: logs.current_page, total_pages: logs.total_pages, total_count: logs.total_count }
        }
      end

      def show
        log = AuditLog.find(params[:id])
        authorize log
        render json: log_json(log, detailed: true)
      end

      private

      def log_json(l, detailed: false)
        json = {
          id: l.id, action: l.action,
          auditable_type: l.auditable_type, auditable_id: l.auditable_id,
          user: { id: l.user_id, name: l.user&.name },
          ip_address: l.ip_address, created_at: l.created_at
        }
        json[:changes_data] = l.changes_data if detailed
        json[:metadata] = l.metadata if detailed
        json
      end
    end
  end
end
