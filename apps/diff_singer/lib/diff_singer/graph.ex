defmodule DiffSinger.Graph do
  @moduledoc """
  负责管理模型调用顺序的 helper。

  因为模型场景的复杂性以及功能的特异性而被设计，旨在表示不同模型的依赖与上下游关系。
  可以更加精确地调用模型的更多功能。本质上是一个有向图。

  其中节点并不对应着模型本体，可能是模型的 Reference 。节点需要有一个属性叫做
  `port` ，如果两个节点的 `port` 一样会变成边（但一般来讲边下游的 `port`
  也允许非模型生成的数据）。所有的没有边的 `port` 就作为输入或者输出。

  用人话来说就是直接把模型以及有关模型的数据输出的信息丢进去，把存在内在联系的那些数据
  （比方说模型 A 的输出 x 就是模型 B 的输入，模型 C 的数据 y 也是模型 D 、 E 的输入）
  连起来，把没有确定联系的那些输入输出作为整个对象的输入输出。

  这里的模型也不一定是一个 ONNX 网络，也可能是一些函数，比方说在 GPT
  中把本轮的输出连着之前轮数的输出作为本轮的模型输入的情景。
  「对输出的处理」也作为一个结点。

  有一个很典型的应用场景，比方说 Graph Γ 有三个输入，两个模型；
  就像 (a, b) -> A -> o1; (b, c) -> B -> o2
  当我对 a 进行修改，我只需要调用模型 A 再重新生成即可，这样可以显著的减少额外的消耗、
  加强输出的效率。

  计划最后与 `DiffSinger.Port.Serving` 对接的就是这类模块或是其进一步抽象。
  """
  alias DiffSinger.Graph
  # use :digraph

  @type t :: %__MODULE__{
    config: any(),
    nodes: %{atom() => any()},
    edges: [any()],
    ports: [any()],
  }
  defstruct [:config, :nodes, :edges, :ports]

  @doc """
  创建一个空白的 `Graph` 。
  """
  def blank(), do: %__MODULE__{
    config: %{graph: :digraph.new()},
    nodes: %{},
    edges: [],
    ports: []
  }

  def add_node(graph = %__MODULE__{}, %Graph.Node{name: node_name} = new_node) do
    # Add node validation.
    # Add build edges.
    %{graph | nodes: %{graph.nodes | node_name => new_node}}
  end

  # def add_edge(graph = %__MODULE__{})

  # defp cyclin_check(graph = %__MODULE__{})
  # -> config: interpret_edge

  # def build(model_list) do
  # end

  # def show_ports(graph, opts \\ []) do
  # end
end
