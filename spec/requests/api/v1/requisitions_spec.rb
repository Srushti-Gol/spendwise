require 'rails_helper'

RSpec.describe 'Api::V1::Requisitions', type: :request do
  let(:tenant)  { create(:tenant) }
  let(:staff)   { create(:user, tenant: tenant, role: 'staff') }
  let(:manager) { create(:user, :manager, tenant: tenant) }
  let(:token)   { generate_token(staff) }
  let(:headers) { { 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json' } }

  around(:each) { |ex| ActsAsTenant.with_tenant(tenant) { ex.run } }

  def generate_token(user)
    payload = { user_id: user.id, tenant_id: user.tenant_id, exp: 1.hour.from_now.to_i }
    JWT.encode(payload, ENV.fetch('JWT_SECRET', 'fallback_secret_change_in_production'), 'HS256')
  end

  describe 'GET /api/v1/requisitions' do
    before { create_list(:requisition, 3, tenant: tenant, requester: staff) }

    it 'returns tenant-scoped requisitions' do
      get '/api/v1/requisitions', headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['requisitions'].length).to eq(3)
    end

    it 'does not return requisitions from another tenant' do
      other_tenant = create(:tenant)
      other_user   = create(:user, tenant: other_tenant)
      create(:requisition, tenant: other_tenant, requester: other_user)

      get '/api/v1/requisitions', headers: headers
      json = JSON.parse(response.body)
      expect(json['requisitions'].length).to eq(3)
    end
  end

  describe 'POST /api/v1/requisitions' do
    let(:params) do
      { requisition: { title: 'New Laptops', department: 'Engineering', total_amount: 5000,
                       requisition_items_attributes: [{ description: 'MacBook', quantity: 2, unit_price: 2500, total_price: 5000 }] } }
    end

    it 'creates a requisition' do
      post '/api/v1/requisitions', params: params.to_json, headers: headers
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)['title']).to eq('New Laptops')
    end
  end

  describe 'POST /api/v1/requisitions/:id/submit' do
    it 'transitions requisition to pending' do
      ApprovalRule.create!(tenant: tenant, level: 1, approver_role: 'manager', min_amount: 0)
      req = create(:requisition, tenant: tenant, requester: staff, status: 'draft')

      post "/api/v1/requisitions/#{req.id}/submit", headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['status']).to eq('pending')
    end
  end

  describe 'cross-tenant isolation' do
    it 'returns 404 for requisitions belonging to another tenant' do
      other_tenant = create(:tenant)
      other_user   = create(:user, tenant: other_tenant)
      other_req    = create(:requisition, tenant: other_tenant, requester: other_user)

      get "/api/v1/requisitions/#{other_req.id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'authentication' do
    it 'returns 401 without a token' do
      get '/api/v1/requisitions'
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
