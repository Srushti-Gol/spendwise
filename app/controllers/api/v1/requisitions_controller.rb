module Api
  module V1
    class RequisitionsController < ApplicationController
      before_action :set_requisition, only: %i[show update destroy submit approve reject cancel]

      def index
        requisitions = policy_scope(Requisition).includes(:requester, :current_approver, :requisition_items)
                                                .order(created_at: :desc)
                                                .page(params[:page]).per(params[:per_page] || 25)
        render json: {
          requisitions: requisitions.map { |r| requisition_json(r) },
          meta: pagination_meta(requisitions)
        }
      end

      def show
        authorize @requisition
        render json: requisition_json(@requisition, detailed: true)
      end

      def create
        requisition = Requisition.new(requisition_params.merge(requester: current_user))
        authorize requisition

        if requisition.save
          audit("create", requisition)
          render json: requisition_json(requisition), status: :created
        else
          render json: { errors: requisition.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        authorize @requisition
        if @requisition.update(requisition_params)
          audit("update", @requisition)
          render json: requisition_json(@requisition)
        else
          render json: { errors: @requisition.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @requisition
        @requisition.destroy
        audit("delete", @requisition)
        head :no_content
      end

      def submit
        authorize @requisition, :submit?
        ApprovalChainService.new(@requisition).build_chain!
        @requisition.submit!
        audit("submit", @requisition, { status: "pending" })
        render json: requisition_json(@requisition)
      rescue => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def approve
        authorize @requisition, :approve?
        ApprovalChainService.new(@requisition).advance!(
          approved_by: current_user,
          comment: params[:comment]
        )
        audit("approve", @requisition, { comment: params[:comment] })
        render json: requisition_json(@requisition)
      rescue => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def reject
        authorize @requisition, :reject?
        ApprovalChainService.new(@requisition).reject!(
          rejected_by: current_user,
          comment: params[:comment]
        )
        audit("reject", @requisition, { comment: params[:comment] })
        render json: requisition_json(@requisition)
      rescue => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def cancel
        authorize @requisition, :cancel?
        @requisition.cancel!
        audit("cancel", @requisition)
        render json: requisition_json(@requisition)
      end

      private

      def set_requisition
        @requisition = Requisition.find(params[:id])
      end

      def requisition_params
        params.require(:requisition).permit(
          :title, :description, :department, :total_amount,
          requisition_items_attributes: %i[id description quantity unit_price total_price unit _destroy]
        )
      end

      def requisition_json(r, detailed: false)
        json = {
          id: r.id, title: r.title, department: r.department,
          total_amount: r.total_amount, status: r.status,
          requester: { id: r.requester_id, name: r.requester&.name },
          current_approver: r.current_approver ? { id: r.current_approver_id, name: r.current_approver&.name } : nil,
          created_at: r.created_at, updated_at: r.updated_at
        }
        if detailed
          json.merge!(
            description: r.description,
            items: r.requisition_items.map { |i| { id: i.id, description: i.description, quantity: i.quantity, unit_price: i.unit_price, total_price: i.total_price } },
            approval_steps: r.approval_steps.order(:level).map { |s| { level: s.level, approver: s.approver&.name, status: s.status, comment: s.comment, decided_at: s.decided_at } }
          )
        end
        json
      end

      def pagination_meta(collection)
        { current_page: collection.current_page, total_pages: collection.total_pages, total_count: collection.total_count }
      end
    end
  end
end
