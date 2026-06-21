require 'rails_helper'

RSpec.describe VendorMatchService do
  describe '#match?' do
    it 'returns true for exact match' do
      expect(described_class.new('Acme Corp', 'Acme Corp').match?).to be true
    end

    it 'is case-insensitive' do
      expect(described_class.new('ACME CORP', 'acme corp').match?).to be true
    end

    it 'returns true for acronym match' do
      expect(described_class.new('IBM', 'International Business Machines').match?).to be true
    end

    it 'returns true for high-similarity fuzzy match' do
      expect(described_class.new('Acme Corporation', 'Acme Corp').match?).to be true
    end

    it 'returns false for completely different vendors' do
      expect(described_class.new('Acme Corp', 'Global Supplies Ltd').match?).to be false
    end

    it 'returns false for empty strings' do
      expect(described_class.new('', 'Acme Corp').match?).to be false
    end
  end

  describe '#similarity_score' do
    it 'returns 1.0 for identical strings' do
      expect(described_class.new('Vendor A', 'Vendor A').similarity_score).to eq(1.0)
    end

    it 'returns 0.0 for empty invoice vendor' do
      expect(described_class.new('', 'Vendor B').similarity_score).to eq(0.0)
    end
  end
end
