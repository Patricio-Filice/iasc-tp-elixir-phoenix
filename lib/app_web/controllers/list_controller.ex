defmodule AppWeb.ListController do
  use AppWeb, :controller

  def create(conn, params) do
    %{ "name" => name } = params
    App.ToDoList.Worker.create(name)
    Plug.Conn.send_resp(conn, 204, "")
  end

  def get(conn, params) do
    %{ "name" => name }  = params
    json(conn, %{ name: name })
  end

  def list(conn, _params) do
    lists = App.ToDoList.Worker.all()
    map = fn { name, _, _ } ->
      %{ name: name  }
    end
    json(conn, Enum.map(lists, map))
  end
end
