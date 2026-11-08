class RequisitionItem < ApplicationRecord
  belongs_to :requisition

  validates :description, :quantity, :unit_price, :total_price, presence: true
  validates :quantity, :unit_price, numericality: { greater_than: 0 }

  before_save :calculate_total

  private

  def calculate_total
    self.total_price = quantity * unit_price if quantity && unit_price
  end
end
