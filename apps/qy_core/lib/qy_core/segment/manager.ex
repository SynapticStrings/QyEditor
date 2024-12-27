defmodule QyCore.Segment.Manager do
  # 实现对 QyCore.Segment.StateM 的管理
  use DynamicSupervisor

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
