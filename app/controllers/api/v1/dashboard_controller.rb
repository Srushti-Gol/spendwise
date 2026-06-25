module Api
  module V1
    class DashboardController < ApplicationController
      def stats
        render json: {
          requisitions: requisition_stats,
          purchase_orders: po_stats,
          invoices: invoice_stats,
          spend_by_month: spend_by_month
        }
      end

      private

      def requisition_stats
        reqs = Requisition.where(tenant: current_user.tenant)
        {
          total: reqs.count,
          draft: reqs.where(status: "draft").count,
          pending: reqs.where(status: "pending").count,
          approved: reqs.where(status: "approved").count,
          my_inbox: reqs.where(current_approver: current_user, status: "pending").count
        }
      end

      def po_stats
        pos = PurchaseOrder.where(tenant: current_user.tenant)
        {
          total: pos.count,
          open: pos.where(status: %w[sent partial]).count,
          total_value: pos.sum(:total_amount)
        }
      end

      def invoice_stats
        invs = Invoice.where(tenant: current_user.tenant)
        {
          total: invs.count,
          pending: invs.where(status: "pending").count,
          matched: invs.where(status: "matched").count,
          exceptions: invs.where(status: "exception").count,
          total_value: invs.sum(:total_amount)
        }
      end

      def spend_by_month
        Invoice.where(tenant: current_user.tenant)
               .where("invoice_date >= ?", 6.months.ago)
               .group("DATE_TRUNC('month', invoice_date)")
               .order("DATE_TRUNC('month', invoice_date)")
               .sum(:total_amount)
               .map { |month, total| { month: month, total: total } }
      end
    end
  end
end
