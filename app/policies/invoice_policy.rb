class InvoicePolicy < ApplicationPolicy
  def index? = true
  def show? = true
  def create? = finance? || admin?
  def update? = finance? || admin?
  def destroy? = admin?
  def process_invoice? = finance? || admin?
  def approve_invoice? = finance? || admin?
  def mark_paid? = finance? || admin?

  class Scope < Scope
    def resolve = @scope.where(tenant: user.tenant)
  end
end
