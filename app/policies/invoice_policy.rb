class InvoicePolicy < ApplicationPolicy
  def index?   = true
  def show?    = true
  def create?  = role_at_least?('finance')
  def update?  = role_at_least?('finance') && !record.paid?
  def destroy? = role_at_least?('admin')

  def process_invoice?  = role_at_least?('finance') && record.pending?
  def approve_payment?  = role_at_least?('finance') && record.matched?

  class Scope < ApplicationPolicy::Scope
    def resolve
      @scope.where(tenant: @user.tenant)
    end
  end
end
