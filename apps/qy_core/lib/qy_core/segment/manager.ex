defmodule QyCore.Segment.Manager do
  # 实现对 QyCore.Segment.StateM 的管理
  use DynamicSupervisor

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  ## 管理器相关

  # ...

  ## 片段管理相关

  # 用于创建一个新的 Segment
  # def create

  # 用于销毁一个已有的 Segment
  # def terminate

  # 合并两个 Segments
  # def merge
  # 有 overlap 或没有 overlap 或之间有新的 Segment

  # 分割一个 Segment
  # def split

  ## 持久化相关

  # 将 Segment 持久化
  # def persist

  # 从持久化中恢复 Segment
  # def restore

  # 全部更改为某次记录
  # def update
end
