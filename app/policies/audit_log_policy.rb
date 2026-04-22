class AuditLogPolicy < ApplicationPolicy
  def index? = role_at_least?('manager')
  def show?  = role_at_least?('manager')
  def create?  = false
  def update?  = false
  def destroy? = false
end
