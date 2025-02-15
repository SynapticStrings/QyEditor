defmodule QyCore.Recipe.Graph do
  alias QyCore.Recipe.{Step, Graph}

  @type t :: %__MODULE__{
          vertex: [atom()] | [],
          orphans: [atom()] | [],
          input_port: [atom()] | [],
          output_port: [atom()] | [],
          edge: [atom()] | []
        }
  defstruct vertex: [], orphans: [], input_port: [], output_port: [], edge: []

  @spec get_step_from_vertex(atom(), [Step.t()]) :: Step.t() | nil
  def get_step_from_vertex(name, steps), do: Enum.find(steps, &(&1.name == name))

  @spec build_conn_from_steps([Step.t()]) :: Graph.t()
  def build_conn_from_steps([%Step{}] = steps) do
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

        {1, _} ->
          # 如果是边的话
          {name, :edge, Enum.map(as_to, &{&1, Enum.at(as_from, 0)})}

        _ ->
          {name, :error}
      end
    end)
    |> Enum.reduce(%{orphans: [], input_port: [], output_port: [], edge: []}, &update_format/2)
    |> Map.merge(%{vertex: Enum.map(steps, & &1.name)})
    |> then(&struct!(__MODULE__, &1))
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

  @spec get_graph_from_struct(Graph.t(), :digraph.graph()) :: :digraph.graph()
  def get_graph_from_struct(%__MODULE__{} = graph_dict, graph \\ :digraph.new([])) do
    Enum.map(graph_dict.vertex, &:digraph.add_vertex(graph, &1))
    Enum.map(graph_dict.input_port, &:digraph.add_vertex(graph, &1))
    Enum.map(graph_dict.output_port, &:digraph.add_vertex(graph, &1))
    Enum.map(graph_dict.edge, fn {from, to} -> :digraph.add_edge(graph, from, to) end)

    graph
  end
end
