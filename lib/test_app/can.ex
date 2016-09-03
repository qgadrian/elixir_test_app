defimpl Canada.Can, for: TestApp.User do

  alias TestApp.{User}

  require Logger

  def can?(%User{id: user_id}, action, session_user) when action in [:update, :show, :delete] do
    case session_user do
      nil -> false
      user -> user_id == user.id
    end
  end

  def can?(%User{}, action) when action in [:create] do true end

#  def can?(%TestApp.User{admin: admin}, action, _)
#    when action in [:update, :read, :destroy, :touch], do: admin

#  def can?(%User{}, :create, Post), do: true

#  def can?(user, action, Something) when action in [:new, :create] do
#    user.role == "something_owner"
#  end

#  def can?(user, action, something = %User{}) do
#    something.owner_id == user.id
#  end
end