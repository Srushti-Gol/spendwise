class ThreeWayMatchService
  def initialize(invoice)
    @invoice = invoice
    @po = invoice.purchase_order
  end

  def perform!
    return no_po_result unless @po

    price_variance = calculate_price_variance
    quantity_variance = calculate_quantity_variance
    vendor_ok = vendors_match?
    duplicate = duplicate?

    price_ok = price_variance <= @po.price_tolerance
    quantity_ok = quantity_variance <= @po.quantity_tolerance

    exceptions = build_exceptions(price_ok, quantity_ok, vendor_ok, duplicate,
                                  price_variance, quantity_variance)

    @invoice.update!(
      price_match: price_ok,
      quantity_match: quantity_ok,
      vendor_match: vendor_ok,
      price_variance: price_variance,
      quantity_variance: quantity_variance,
      is_duplicate: duplicate,
      match_result: { exceptions: exceptions,
                      price_variance_pct: (price_variance * 100).round(4),
                      quantity_variance_pct: (quantity_variance * 100).round(4) },
      processed_at: Time.current
    )

    if exceptions.empty?
      @invoice.mark_matched!
    else
      @invoice.flag_exception!
    end

    { matched: exceptions.empty?, exceptions: exceptions }
  end

  private

  def calculate_price_variance
    return 0 if @po.total_amount.zero?
    (@invoice.total_amount - @po.total_amount).abs / @po.total_amount
  end

  def calculate_quantity_variance
    total_ordered = @po.purchase_order_items.sum(:quantity).to_f
    return 0 if total_ordered.zero?

    total_received = @po.goods_receipts
                        .joins(:goods_receipt_items)
                        .sum("goods_receipt_items.quantity_received").to_f

    (total_received - total_ordered).abs / total_ordered
  end

  def vendors_match?
    @invoice.vendor.downcase.strip == @po.vendor.downcase.strip
  end

  def duplicate?
    Invoice.where(tenant: @invoice.tenant, invoice_number: @invoice.invoice_number)
           .where.not(id: @invoice.id)
           .exists?
  end

  def build_exceptions(price_ok, quantity_ok, vendor_ok, duplicate, pv, qv)
    exceptions = []
    unless price_ok
      exceptions << "Price variance #{(pv * 100).round(2)}% exceeds tolerance #{(@po.price_tolerance * 100).round(2)}%"
    end
    unless quantity_ok
      exceptions << "Quantity variance #{(qv * 100).round(2)}% exceeds tolerance #{(@po.quantity_tolerance * 100).round(2)}%"
    end
    exceptions << "Vendor mismatch: invoice '#{@invoice.vendor}' vs PO '#{@po.vendor}'" unless vendor_ok
    exceptions << "Duplicate invoice number detected" if duplicate
    exceptions
  end

  def no_po_result
    @invoice.update!(match_result: { exceptions: [ "No linked purchase order" ] }, processed_at: Time.current)
    @invoice.flag_exception!
    { matched: false, exceptions: [ "No linked purchase order" ] }
  end
end
