require 'rails_helper'

RSpec.describe Requisition, type: :model do
  let(:tenant)   { create(:tenant) }
  let(:manager)  { create(:user, tenant: tenant, role: 'manager') }
  let(:req) do
    create(:requisition, tenant: tenant, requester: manager,
           current_approver: manager, status: 'draft')
  end

  describe 'AASM state machine' do
    it 'starts in draft state' do
      expect(req.status).to eq('draft')
    end

    it 'transitions draft -> pending on submit when no self-approval conflict' do
      other_approver = create(:user, tenant: tenant, role: 'manager')
      req.update!(current_approver: other_approver)
      expect { req.submit! }.to change(req, :status).from('draft').to('pending')
    end

    it 'blocks submit when requester == current_approver and self_approval_blocked' do
      req.update!(self_approval_blocked: true)
      expect { req.submit! }.to raise_error(AASM::InvalidTransition)
    end

    it 'transitions pending -> approved on approve' do
      req.update!(status: 'pending')
      expect { req.approve! }.to change(req, :status).from('pending').to('approved')
    end

    it 'transitions pending -> rejected on reject' do
      req.update!(status: 'pending')
      expect { req.reject! }.to change(req, :status).from('pending').to('rejected')
    end

    it 'can cancel from draft or pending' do
      expect { req.cancel! }.to change(req, :status).from('draft').to('cancelled')
    end
  end

  describe 'validations' do
    it 'is invalid without title' do
      req.title = nil
      expect(req).not_to be_valid
    end

    it 'is invalid with non-positive total_amount' do
      req.total_amount = -50
      expect(req).not_to be_valid
    end
  end
end
