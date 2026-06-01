class GoodsReceiptPolicy < ApplicationPolicy
  def index?  = true
  def show?   = true
  def create? = role_at_least?('staff')

  class Scope < Scope
    def resolve
      scope.where(tenant: user.tenant)
    end
  end
end
