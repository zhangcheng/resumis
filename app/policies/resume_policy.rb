class ResumePolicy < ApplicationPolicy
  def index?
    if user.api_user?
      has_public_access_scopes?
    else
      true
    end
  end

  def show?
    record_exists = super

    if user.api_user?
      record_exists && has_public_access_scopes?
    else
      record_exists
    end
  end

  def create?
    if user.api_user?
      user.owns?(record) && user.has_oauth_scope?(:resumes_write)
    else
      user.owns?(record)
    end
  end

  def update?
    create?
  end

  def destroy?
    create?
  end

  class Scope < Scope
    def resolve
      if user.nil? || !user.current_tenant?
        scope.where(published: true)
      else
        scope
      end
    end
  end

  private def has_public_access_scopes?
    user.has_oauth_scope?(:public) || user.has_oauth_scope?(:resumes_write)
  end
end
