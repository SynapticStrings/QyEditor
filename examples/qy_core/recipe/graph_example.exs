# alias QyCore.Param
alias QyCore.Recipe.{Step, Graph}

step1 = %Step{
  name: :step1,
  name_tuple: {{:i1, :i2}, {:m1}},
  init: & &1,
  call: fn {a, b}, _ -> {a + b} end
}

step2 = %Step{
  name: :step2,
  name_tuple: {{:i2}, {:m2}},
  init: & &1,
  call: fn {a}, _ -> {a * 2} end
}

step3 = %Step{
  name: :step3,
  name_tuple: {{:m1, :m2}, {:o1}},
  init: & &1,
  call: fn {a, b}, _ -> {a * b} end
}

defmodule Step4 do
  def call({input_1, middle_1}, _opts) do
    {input_1 + middle_1 * 2}
  end

  def inject() do
    %Step{name: :step4, name_tuple: {{:i1, :m1}, {:o2}}, init: & &1, call: &call/2}
  end
end

%{i1: 1, i2: 3, m1: nil, m2: nil, o1: nil}
|> Step.exec(step1)
|> Step.exec(step2)
|> Step.exec(step3)
|> Step.exec(Step4.inject())
|> IO.inspect(label: :mannual_load)

### USING GRAPH TO CONNECT NODE

g =
  [step1, step2, step3, Step4.inject()]
  |> Graph.build_conn_from_steps()
  # |> IO.inspect(label: :graph_dict)
  |> Graph.get_graph_from_struct()
  # |> IO.inspect(label: :graph)

Graph.Helper.has_cycle?(g) |> IO.inspect(label: :cycle?)

:digraph_utils.topsort(g) |> IO.inspect(label: :topsort)

:digraph_utils.components(g) |> IO.inspect(label: :components)
