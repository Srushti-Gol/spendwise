require 'rails_helper'

RSpec.describe AuditLog, type: :model do
  let(:tenant) { create(:tenant) }
  let(:user)   { create(:user, tenant: tenant) }
  let(:req)    { create(:requisition, tenant: tenant, requester: user) }

  describe '.record' do
    it 'creates an audit log entry' do
      expect {
        AuditLog.record(
          action: 'submit',
          auditable: req,
          user: user,
          ip_address: '127.0.0.1',
          changes_data: { status: ['draft', 'pending'] }
        )
      }.to change(AuditLog, :count).by(1)
    end

    it 'stores the action and auditable polymorphic reference' do
      log = AuditLog.record(
        action: 'approve',
        auditable: req,
        user: user,
        ip_address: '127.0.0.1',
        changes_data: {}
      )
      expect(log.action).to eq('approve')
      expect(log.auditable_type).to eq('Requisition')
      expect(log.auditable_id).to eq(req.id)
    end
  end

  describe 'append-only immutability' do
    subject(:log) { AuditLog.record(action: 'create', auditable: req, user: user, ip_address: '127.0.0.1', changes_data: {}) }

    it 'raises ReadOnlyRecord on update' do
      expect { log.update!(action: 'tampered') }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it 'raises ReadOnlyRecord on destroy' do
      expect { log.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end
  end
end
