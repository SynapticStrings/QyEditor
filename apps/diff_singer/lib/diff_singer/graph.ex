defmodule DiffSinger.Graph do
  @moduledoc false
  # 用于管理模型状态的 helper
  # 其中节点并不对应着模型本体，可能是模型所在进程 pid 或是什么的
  # 节点需要有一个属性叫做 `port` ，如果两个节点的 `port` 一样会变成边
  # 所有的没有边的 `port` 就作为输入输出
  # 有一个很典型的应用场景，比方说 Graph Γ 有三个输入，两个模型
  # 就像 (a, b) -> A -> o1; (b, c) -> B -> o2
  # 当我对 a 进行修改，我只需要调用模型 A 再重新生成即可。
  # 和 Model 的差别就在于它算是某种对模型的抽象。
  # 可能最后与 `DiffSinger.Port.Serving` 对接的就是这类模块。

  @type t :: %__MODULE__{
    config: any(),
    nodes: %{atom() => any()},
    edges: [any()],
    ports: [any()],
  }
  defstruct [:config, :nodes, :edges, :ports]

  # def add_node()
  # def add_edge()
  # def build()

  # def show_ports()
end
