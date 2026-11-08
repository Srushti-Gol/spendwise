module Api
  module V1
    class DashboardController < ApplicationController
      def stats
        tenant = current_user.tenant

        total_spend = Invoice.where(tenant: tenant, status: %w[matched approved paid])
                             .sum(:total_amount)
        pending_approvals = Requisition.where(tenant: tenant, status: 'pending')
                                       .where(current_approver: current_user)
                                       .count
        matched_invoices = Invoice.where(tenant: tenant, status: 'matched').count
        exception_invoices = Invoice.where(tenant: tenant, status: 'exception').count
        open_pos = PurchaseOrder.where(tenant: tenant, status: %w[sent partial]).count

        monthly_spend = Invoice.where(tenant: tenant)
                               .where('created_at >= ?', 6.months.ago)
                               .group("DATE_TRUNC('month', created_at)")
                               .sum(:total_amount)
                               .transform_keys { |k| k.strftime('%Y-%m') }

        render json: {
          total_spend: total_spend,
          pending_approvals: pending_approvals,
          matched_invoices: matched_invoices,
          exception_invoices: exception_invoices,
          open_purchase_orders: open_pos,
          monthly_spend: monthly_spend
        }
      end
    end
  end
end
