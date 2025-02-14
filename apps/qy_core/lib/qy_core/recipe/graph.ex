defmodule QyCore.Recipe.Graph do
  # Set recipes as DAG

  # 首先定义两类类型，以及图的形式

  def extract_vertex(%QyCore.Recipe.Step{} = step), do: {step.name, step.name_tuple}

  def get_step_from_vertex(name, steps), do: Enum.find(steps, &(&1.name == name))

  def get_vertex(steps), do: Enum.map(steps, &extract_vertex/1)

  def get_edges_ports_and_orphans(steps) do
    steps
    |> get_vertex()
    |> Enum.map(fn {n, {i, o}} -> {n, {Tuple.to_list(i), Tuple.to_list(o)}} end)
    |> do_get_edges(steps, [], %{input: [], output: []}, [])
    # 完全可以换种做法，根据 vertex 得到所有的 edges
    # 再进行递归 =>
    #   {0, 1} -> 输出, {step, 输出}
    #   {1, 0} -> 输入, {输入, step}
    #   {1, n} -> 普通的边，对应装载即可
    #   {0, 0} -> 孤儿边
    #   {n, _} -> 报错即可
    #
  end

  # 用个小递归
  defp do_get_edges([], _, edges, ports, orphans), do: {edges, ports, orphans}

  defp do_get_edges(
         [{name, {from, to}} | rest],
         steps,
         edges,
         %{input: inputs, output: outputs},
         orphans
       ) do
    maybe_upstream =
      Enum.reduce(from, [], &check_same_edge(&1, rest, :current_as_input) ++ &2)

    maybe_downstream =
      Enum.reduce(to, [], &check_same_edge(&1, rest, :current_as_output) ++ &2)

    IO.inspect(inputs, label: :i)
    IO.inspect(outputs, label: :o)

    case {maybe_upstream, maybe_downstream} do
      {[], []} ->
        # {无, 无} => 丢进  orphans 里
        do_get_edges(
          # Enum.reduce(from ++ to, rest, &delete_edge_in_rest/2),
          rest,
          steps,
          edges,
          %{input: inputs, output: outputs},
          [get_step_from_vertex(name, steps) | orphans]
        )

      {_, []} ->
        # {有, 无} => 输出端
        do_get_edges(
          Enum.reduce(from ++ to, rest, &delete_edge_in_rest/2),
          steps,
          edges,
          %{input: inputs, output: [get_step_from_vertex(name, steps) | outputs]},
          orphans
        )

      {[], _} ->
        # {无, 有} => 输入端
        do_get_edges(
          Enum.reduce(from ++ to, rest, &delete_edge_in_rest/2),
          steps,
          edges,
          %{input: [get_step_from_vertex(name, steps) | inputs], output: outputs},
          orphans
        )

      {_from_step_list, _to_step_list} ->
        # {有, 有} => 加上对应的边
        # edge 形如 {name, from_step, to_step}
        # name 就是那个原子本身
        do_get_edges(
          Enum.reduce(from ++ to, rest, &delete_edge_in_rest/2),
          steps,
          edges ++ {},
          %{input: inputs, output: outputs},
          orphans
        )
    end
  end

  defp check_same_edge(current, rest, :current_as_input) do
    rest
    |> Enum.filter(fn {_, {_, maybe_upstream}} -> current in maybe_upstream end)
    |> case do
      [] -> []
      inner -> Enum.map(inner, fn {name, _} -> name end)
    end
  end

  defp check_same_edge(current, rest, :current_as_output) do
    rest
    |> Enum.filter(fn {_, {maybe_downstream, _}} -> current in maybe_downstream end)
    |> case do
      [] -> []
      inner -> Enum.map(inner, fn {name, _} -> name end)
    end
  end

  defp delete_edge_in_rest(target, rest) do
    Enum.map(rest, fn {name, {i, o}} ->
      {name, {
        if target in i do
          List.delete(i, target)
        else
          i
        end,
        if target in o do
          List.delete(o, target)
        else
          o
        end
      }}
    end)
  end

  ## 合法性检查
  # 拓扑排序
  # 独立节点检查
  # 图的输入输出
end
