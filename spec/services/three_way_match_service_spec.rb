require 'rails_helper'

RSpec.describe ThreeWayMatchService, type: :service do
  let(:tenant)  { create(:tenant) }
  let(:manager) { create(:user, :manager, tenant: tenant) }
  let(:finance) { create(:user, :finance, tenant: tenant) }

  around(:each) { |ex| ActsAsTenant.with_tenant(tenant) { ex.run } }

  describe '#perform!' do
    context 'when price variance is within tolerance' do
      it 'marks invoice as matched' do
        po = create(:purchase_order, tenant: tenant, created_by: manager,
                    vendor: 'Acme Supplies', total_amount: 10_000, status: 'sent')
        invoice = create(:invoice, tenant: tenant, created_by: finance,
                         vendor: 'Acme Supplies', total_amount: 10_200, purchase_order: po)
        invoice.start_processing!

        result = described_class.new(invoice).perform!

        expect(result[:matched]).to be true
        expect(invoice.reload.status).to eq('matched')
        expect(invoice.price_match).to be true
      end
    end

    context 'when price variance exceeds tolerance' do
      it 'flags the invoice as an exception' do
        po = create(:purchase_order, tenant: tenant, created_by: manager,
                    vendor: 'Acme Supplies', total_amount: 10_000,
                    status: 'sent', price_tolerance: 0.02)
        invoice = create(:invoice, tenant: tenant, created_by: finance,
                         vendor: 'Acme Supplies', total_amount: 11_000, purchase_order: po)
        invoice.start_processing!

        result = described_class.new(invoice).perform!

        expect(result[:matched]).to be false
        expect(result[:exceptions]).to include(match(/Price variance/))
        expect(invoice.reload.status).to eq('exception')
      end
    end

    context 'when vendor names differ' do
      it 'flags vendor mismatch exception' do
        po = create(:purchase_order, tenant: tenant, created_by: manager,
                    vendor: 'Acme Supplies', total_amount: 10_000, status: 'sent')
        invoice = create(:invoice, tenant: tenant, created_by: finance,
                         vendor: 'Different Vendor', total_amount: 10_000, purchase_order: po)
        invoice.start_processing!

        result = described_class.new(invoice).perform!

        expect(result[:exceptions]).to include(match(/Vendor mismatch/))
      end
    end

    context 'when invoice number is duplicated within tenant' do
      it 'flags duplicate exception' do
        po = create(:purchase_order, tenant: tenant, created_by: manager,
                    vendor: 'Acme Supplies', total_amount: 10_000, status: 'sent')
        create(:invoice, tenant: tenant, created_by: finance,
               invoice_number: 'INV-DUP-001', vendor: 'Acme Supplies', total_amount: 10_000)
        invoice = create(:invoice, tenant: tenant, created_by: finance,
                         vendor: 'Acme Supplies', total_amount: 10_000,
                         invoice_number: 'INV-DUP-001', purchase_order: po)
        invoice.start_processing!

        result = described_class.new(invoice).perform!

        expect(result[:exceptions]).to include(match(/Duplicate/))
      end
    end

    context 'when no purchase order is linked' do
      it 'flags missing PO exception' do
        invoice = create(:invoice, tenant: tenant, created_by: finance, purchase_order: nil)
        invoice.start_processing!

        result = described_class.new(invoice).perform!

        expect(result[:matched]).to be false
        expect(result[:exceptions]).to include('No linked purchase order')
      end
    end
  end
end
