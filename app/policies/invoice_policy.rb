class InvoicePolicy < ApplicationPolicy
  def create?          = role_at_least?('finance')
  def update?          = role_at_least?('finance')
  def process_invoice? = role_at_least?('finance')
  def approve_payment? = role_at_least?('director')
end
