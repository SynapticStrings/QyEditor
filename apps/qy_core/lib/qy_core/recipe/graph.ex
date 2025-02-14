defmodule QyCore.Recipe.Graph do
  # Set recipes as DAG

  # 首先定义两类类型，以及图的形式

  def extract_vertex(%QyCore.Recipe.Step{} = step), do: {step.name, step.name_tuple}

  def get_step_from_vertex(name, steps), do: Enum.find(steps, &(&1.name == name))

  def get_vertex(steps), do: Enum.map(steps, &extract_vertex/1)

  # TODO: fix error
  # vertex 是端口或 step 的 name
  # edge 是 step 的 input_or_output_keyword
  def build_conn(steps, graph \\ :digraph.new([])) do
    vertex = steps
    |> get_vertex()

    vertex
    |> Enum.reduce([], fn {_, {i, o}}, acc -> Tuple.to_list(i) ++ Tuple.to_list(o) ++ acc end)
    |> Enum.uniq()
    |> Enum.map(&({&1, get_steps_from_edge(&1, steps)}))
    |> Enum.map(
      fn {name, %{as_from: as_from, as_to: as_to}} ->
        case {length(as_from), length(as_to)} do
          {0, 0} -> {name, :orphan}
          {0, 1} ->
            # 关于输入输出：
            # port + 名字
            # edge: {from_step, to_port}
            {name, :output, {Enum.at(as_to, 0), name}}
          {_, 0} ->
            {name, :input, Enum.map(as_from, &({name, &1}))}
          {1, _} ->
            # 如果是边的话
            {name, :edge, Enum.map(as_to, &({&1, Enum.at(as_from, 0)}))}
          _ -> {name, :error}
        end
      end
    )
    |> Enum.reduce(%{orphans: [], input_port: [], output_port: [], edge: []}, &update_format/2)
    |> Map.merge(%{vertex: vertex})
    |> do_graph(graph)
  end

  defp get_steps_from_edge(edge_name, steps) do
    %{
      as_from:
        Enum.filter(steps, fn step ->
          {from, _} = step.name_tuple
          edge_name == from or edge_name in Tuple.to_list(from)
        end),
      as_to:
        Enum.filter(steps, fn step ->
          {_, to} = step.name_tuple
          edge_name == to or edge_name in Tuple.to_list(to)
        end)
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

  defp do_graph(graph_dict, graph) do
    Enum.map(graph_dict[:vertex], &:digraph.add_vertex(graph, &1))
    Enum.map(graph_dict[:input_port], &:digraph.add_vertex(graph, &1))
    Enum.map(graph_dict[:output_port], &:digraph.add_vertex(graph, &1))
    Enum.map(graph_dict[:edge], fn {from, to} -> :digraph.add_edge(graph, from, to) end)
  end

  ## 合法性检查
  # 拓扑排序
  # 独立节点检查
  # 图的输入输出
end
