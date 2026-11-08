module Api
  module V1
    class PurchaseOrdersController < ApplicationController
      before_action :set_po, only: [:show, :update, :destroy, :send_to_vendor]

      def index
        pos = policy_scope(PurchaseOrder).includes(:requisition, :purchase_order_items)
                                         .order(created_at: :desc)
                                         .page(params[:page]).per(25)
        render json: { purchase_orders: pos.map { |po| po_json(po) }, meta: pagination_meta(pos) }
      end

      def show
        authorize @po
        render json: po_json(@po, detail: true)
      end

      def create
        @po = PurchaseOrder.new(po_params.merge(created_by: current_user, tenant: current_user.tenant))
        authorize @po
        if @po.save
          audit_action('create', @po)
          render json: po_json(@po), status: :created
        else
          render json: { errors: @po.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        authorize @po
        if @po.update(po_params)
          audit_action('update', @po, changes: @po.saved_changes)
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
        authorize @po, :send_to_vendor?
        @po.send_to_vendor!
        audit_action('send_to_vendor', @po)
        render json: po_json(@po)
      end

      private

      def set_po
        @po = PurchaseOrder.find(params[:id])
      end

      def po_params
        params.require(:purchase_order).permit(
          :vendor, :vendor_email, :total_amount, :expected_delivery_date, :notes,
          :price_tolerance, :quantity_tolerance, :requisition_id,
          purchase_order_items_attributes: [:id, :description, :quantity, :unit_price, :total_price, :unit, :_destroy]
        )
      end

      def po_json(po, detail: false)
        json = {
          id: po.id, vendor: po.vendor, total_amount: po.total_amount,
          status: po.status, created_at: po.created_at,
          price_tolerance: po.price_tolerance, quantity_tolerance: po.quantity_tolerance
        }
        if detail
          json[:items] = po.purchase_order_items.map { |i| { id: i.id, description: i.description, quantity: i.quantity, unit_price: i.unit_price, received_quantity: i.received_quantity } }
        end
        json
      end

      def pagination_meta(collection)
        { total: collection.total_count, page: collection.current_page, pages: collection.total_pages }
      end
    end
  end
end
