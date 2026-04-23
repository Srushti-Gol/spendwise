module Api
  module V1
    class GoodsReceiptsController < ApplicationController
      before_action :set_receipt, only: [:show, :destroy]

      def index
        receipts = GoodsReceipt.where(tenant: current_user.tenant)
                               .includes(:purchase_order, :received_by, :goods_receipt_items)
                               .order(received_at: :desc)
                               .page(params[:page]).per(25)
        render json: { goods_receipts: receipts.map { |r| receipt_json(r) } }
      end

      def show
        render json: receipt_json(@receipt, detail: true)
      end

      def create
        @receipt = GoodsReceipt.new(receipt_params.merge(received_by: current_user, tenant: current_user.tenant))
        if @receipt.save
          audit_action('create', @receipt)
          render json: receipt_json(@receipt), status: :created
        else
          render json: { errors: @receipt.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @receipt.destroy
        head :no_content
      end

      private

      def set_receipt
        @receipt = GoodsReceipt.find(params[:id])
      end

      def receipt_params
        params.require(:goods_receipt).permit(
          :purchase_order_id, :received_at, :notes, :delivery_reference,
          goods_receipt_items_attributes: [:id, :purchase_order_item_id, :quantity_received, :condition, :notes, :_destroy]
        )
      end

      def receipt_json(r, detail: false)
        json = {
          id: r.id, purchase_order_id: r.purchase_order_id,
          received_at: r.received_at, notes: r.notes,
          received_by: { id: r.received_by_id, name: r.received_by&.name },
          created_at: r.created_at
        }
        if detail
          json[:items] = r.goods_receipt_items.map { |i| { id: i.id, purchase_order_item_id: i.purchase_order_item_id, quantity_received: i.quantity_received, condition: i.condition } }
        end
        json
      end
    end
  end
end
