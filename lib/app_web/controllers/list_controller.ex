defmodule AppWeb.ListController do
  use AppWeb, :controller

  def create(conn, params) do
    %{ "name" => name } = params
    try(conn, fn -> App.ToDoList.Worker.create(name) end, fn _ -> Plug.Conn.send_resp(conn, 204, "") end)
  end

  def list(conn, params) do
    sort_direction = Map.get(params, "sortDirection", "asc")
    name_filter = Map.get(params, "name", "")

    sort_direction = if sort_direction == "desc", do: :desc, else: :asc
    todo_lists = App.ToDoList.Worker.all()

    reducer = fn { name, _, _ }, map ->
      if (name_filter == "" || String.contains?(name, name_filter)) do
        todo_list_result = Map.get(map, name, %{ name: name, workersCount: 0 })
        Map.put(map, name, %{ name: todo_list_result.name, workersCount: todo_list_result.workersCount + 1 })
      else
        map
      end
    end

    result = todo_lists
    |> Enum.reduce(%{}, reducer)
    |> Map.values
    |> Enum.sort_by(& &1.name, sort_direction)

    json(conn, result)
  end

  defp try(conn, action, response) do
    duplicated_action = fn error ->
      conn
      |> Plug.Conn.put_status(400)
      |> json(error)
    end

    case action.() do
      { :duplicated_to_do_list, error } -> duplicated_action.(error)
      result -> response.(result)
    end
  end
end
