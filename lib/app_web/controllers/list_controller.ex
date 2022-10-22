defmodule AppWeb.ListController do
  use AppWeb, :controller

  def create(conn, params) do
    %{ "name" => name } = params
    json(conn, %{id: name})
  end

  def get(conn, params) do
    %{ "name" => name }  = params
    json(conn, %{ name: name })
  end

  def list(conn, _params) do
    json(conn, [])
  end
end
