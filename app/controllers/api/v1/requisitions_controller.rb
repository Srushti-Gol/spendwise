module Api
  module V1
    class RequisitionsController < ApplicationController
      before_action :set_requisition, only: [:show, :update, :destroy, :submit, :approve, :reject, :cancel]

      def index
        requisitions = policy_scope(Requisition).includes(:requester, :current_approver, :requisition_items)
                                               .order(created_at: :desc)
                                               .page(params[:page]).per(25)
        render json: {
          requisitions: requisitions.map { |r| requisition_json(r) },
          meta: { total: requisitions.total_count, page: requisitions.current_page, pages: requisitions.total_pages }
        }
      end

      def show
        authorize @requisition
        render json: requisition_json(@requisition, detail: true)
      end

      def create
        @requisition = Requisition.new(requisition_params.merge(requester: current_user, tenant: current_user.tenant))
        authorize @requisition
        if @requisition.save
          audit_action('create', @requisition)
          render json: requisition_json(@requisition), status: :created
        else
          render json: { errors: @requisition.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        authorize @requisition
        if @requisition.update(requisition_params)
          audit_action('update', @requisition, changes: @requisition.saved_changes)
          render json: requisition_json(@requisition)
        else
          render json: { errors: @requisition.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @requisition
        @requisition.destroy
        audit_action('delete', @requisition)
        head :no_content
      end

      def submit
        authorize @requisition, :submit?
        service = ApprovalChainService.new(@requisition)
        service.build_chain!
        @requisition.submit!
        audit_action('submit', @requisition)
        render json: requisition_json(@requisition)
      rescue => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def approve
        authorize @requisition, :approve?
        service = ApprovalChainService.new(@requisition)
        service.advance!(approved_by: current_user, comment: params[:comment])
        audit_action('approve', @requisition, changes: { comment: params[:comment] })
        render json: requisition_json(@requisition)
      rescue => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def reject
        authorize @requisition, :reject?
        service = ApprovalChainService.new(@requisition)
        service.reject!(rejected_by: current_user, comment: params[:comment])
        audit_action('reject', @requisition, changes: { comment: params[:comment] })
        render json: requisition_json(@requisition)
      rescue => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def cancel
        authorize @requisition, :cancel?
        @requisition.cancel!
        audit_action('cancel', @requisition)
        render json: requisition_json(@requisition)
      end

      private

      def set_requisition
        @requisition = Requisition.find(params[:id])
      end

      def requisition_params
        params.require(:requisition).permit(
          :title, :description, :department, :total_amount, :self_approval_blocked,
          requisition_items_attributes: [:id, :description, :quantity, :unit_price, :total_price, :unit, :_destroy]
        )
      end

      def requisition_json(r, detail: false)
        json = {
          id: r.id, title: r.title, department: r.department,
          total_amount: r.total_amount, status: r.status,
          created_at: r.created_at,
          requester: { id: r.requester_id, name: r.requester&.name },
          current_approver: r.current_approver ? { id: r.current_approver_id, name: r.current_approver&.name } : nil
        }
        if detail
          json[:items] = r.requisition_items.map { |i| { id: i.id, description: i.description, quantity: i.quantity, unit_price: i.unit_price, total_price: i.total_price } }
          json[:approval_steps] = r.approval_steps.order(:level).map { |s| { level: s.level, approver: s.approver&.name, status: s.status, comment: s.comment, decided_at: s.decided_at } }
        end
        json
      end
    end
  end
end
