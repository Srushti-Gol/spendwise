class AuditLogPolicy < ApplicationPolicy
  def index? = role_at_least?('finance')
  def show?  = role_at_least?('finance')

  class Scope < Scope
    def resolve
      scope.where(tenant: user.tenant)
    end
  end
end
