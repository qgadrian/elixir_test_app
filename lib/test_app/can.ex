defimpl Canada.Can, for: TestApp.User do

  alias TestApp.{User}

  require Logger
  require IEx

  def can?(session_user, action, request_user) when action in [:update, :show, :delete] do
    session_user = TestApp.Repo.preload session_user, :role
    Logger.debug "session_user #{inspect(session_user)}"
    Logger.debug "request_user #{inspect(request_user)}"
    case request_user do
      nil -> true
      request_user ->
        Map.get(session_user.role, :name) == "admin" || session_user.id == request_user.id
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