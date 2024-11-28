defmodule DiffSinger.Graph do
  @moduledoc """
  负责管理模型调用顺序的 helper。

  因为模型场景的复杂性以及功能的特异性而被设计，旨在表示不同模型的依赖与上下游关系。
  可以更加精确地调用模型的更多功能。本质上是一个有向无环图。

  其中节点并不对应着模型本体，可能是模型的 Reference 。节点需要有一个属性叫做
  `port` ，如果两个节点的 `port` 一样会变成边（但一般来讲边下游的 `port`
  也允许非模型生成的数据）。所有的没有边的 `port` 就作为输入或者输出。

  有一个很典型的应用场景，比方说 Graph Γ 有三个输入，两个模型；
  就像 (a, b) -> A -> o1; (b, c) -> B -> o2
  当我对 a 进行修改，我只需要调用模型 A 再重新生成即可。
  """
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

  # defp cyclin_check()
  # -> config: interpret_edge

  # def build(model_list) do
  # end

  # def show_ports(graph, opts \\ []) do
  # end
end
