class ApprovalChainService
  def initialize(requisition)
    @requisition = requisition
    @tenant = requisition.tenant
  end

  def build_chain!
    rules = ApprovalRule.where(tenant: @tenant)
                        .where("department IS NULL OR department = ?", @requisition.department)
                        .where("min_amount <= ?", @requisition.total_amount)
                        .where("max_amount IS NULL OR max_amount >= ?", @requisition.total_amount)
                        .order(:level)

    raise "No approval rules configured for this amount/department" if rules.empty?

    @requisition.approval_steps.destroy_all

    steps = rules.map do |rule|
      approver = User.where(tenant: @tenant, role: rule.approver_role)
                     .where.not(id: @requisition.requester_id)
                     .first
      next unless approver

      ApprovalStep.create!(
        tenant: @tenant,
        requisition: @requisition,
        approver: approver,
        level: rule.level,
        status: "pending"
      )
    end.compact

    first_step = steps.min_by(&:level)
    @requisition.update!(current_approver: first_step&.approver)
    steps
  end

  def advance!(approved_by:, comment: nil)
    current_step = pending_step
    raise "No pending approval step" unless current_step
    raise "Self-approval is not allowed" if current_step.approver_id == @requisition.requester_id

    current_step.approve!(comment: comment)

    next_step = @requisition.approval_steps.where(status: "pending").order(:level).first
    if next_step
      @requisition.update!(current_approver: next_step.approver)
    else
      @requisition.approve!
      @requisition.update!(current_approver: nil)
    end
  end

  def reject!(rejected_by:, comment: nil)
    step = pending_step
    step&.reject!(comment: comment)
    @requisition.reject!
    @requisition.update!(current_approver: nil)
  end

  private

  def pending_step
    @requisition.approval_steps.where(status: "pending").order(:level).first
  end
end
