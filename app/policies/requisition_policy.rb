class RequisitionPolicy < ApplicationPolicy
  def index? = true
  def show? = true
  def create? = true

  def update?
    record.draft? && (record.requester == user || admin?)
  end

  def destroy?
    admin?
  end

  def submit?
    record.draft? && record.requester == user
  end

  def approve?
    record.pending? && record.current_approver == user && !self_approval?
  end

  def reject?
    record.pending? && record.current_approver == user
  end

  def cancel?
    (record.draft? || record.pending?) && (record.requester == user || manager?)
  end

  class Scope < Scope
    def resolve
      if user.role.in?(%w[manager finance director admin])
        base.where(tenant: user.tenant)
            .where('requester_id = ? OR current_approver_id = ?', user.id, user.id)
      else
        base.where(tenant: user.tenant, requester: user)
      end
    end

    private

    def base = @scope
  end

  private

  def self_approval?
    record.self_approval_blocked && record.requester == user
  end
end
