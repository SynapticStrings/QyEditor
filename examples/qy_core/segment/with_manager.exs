
# 主要的子进程管理器
children = [
  {DynamicSupervisor, strategy: :one_for_one, name: QyCore.Segment.Manager}
]

{:ok, _supervisor} = Supervisor.start_link(children, strategy: :one_for_one)

# 从 0.00 开始，每过 2.0 的 offset 加一个
