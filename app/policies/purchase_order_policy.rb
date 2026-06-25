class PurchaseOrderPolicy < ApplicationPolicy
  def index?        = true
  def show?         = true
  def create?       = role_at_least?("finance")
  def update?       = role_at_least?("finance") && record.draft?
  def destroy?      = role_at_least?("admin")
  def send_to_vendor? = role_at_least?("finance") && record.draft?

  class Scope < ApplicationPolicy::Scope
    def resolve
      @scope.where(tenant: @user.tenant)
    end
  end
end
