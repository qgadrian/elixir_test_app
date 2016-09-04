defmodule TestApp.Plug.CanaryUser do
  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    current_user = Guardian.Plug.current_resource(conn)
    Logger.debug "Inyecting current user #{inspect(current_user)}"
    Plug.Conn.assign(conn, :current_user, current_user)
  end
end