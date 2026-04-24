module Api
  module V1
    class PurchaseOrdersController < ApplicationController
      before_action :set_po, only: %i[show update destroy send_to_vendor]

      def index
        pos = policy_scope(PurchaseOrder).includes(:requisition, :purchase_order_items)
                                         .order(created_at: :desc)
                                         .page(params[:page]).per(25)
        render json: { purchase_orders: pos.map { |p| po_json(p) }, meta: pagination_meta(pos) }
      end

      def show
        authorize @po
        render json: po_json(@po, detailed: true)
      end

      def create
        po = PurchaseOrder.new(po_params.merge(created_by: current_user))
        authorize po
        if po.save
          audit('create', po)
          render json: po_json(po), status: :created
        else
          render json: { errors: po.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        authorize @po
        if @po.update(po_params)
          audit('update', @po)
          render json: po_json(@po)
        else
          render json: { errors: @po.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @po
        @po.destroy
        head :no_content
      end

      def send_to_vendor
        authorize @po, :update?
        @po.send_to_vendor!
        audit('send_to_vendor', @po)
        render json: po_json(@po)
      end

      private

      def set_po
        @po = PurchaseOrder.find(params[:id])
      end

      def po_params
        params.require(:purchase_order).permit(
          :vendor, :vendor_email, :total_amount, :expected_delivery_date,
          :notes, :price_tolerance, :quantity_tolerance, :requisition_id,
          purchase_order_items_attributes: %i[id description quantity unit_price total_price unit _destroy]
        )
      end

      def po_json(po, detailed: false)
        json = {
          id: po.id, vendor: po.vendor, total_amount: po.total_amount,
          status: po.status, price_tolerance: po.price_tolerance,
          quantity_tolerance: po.quantity_tolerance,
          created_at: po.created_at
        }
        if detailed
          json.merge!(
            items: po.purchase_order_items.map { |i| { id: i.id, description: i.description, quantity: i.quantity, received_quantity: i.received_quantity, unit_price: i.unit_price } },
            receipts_count: po.goods_receipts.count,
            invoices_count: po.invoices.count
          )
        end
        json
      end

      def pagination_meta(c)
        { current_page: c.current_page, total_pages: c.total_pages, total_count: c.total_count }
      end
    end
  end
end
