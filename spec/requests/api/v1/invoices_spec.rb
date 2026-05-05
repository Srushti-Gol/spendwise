require 'rails_helper'

RSpec.describe 'Api::V1::Invoices', type: :request do
  let(:tenant)  { create(:tenant) }
  let(:finance) { create(:user, :finance, tenant: tenant) }
  let(:token)   { generate_token(finance) }
  let(:headers) { { 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json' } }

  around(:each) { |ex| ActsAsTenant.with_tenant(tenant) { ex.run } }

  def generate_token(user)
    payload = { user_id: user.id, tenant_id: user.tenant_id, exp: 1.hour.from_now.to_i }
    JWT.encode(payload, ENV.fetch('JWT_SECRET', 'fallback_secret_change_in_production'), 'HS256')
  end

  describe 'POST /api/v1/invoices' do
    let(:params) do
      { invoice: { vendor: 'Acme Corp', invoice_number: 'INV-001',
                   total_amount: 10_000, invoice_date: Date.today.iso8601 } }
    end

    it 'creates an invoice in pending state' do
      post '/api/v1/invoices', params: params.to_json, headers: headers
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['vendor']).to eq('Acme Corp')
      expect(json['status']).to eq('pending')
    end
  end

  describe 'POST /api/v1/invoices/:id/process_invoice' do
    it 'queues InvoiceExtractionJob' do
      invoice = create(:invoice, tenant: tenant, created_by: finance)
      expect(InvoiceExtractionJob).to receive(:perform_later).with(invoice.id, invoice.tenant_id)

      post "/api/v1/invoices/#{invoice.id}/process_invoice", headers: headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'cross-tenant isolation' do
    it 'cannot access invoices from another tenant' do
      other_tenant  = create(:tenant)
      other_finance = create(:user, :finance, tenant: other_tenant)
      other_invoice = create(:invoice, tenant: other_tenant, created_by: other_finance)

      get "/api/v1/invoices/#{other_invoice.id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
