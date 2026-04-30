require 'rails_helper'

RSpec.describe ApprovalChainService, type: :service do
  let(:tenant)    { create(:tenant) }
  let(:staff)     { create(:user, tenant: tenant, role: 'staff', department: 'Engineering') }
  let(:manager)   { create(:user, :manager, tenant: tenant) }
  let(:finance)   { create(:user, :finance, tenant: tenant) }

  around(:each) { |ex| ActsAsTenant.with_tenant(tenant) { ex.run } }

  before do
    ApprovalRule.create!(tenant: tenant, level: 1, approver_role: 'manager', min_amount: 0, max_amount: 10_000)
    ApprovalRule.create!(tenant: tenant, level: 2, approver_role: 'finance', min_amount: 10_001)
  end

  describe '#build_chain!' do
    it 'creates approval steps based on amount thresholds' do
      req = create(:requisition, tenant: tenant, requester: staff, total_amount: 5_000)
      steps = described_class.new(req).build_chain!

      expect(steps.length).to eq(1)
      expect(steps.first.approver).to eq(manager)
      expect(req.reload.current_approver).to eq(manager)
    end

    it 'creates multi-level chain for large amounts' do
      req = create(:requisition, tenant: tenant, requester: staff, total_amount: 50_000)
      steps = described_class.new(req).build_chain!

      expect(steps.length).to eq(2)
      expect(steps.map(&:level)).to eq([1, 2])
    end
  end

  describe '#advance!' do
    it 'approves current step and advances to next approver' do
      req = create(:requisition, tenant: tenant, requester: staff, total_amount: 50_000)
      described_class.new(req).build_chain!
      req.submit!

      described_class.new(req).advance!(approved_by: manager, comment: 'Looks good')

      expect(req.reload.current_approver).to eq(finance)
      expect(req.approval_steps.find_by(approver: manager).status).to eq('approved')
    end

    it 'fully approves requisition when last step is approved' do
      req = create(:requisition, tenant: tenant, requester: staff, total_amount: 5_000)
      described_class.new(req).build_chain!
      req.submit!

      described_class.new(req).advance!(approved_by: manager)

      expect(req.reload.status).to eq('approved')
      expect(req.current_approver).to be_nil
    end

    it 'blocks self-approval' do
      req = create(:requisition, tenant: tenant, requester: manager, total_amount: 5_000,
                   current_approver: manager)
      ApprovalStep.create!(tenant: tenant, requisition: req, approver: manager, level: 1, status: 'pending')

      expect {
        described_class.new(req).advance!(approved_by: manager)
      }.to raise_error('Self-approval is not allowed')
    end
  end

  describe '#reject!' do
    it 'rejects the requisition and clears current approver' do
      req = create(:requisition, tenant: tenant, requester: staff, total_amount: 5_000)
      described_class.new(req).build_chain!
      req.submit!

      described_class.new(req).reject!(rejected_by: manager, comment: 'Not approved')

      expect(req.reload.status).to eq('rejected')
      expect(req.current_approver).to be_nil
    end
  end
end
