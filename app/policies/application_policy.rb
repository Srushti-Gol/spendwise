class ApplicationPolicy
  ROLES = { staff: 0, manager: 1, finance: 2, director: 3, admin: 4 }.freeze

  attr_reader :user, :record

  def initialize(user, record)
    raise Pundit::NotAuthorizedError, 'must be logged in' unless user
    @user = user
    @record = record
  end

  def index? = user_role >= ROLES[:staff]
  def show? = user_role >= ROLES[:staff]
  def create? = user_role >= ROLES[:staff]
  def update? = user_role >= ROLES[:manager]
  def destroy? = user_role >= ROLES[:admin]

  private

  def user_role
    ROLES[user.role.to_sym] || 0
  end

  def admin? = user.role == 'admin'
  def director? = user_role >= ROLES[:director]
  def finance? = user_role >= ROLES[:finance]
  def manager? = user_role >= ROLES[:manager]

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @scope.where(tenant: @user.tenant)
    end
  end
end
