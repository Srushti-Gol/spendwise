module Api
  module V1
    class GoodsReceiptsController < ApplicationController
      def index
        receipts = policy_scope(GoodsReceipt).includes(:purchase_order, :received_by)
                                              .order(created_at: :desc).page(params[:page]).per(25)
        render json: { goods_receipts: receipts.map { |r| receipt_json(r) } }
      end

      def show
        receipt = GoodsReceipt.find(params[:id])
        authorize receipt
        render json: receipt_json(receipt, detailed: true)
      end

      def create
        receipt = GoodsReceipt.new(receipt_params.merge(received_by: current_user))
        authorize receipt
        if receipt.save
          audit('create', receipt)
          render json: receipt_json(receipt), status: :created
        else
          render json: { errors: receipt.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def receipt_params
        params.require(:goods_receipt).permit(
          :purchase_order_id, :received_at, :notes, :delivery_reference,
          goods_receipt_items_attributes: %i[id purchase_order_item_id quantity_received condition notes _destroy]
        )
      end

      def receipt_json(r, detailed: false)
        { id: r.id, purchase_order_id: r.purchase_order_id, received_at: r.received_at,
          received_by: r.received_by&.name, delivery_reference: r.delivery_reference,
          created_at: r.created_at }
      end
    end
  end
end
