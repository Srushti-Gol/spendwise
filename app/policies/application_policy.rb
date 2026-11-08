class ApplicationPolicy
  ROLE_WEIGHTS = { 'staff' => 0, 'manager' => 1, 'finance' => 2, 'director' => 3, 'admin' => 4 }.freeze

  attr_reader :user, :record

  def initialize(user, record)
    raise Pundit::NotAuthorizedError, 'must be logged in' unless user
    @user = user
    @record = record
  end

  def index?  = role_at_least?('staff')
  def show?   = role_at_least?('staff')
  def create? = role_at_least?('staff')
  def update? = role_at_least?('manager')
  def destroy? = role_at_least?('admin')

  class Scope
    def initialize(user, scope)
      @user  = user
      @scope = scope
    end

    def resolve
      @scope.where(tenant: @user.tenant)
    end
  end

  protected

  def role_at_least?(minimum)
    (ROLE_WEIGHTS[@user.role] || 0) >= (ROLE_WEIGHTS[minimum] || 0)
  end
end
