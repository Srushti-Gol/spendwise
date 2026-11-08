class PurchaseOrderPolicy < ApplicationPolicy
  def index? = true
  def show? = true
  def create? = manager? || admin?
  def update? = manager? || admin?
  def destroy? = admin?
  def send_to_vendor? = manager? || admin?

  class Scope < Scope
    def resolve = @scope.where(tenant: user.tenant)
  end
end
