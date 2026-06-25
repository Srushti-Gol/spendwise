class PoGenerationService
  def initialize(requisition, created_by)
    @requisition = requisition
    @created_by  = created_by
  end

  def call
    raise ArgumentError, "Requisition must be approved" unless @requisition.approved?

    ActiveRecord::Base.transaction do
      po = PurchaseOrder.create!(
        tenant:            @requisition.tenant,
        requisition:       @requisition,
        vendor:            derive_vendor,
        total_amount:      @requisition.total_amount,
        currency:          @requisition.currency || "USD",
        created_by:        @created_by,
        price_tolerance:   0.05,
        quantity_tolerance: 0.02,
        status:            "draft"
      )

      @requisition.purchase_order_items.each do |item|
        po.purchase_order_items.create!(
          description: item.description,
          quantity:    item.quantity,
          unit_price:  item.unit_price,
          total_price: item.total_price
        )
      end

      @requisition.convert_to_order!
      AuditLog.record(
        action: "po_generated",
        auditable: po,
        user: @created_by,
        ip_address: nil,
        changes_data: { requisition_id: @requisition.id }
      )

      po
    end
  end

  private

  def derive_vendor
    @requisition.preferred_vendor.presence || "TBD"
  end
end
