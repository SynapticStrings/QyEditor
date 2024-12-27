defmodule QyCore.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # 前两个是必须的，第三个是否开发还是要考虑一下的
    children = [
      # 执行推理任务的子进程
      # QyCore.InferenceWorker,
      # 管理片段状态的子进程
      # QyCore.Segment.Manager,
      # 相关片段以及记录的存储（包括缓存以及持久化）
      # QyCore.Repo,
    ]

    opts = [strategy: :one_for_one, name: QyCore.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
