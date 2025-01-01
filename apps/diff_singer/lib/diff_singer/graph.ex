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

  # 抄袭的 Livebook.Utils.Graph
  # 后续会基于和 Livebook 的不同进行修改
  # 简单来说这里的上下游是此节点是否需要来自模型的输出作为输入的程度

  @typedoc """
  自下而上的图形表示法，编码为子女对父母条目的映射。
  """
  @type t() :: %{node_id => node_id | nil}

  @type t(node_id) :: %{node_id => node_id | nil}

  @type node_id :: term()

  @doc """
  查找节点 `from_id` 和 `to_id` 之间的路径。

  如果路径存在，将返回一个自上而下的节点列表，其中包括极端节点。否则，将返回一个空列表。
  """
  @spec find_path(t(), node_id(), node_id()) :: list(node_id())
  def find_path(graph, from_id, to_id) do
    find_path(graph, from_id, to_id, [])
  end

  defp find_path(_graph, to_id, to_id, path), do: [to_id | path]
  defp find_path(_graph, nil, _to_id, _path), do: []

  defp find_path(graph, from_id, to_id, path),
    do: find_path(graph, graph[from_id], to_id, [from_id | path])

  @doc """
  查找图的离开节点，即没有子节点的节点。
  """
  @spec leaves(t()) :: list(node_id())
  def leaves(graph) do
    children = MapSet.new(graph, fn {key, _} -> key end)
    parents = MapSet.new(graph, fn {_, value} -> value end)
    MapSet.difference(children, parents) |> MapSet.to_list()
  end

  @doc """
  还原图中每条自上而下的路径。

  返回累加器列表，图中每片叶子对应一个累加器，没有特定顺序。
  """
  @spec reduce_paths(t(), acc, (node_id(), acc -> acc)) :: acc when acc: term()
  def reduce_paths(graph, acc, fun) do
    leaves = leaves(graph)
    cache = do_reduce(graph, leaves, acc, fun, %{})
    Enum.map(leaves, &cache[&1])
  end

  defp do_reduce(_graph, [], _initial_acc, _fun, cache), do: cache

  defp do_reduce(graph, [cell_id | cell_ids], initial_acc, fun, cache) do
    if parent_id = graph[cell_id] do
      case cache do
        %{^parent_id => acc} ->
          acc = fun.(cell_id, acc)
          cache = put_in(cache[cell_id], acc)
          do_reduce(graph, cell_ids, initial_acc, fun, cache)

        _ ->
          do_reduce(graph, [parent_id, cell_id | cell_ids], initial_acc, fun, cache)
      end
    else
      acc = fun.(cell_id, initial_acc)
      cache = put_in(cache[cell_id], acc)
      do_reduce(graph, cell_ids, initial_acc, fun, cache)
    end
  end
end
