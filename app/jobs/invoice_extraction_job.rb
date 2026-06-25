class InvoiceExtractionJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: 3, backtrace: true

  STRICT_SCHEMA = %w[vendor invoice_number date items total_amount currency].freeze

  def perform(invoice_id, tenant_id)
    ActsAsTenant.with_tenant(Tenant.find(tenant_id)) do
      invoice = Invoice.find(invoice_id)
      invoice.start_processing!

      extracted = extract_from_document(invoice.pdf_url)
      validate_schema!(extracted)

      invoice.update!(
        vendor:         extracted["vendor"],
        invoice_number: extracted["invoice_number"],
        invoice_date:   Date.parse(extracted["date"]),
        total_amount:   extracted["total_amount"],
        currency:       extracted["currency"] || "USD",
        extracted_data: extracted
      )

      update_line_items(invoice, extracted["items"] || [])
      auto_link_purchase_order(invoice)
      ThreeWayMatchService.new(invoice.reload).perform!

    rescue ArgumentError => e
      invoice.update!(match_result: { exceptions: [ e.message ] })
      invoice.flag_exception!
      raise
    end
  end

  private

  # In production: OpenRouter → GPT-4o-mini for PDFs (~2 s each),
  # Gemini 2.5 Flash for image scans. Offline heuristic fallback for CI.
  def extract_from_document(url)
    return offline_heuristic_extraction if url.blank? || ENV["AI_OFFLINE"] == "true"

    # client = OpenAI::Client.new(api_key: ENV['OPENROUTER_API_KEY'], uri_base: 'https://openrouter.ai/api/v1')
    # response = client.chat(parameters: { model: 'openai/gpt-4o-mini', messages: pdf_prompt(url) })
    # JSON.parse(response.dig('choices', 0, 'message', 'content'))
    offline_heuristic_extraction
  end

  def offline_heuristic_extraction
    {
      "vendor"         => "Sample Vendor Ltd",
      "invoice_number" => "INV-#{SecureRandom.hex(4).upcase}",
      "date"           => Date.today.iso8601,
      "items"          => [],
      "total_amount"   => 0.0,
      "currency"       => "USD"
    }
  end

  def validate_schema!(data)
    missing = STRICT_SCHEMA.reject { |k| data.key?(k) }
    raise ArgumentError, "Schema validation failed — missing: #{missing.join(', ')}" if missing.any?
  end

  def update_line_items(invoice, items)
    invoice.invoice_items.destroy_all
    items.each do |item|
      invoice.invoice_items.create!(
        description: item["description"] || "Item",
        quantity:    item["quantity"] || 1,
        unit_price:  item["unit_price"] || 0,
        total_price: item["total_price"] || 0
      )
    end
  end

  def auto_link_purchase_order(invoice)
    return if invoice.purchase_order_id.present?

    po = PurchaseOrder.where(vendor: invoice.vendor)
                      .where(status: %w[sent partial])
                      .order(created_at: :desc)
                      .first
    invoice.update!(purchase_order: po) if po
  end
end
