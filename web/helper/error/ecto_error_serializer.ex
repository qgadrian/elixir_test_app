defmodule TestApp.ChangesetView do
  use TestApp.Web, :view

  def render_errors(changeset: changeset) do
    Enum.map(changeset.errors, fn {field, detail} ->
      %{
        field: "#{field}",
        detail: render_detail(detail)
      }
    end)
  end

  def render_detail({message, opts}) do
    Enum.reduce opts, message, fn {k, v}, acc ->
      String.replace(acc, "%{#{k}}", to_string(v))
    end
  end

  def render_detail(message) do
    message
  end
end