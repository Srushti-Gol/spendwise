class GoodsReceiptPolicy < ApplicationPolicy
  def create? = role_at_least?('staff')
  def update? = role_at_least?('manager')
end
