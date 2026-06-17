require 'rails_helper'

RSpec.describe PoGenerationService do
  let(:tenant)   { create(:tenant) }
  let(:finance)  { create(:user, tenant: tenant, role: 'finance') }
  let(:staff)    { create(:user, tenant: tenant, role: 'staff') }
  let(:req) do
    create(:requisition, tenant: tenant, requester: staff, status: 'approved',
           total_amount: 2500.0, currency: 'USD')
  end

  before do
    create(:requisition_item, requisition: req, quantity: 10, unit_price: 250.0)
  end

  subject(:service) { described_class.new(req, finance) }

  it 'creates a PurchaseOrder with matching total' do
    expect { service.call }.to change(PurchaseOrder, :count).by(1)
    po = PurchaseOrder.last
    expect(po.total_amount).to eq(2500.0)
    expect(po.tenant).to eq(tenant)
  end

  it 'transitions requisition to ordered state' do
    service.call
    expect(req.reload.status).to eq('ordered')
  end

  it 'creates audit log entry' do
    expect { service.call }.to change(AuditLog, :count).by(1)
    log = AuditLog.last
    expect(log.action).to eq('po_generated')
    expect(log.user).to eq(finance)
  end

  it 'raises if requisition is not approved' do
    req.update!(status: 'pending')
    expect { service.call }.to raise_error(ArgumentError, /must be approved/)
  end
end
