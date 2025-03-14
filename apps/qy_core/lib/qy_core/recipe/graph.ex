defmodule QyCore.Recipe.Graph do
  @moduledoc """
  主要是关于将一系列的 `%QyCore.Recipe.Step{}`
  组合起来的图结构以及对象（基于 `:digraph`）。
  """

  alias QyCore.Recipe.{Step, Graph}

  @type t :: %__MODULE__{
          vertex: [atom()] | [],
          orphans: [atom()] | [],
          input_port: [atom()] | [],
          output_port: [atom()] | [],
          edge: [atom()] | []
        }
  defstruct vertex: [], orphans: [], input_port: [], output_port: [], edge: []

  @doc """
  从一系列的步骤中构建一个图（`%Graph{}` 结构）。
  """
  @spec build_conn_from_steps([Step.t()]) :: Graph.t()
  defdelegate build_conn_from_steps(steps), to: Graph.Builder

  @doc """
  从图结构中得到 `:digraph.graph()` 对象。
  """
  @spec get_graph_from_struct(Graph.t(), :digraph.graph()) :: :digraph.graph()
  defdelegate get_graph_from_struct(graph_dict, graph \\ :digraph.new([])), to: Graph.Builder

  @spec get_execution_order(Graph.t()) :: {:ok, [atom()]} | {:error, :cyclic}
  def get_execution_order(%Graph{} = graph) do
    g = get_graph_from_struct(graph)

    # 仅对步骤节点（vertex）进行排序，过滤掉输入输出端口
    vertex_only_graph =
      :digraph_utils.subgraph(g, graph.vertex)

    case :digraph_utils.topsort(vertex_only_graph) do
      false -> {:error, :cyclic}
      order -> {:ok, order}
    end
  end

  @spec get_step_from_vertex(atom(), [Step.t()]) :: Step.t() | nil
  def get_step_from_vertex(name, steps), do: Enum.find(steps, &(&1.name == name))

end

defmodule QyCore.Recipe.Graph.Builder do
  alias QyCore.Recipe.{Step, Graph}

  def build_conn_from_steps(steps) do
    steps
    |> Enum.map(& &1.name_tuple)
    |> Enum.reduce(
      [],
      fn {i, o}, acc -> Tuple.to_list(i) ++ Tuple.to_list(o) ++ acc end
    )
    |> Enum.uniq()
    |> Enum.map(&{&1, get_steps_from_edge(&1, steps)})
    |> Enum.map(fn {name, %{as_from: as_from, as_to: as_to}} ->
      case {length(as_from), length(as_to)} do
        {0, 0} ->
          {name, :orphan}

        {0, 1} ->
          # 关于输入输出：
          # port + 名字
          # edge: {from_step, to_port}
          {name, :output, {Enum.at(as_to, 0), name}}

        {_, 0} ->
          {name, :input, Enum.map(as_from, &{name, &1})}

        {_, 1} ->
          # 如果是边的话
          {name, :edge, Enum.map(as_from, &{Enum.at(as_to, 0), &1})}

        _context ->
          {name, :error, :cyclic}
      end
    end)
    |> Enum.reduce(
      %{orphans: [], input_port: [], output_port: [], edge: []},
      &update_format/2
    )
    |> Map.merge(%{vertex: Enum.map(steps, & &1.name)})
    |> then(&struct!(Graph, &1))
  end

  defp get_steps_from_edge(edge_name, steps) do
    %{
      as_from:
        Enum.filter(steps, fn step ->
          {from, _} = step.name_tuple
          edge_name == from or edge_name in Tuple.to_list(from)
        end)
        |> Enum.map(fn %Step{name: name} -> name end),
      as_to:
        Enum.filter(steps, fn step ->
          {_, to} = step.name_tuple
          edge_name == to or edge_name in Tuple.to_list(to)
        end)
        |> Enum.map(fn %Step{name: name} -> name end)
    }
  end

  defp update_format({name, :orphan}, items) do
    %{items | orphans: [name | items[:orphans]]}
  end

  defp update_format({name, :output, edge}, items) do
    %{items | output_port: [name | items[:output_port]], edge: [edge | items[:edge]]}
  end

  defp update_format({name, :input, edges}, items) do
    %{items | input_port: [name | items[:input_port]], edge: edges ++ items[:edge]}
  end

  defp update_format({_name, :edge, edges}, items) do
    %{items | edge: edges ++ items[:edge]}
  end

  defp update_format({name, :error, reason}, items) do
    raise "Catch an error buring #{name} with #{inspect(reason)} when process #{inspect(items)}"
  end

  def get_graph_from_struct(%Graph{} = graph_dict, graph \\ :digraph.new([])) do
    Enum.map(graph_dict.vertex, &:digraph.add_vertex(graph, &1))
    Enum.map(graph_dict.input_port, &:digraph.add_vertex(graph, &1))
    Enum.map(graph_dict.output_port, &:digraph.add_vertex(graph, &1))
    Enum.map(graph_dict.edge, fn {from, to} -> :digraph.add_edge(graph, from, to) end)

    graph
  end
end

defmodule QyCore.Recipe.Graph.Helper do
  @moduledoc """
  主要是一些 utilities 的存在。
  """

  # 最大的度数
  # 先不考虑边或节点的权重
end
