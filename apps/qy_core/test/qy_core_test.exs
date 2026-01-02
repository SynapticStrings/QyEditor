defmodule QyCoreTest do
  use ExUnit.Case
  doctest QyCore

  test "initializes correctly" do
    assert QyCore.init() == :ok
  end

  test "creates a task" do
    {:ok, task_id} = QyCore.create_task(%{name: "Test Task"})
    assert is_binary(task_id)
    assert byte_size(task_id) > 0
  end
end
