# alias QyCore.Param
alias QyCore.Recipe.{Step, Graph}

step1 = %Step{
  name: :step1,
  name_tuple: {{:i1, :i2}, {:m1}},
  init: &(&1),
  call: fn {a, b}, _ -> {a + b} end
}

step2 = %Step{
  name: :step2,
  name_tuple: {{:i2}, {:m2}},
  init: &(&1),
  call: fn {a}, _ -> {a * 2} end
}

step3 = %Step{
  name: :step3,
  name_tuple: {{:m1, :m2}, {:o1}},
  init: &(&1),
  call: fn {a, b}, _ -> {a * b} end
}

%{i1: 1, i2: 3, m1: nil, m2: nil, o1: nil}
|> Step.exec(step1)
|> Step.exec(step2)
|> Step.exec(step3)
|> IO.inspect(label: :mannual_load)

### USING GRAPH TO CONNECT NODE

g = [step1, step2, step3]
  |> Graph.build_conn_from_steps()
  |> IO.inspect(label: :graph_dict)
  |> Graph.get_graph_from_struct()
  |> IO.inspect(label: :graph)

:digraph_utils.components(g) |> IO.inspect()
