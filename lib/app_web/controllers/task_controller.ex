defmodule AppWeb.TaskController do
  use AppWeb, :controller

  def create(conn, params) do
    %{ "list_name" => list_name, "text" => text } = params
    json(conn, %{id: "0000-1111-2222-3333", list_name: list_name, text: text})
  end

  def get(conn, params) do
    %{ "list_name" => _list_name, "task_id" => _task_id } = params
    json(conn, %{ text: "a text", mark: :unmarked})
  end

  def list(conn, _params) do
    json(conn, [])
  end

  def remove(conn, params) do
    %{ "list_name" => _name, "task_id" => _task_id } = params
    Plug.Conn.send_resp(conn, 204, "")
  end

  def update(conn, params) do
    %{ "list_name" => _list_name, "task_id" => _task_id, "text" => _text } = params
    Plug.Conn.send_resp(conn, 204, "")
  end

  def mark(conn, params) do
    %{ "list_name" => _name, "task_id" => _task_id } = params
    Plug.Conn.send_resp(conn, 204, "")
  end

  def unmark(conn, params) do
    %{ "list_name" => _name, "task_id" => _task_id } = params
    Plug.Conn.send_resp(conn, 204, "")
  end
end
