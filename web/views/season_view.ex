defmodule TestApp.SessionView do
  use TestApp.Web, :view

  def render("show.json", %{jwt: jwt, user: user}) do
    %{
      jwt: jwt,
      user: user
    }
  end

  def render("show.json", %{user: user}) do
      %{user: user}
  end

  def render("show.json", %{jwt: jwt}) do
    %{jwt: jwt}
  end

  def render("error.json", %{errors: errors}) do
    %{errors: errors}
  end

  def render("delete.json", _) do
    %{ok: true}
  end

  def render("forbidden.json", %{error: error}) do
    %{error: error}
  end

  def render("not_found.json", %{id: id}) do
    %{error: "Not found #{id}"}
  end
end