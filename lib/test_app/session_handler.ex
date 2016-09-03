defmodule TestApp.SessionHandler do
  require Logger

  def handle_unexpected_error(conn, error_message) do
    Logger.error ("Unexpected error: #{error_message}")
    conn
    |> Plug.Conn.put_status(:internal_server_error)
    |> Phoenix.Controller.render(TestApp.SessionView, "error.json", error: "Error procesing request")
  end

  def handle_unauthorized(conn) do
    Logger.debug "Unauthorized request"
    conn
    |> Plug.Conn.put_status(:forbidden)
    |> Phoenix.Controller.render(TestApp.SessionView, "forbidden.json", error: "Forbidden")
    raise UnauthorizedRequest, message: "Unauthorized request"
  end
end