class RequisitionPolicy < ApplicationPolicy
  def create?  = true
  def update?  = record.draft? && record.requester == user
  def destroy? = role_at_least?("admin")
  def submit?  = record.draft? && record.requester == user
  def approve? = role_at_least?("manager") && record.current_approver == user
  def reject?  = approve?
  def cancel?  = record.requester == user || role_at_least?("admin")

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope = @scope.where(tenant: @user.tenant)
      return scope if @user.role.in?(%w[finance director admin])

      # Managers see own + their approval inbox
      if @user.role == "manager"
        scope.where("requester_id = ? OR current_approver_id = ?", @user.id, @user.id)
      else
        scope.where(requester: @user)
      end
    end
  end
end
