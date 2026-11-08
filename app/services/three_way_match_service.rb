class ThreeWayMatchService
  def initialize(invoice)
    @invoice = invoice
    @po = invoice.purchase_order
  end

  def perform!
    return { matched: false, exceptions: ['No linked purchase order'] } unless @po

    receipts = GoodsReceipt.where(purchase_order: @po)
    total_received = receipts.sum { |r| r.goods_receipt_items.sum(:quantity_received) }
    total_ordered = @po.purchase_order_items.sum(:quantity).to_f

    price_variance = (@invoice.total_amount - @po.total_amount).abs / @po.total_amount.to_f
    quantity_variance = total_ordered > 0 ? (total_received - total_ordered).abs / total_ordered : 0

    price_match = price_variance <= @po.price_tolerance.to_f
    quantity_match = quantity_variance <= @po.quantity_tolerance.to_f
    vendor_match = normalize(@invoice.vendor) == normalize(@po.vendor)

    exceptions = []
    exceptions << "Price variance #{(price_variance * 100).round(2)}% exceeds tolerance #{(@po.price_tolerance * 100).round(2)}%" unless price_match
    exceptions << "Quantity variance #{(quantity_variance * 100).round(2)}% exceeds tolerance #{(@po.quantity_tolerance * 100).round(2)}%" unless quantity_match
    exceptions << "Vendor mismatch: invoice '#{@invoice.vendor}' vs PO '#{@po.vendor}'" unless vendor_match

    is_duplicate = Invoice.where(tenant: @invoice.tenant, invoice_number: @invoice.invoice_number)
                          .where.not(id: @invoice.id)
                          .exists?
    exceptions << 'Duplicate invoice number detected' if is_duplicate

    match_result = {
      price_match: price_match, quantity_match: quantity_match,
      vendor_match: vendor_match, exceptions: exceptions,
      price_variance: price_variance.round(6),
      quantity_variance: quantity_variance.round(6)
    }

    new_status = exceptions.empty? ? 'matched' : 'exception'

    @invoice.update!(
      price_match: price_match, quantity_match: quantity_match,
      vendor_match: vendor_match, price_variance: price_variance,
      quantity_variance: quantity_variance, is_duplicate: is_duplicate,
      match_result: match_result, processed_at: Time.current
    )

    if new_status == 'matched'
      @invoice.mark_matched! if @invoice.may_mark_matched?
    else
      @invoice.flag_exception! if @invoice.may_flag_exception?
    end

    match_result
  end

  private

  def normalize(str)
    str.to_s.downcase.strip.gsub(/\s+/, ' ')
  end
end
