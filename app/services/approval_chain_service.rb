class ApprovalChainService
  def initialize(requisition)
    @requisition = requisition
  end

  def build_chain!
    rules = ApprovalRule
              .for_amount(@requisition.total_amount)
              .for_department(@requisition.department)
              .order(:level)

    steps = rules.filter_map do |rule|
      approver = User.where(role: rule.approver_role).first
      next unless approver

      ApprovalStep.create!(
        tenant: @requisition.tenant,
        requisition: @requisition,
        approver: approver,
        level: rule.level,
        status: 'pending'
      )
    end

    if steps.any?
      @requisition.update!(current_approver: steps.first.approver)
    end

    steps
  end

  def advance!(approved_by:, comment: nil)
    current_step = @requisition.approval_steps.where(status: 'pending').order(:level).first
    return false unless current_step

    if current_step.approver_id == @requisition.requester_id && @requisition.self_approval_blocked
      raise StandardError, 'Self-approval is not allowed'
    end

    current_step.approve!(comment: comment)

    next_step = @requisition.approval_steps.where(status: 'pending').order(:level).first
    if next_step
      @requisition.update!(current_approver: next_step.approver)
    else
      @requisition.approve!
      @requisition.update!(current_approver: nil)
    end

    true
  end

  def reject!(rejected_by:, comment: nil)
    current_step = @requisition.approval_steps.where(status: 'pending').order(:level).first
    current_step&.reject!(comment: comment)

    @requisition.approval_steps.where(status: 'pending').update_all(status: 'skipped')
    @requisition.reject!
    @requisition.update!(current_approver: nil)
  end
end
