class PurchaseOrderPolicy < ApplicationPolicy
  def create?  = role_at_least?('manager')
  def update?  = role_at_least?('manager')
  def destroy? = role_at_least?('admin')
end
