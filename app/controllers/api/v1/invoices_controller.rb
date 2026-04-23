module Api
  module V1
    class InvoicesController < ApplicationController
      before_action :set_invoice, only: [:show, :update, :destroy, :process_invoice]

      def index
        invoices = policy_scope(Invoice).includes(:purchase_order, :created_by)
                                        .order(created_at: :desc)
                                        .page(params[:page]).per(25)
        invoices = invoices.where(status: params[:status]) if params[:status].present?
        render json: { invoices: invoices.map { |i| invoice_json(i) }, meta: pagination_meta(invoices) }
      end

      def show
        authorize @invoice
        render json: invoice_json(@invoice, detail: true)
      end

      def create
        @invoice = Invoice.new(invoice_params.merge(created_by: current_user, tenant: current_user.tenant))
        authorize @invoice
        if @invoice.save
          audit_action('create', @invoice)
          render json: invoice_json(@invoice), status: :created
        else
          render json: { errors: @invoice.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        authorize @invoice
        if @invoice.update(invoice_params)
          render json: invoice_json(@invoice)
        else
          render json: { errors: @invoice.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @invoice
        @invoice.destroy
        head :no_content
      end

      def process_invoice
        authorize @invoice, :process_invoice?
        InvoiceExtractionJob.perform_later(@invoice.id, current_user.tenant_id)
        audit_action('process_invoice', @invoice)
        render json: { message: 'Invoice processing queued', invoice_id: @invoice.id }
      end

      private

      def set_invoice
        @invoice = Invoice.find(params[:id])
      end

      def invoice_params
        params.require(:invoice).permit(
          :vendor, :invoice_number, :total_amount, :currency,
          :invoice_date, :pdf_url, :purchase_order_id,
          invoice_items_attributes: [:id, :description, :quantity, :unit_price, :total_price, :_destroy]
        )
      end

      def invoice_json(inv, detail: false)
        json = {
          id: inv.id, vendor: inv.vendor, invoice_number: inv.invoice_number,
          total_amount: inv.total_amount, currency: inv.currency,
          status: inv.status, invoice_date: inv.invoice_date,
          price_match: inv.price_match, quantity_match: inv.quantity_match,
          vendor_match: inv.vendor_match, is_duplicate: inv.is_duplicate,
          price_variance: inv.price_variance, quantity_variance: inv.quantity_variance,
          processed_at: inv.processed_at, created_at: inv.created_at,
          purchase_order_id: inv.purchase_order_id
        }
        if detail
          json[:match_result] = inv.match_result
          json[:extracted_data] = inv.extracted_data
          json[:items] = inv.invoice_items.map { |i| { description: i.description, quantity: i.quantity, unit_price: i.unit_price, total_price: i.total_price } }
        end
        json
      end

      def pagination_meta(collection)
        { total: collection.total_count, page: collection.current_page, pages: collection.total_pages }
      end
    end
  end
end
