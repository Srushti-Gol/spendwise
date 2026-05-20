require 'rails_helper'

RSpec.describe 'GET /api/v1/dashboard/stats', type: :request do
  let(:tenant) { create(:tenant) }
  let(:user)   { create(:user, tenant: tenant, role: 'admin') }
  let(:headers) { auth_headers(user) }

  before do
    create_list(:requisition, 3, tenant: tenant, requester: user, status: 'pending')
    create_list(:invoice, 2, tenant: tenant, created_by: user, status: 'exception')
  end

  it 'returns requisition counts, po stats, invoice stats, and spend_by_month' do
    get '/api/v1/dashboard/stats', headers: headers
    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body).to have_key('requisitions')
    expect(body).to have_key('purchase_orders')
    expect(body).to have_key('invoices')
    expect(body).to have_key('spend_by_month')
    expect(body['requisitions']['pending']).to eq(3)
    expect(body['invoices']['exceptions']).to eq(2)
  end

  it 'returns 401 without auth' do
    get '/api/v1/dashboard/stats'
    expect(response).to have_http_status(:unauthorized)
  end
end
