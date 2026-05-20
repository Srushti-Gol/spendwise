require 'rails_helper'

RSpec.describe 'AuditLogs API', type: :request do
  let(:tenant) { create(:tenant) }
  let(:admin)  { create(:user, tenant: tenant, role: 'admin') }
  let(:staff)  { create(:user, tenant: tenant, role: 'staff') }
  let(:req)    { create(:requisition, tenant: tenant, requester: admin) }

  before do
    5.times do |i|
      AuditLog.record(
        action: 'create',
        auditable: req,
        user: admin,
        ip_address: "10.0.0.#{i + 1}",
        changes_data: {}
      )
    end
  end

  describe 'GET /api/v1/audit_logs' do
    it 'returns paginated logs for admin' do
      get '/api/v1/audit_logs', headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['audit_logs'].length).to eq(5)
      expect(body['meta']).to include('total_count' => 5)
    end

    it 'filters by resource_type' do
      get '/api/v1/audit_logs', params: { resource_type: 'Requisition' }, headers: auth_headers(admin)
      body = JSON.parse(response.body)
      expect(body['audit_logs'].all? { |l| l['auditable_type'] == 'Requisition' }).to be true
    end

    it 'returns 403 for staff role' do
      get '/api/v1/audit_logs', headers: auth_headers(staff)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/v1/audit_logs/:id' do
    it 'returns detailed log entry with changes_data' do
      log = AuditLog.last
      get "/api/v1/audit_logs/#{log.id}", headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to have_key('changes_data')
      expect(body).to have_key('metadata')
    end
  end
end
