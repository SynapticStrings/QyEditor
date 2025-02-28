alias QyCore.Recipe.{Step, Graph}

step1 = %Step{
  name: :add,
  name_tuple: {{:i1, :i2}, {:m1}},
  prepare: & &1,
  call: fn {a, b}, _ -> {a + b} end
}

step2 = %Step{
  name: :copy,
  name_tuple: {{:i2}, {:m2}},
  prepare: & &1,
  call: fn {a}, _ -> {a * 2} end
}

step3 = %Step{
  name: :multi,
  name_tuple: {{:m1, :m2}, {:o1}},
  prepare: & &1,
  call: fn {a, b}, _ -> {a * b} end
}

defmodule Step4 do
  def call({input_1, middle_1}, _opts) do
    {input_1 + middle_1 * 2}
  end

  def inject() do
    %Step{name: :add_with_copied_value, name_tuple: {{:i1, :m1}, {:o2}}, prepare: & &1, call: &call/2}
  end
end

# TODO
# Try to add a new step with multiple outputs

step_mapper = %{
  step1.name => step1,
  step2.name => step2,
  step3.name => step3,
  Step4.inject().name => Step4.inject()
}

initial_prams = %{i1: 1, i2: 3, m1: nil, m2: nil, o1: nil}

mannual_operate_result =
  initial_prams
  |> Step.exec(step1)
  |> Step.exec(step2)
  |> Step.exec(step3)
  |> Step.exec(Step4.inject())
  |> IO.inspect(label: :mannual_load)

### USING GRAPH TO CONNECT NODE

s =
  [step1, step2, step3, Step4.inject()]
  # Shuffle the list to avoid the order of the list
  |> Enum.shuffle()
  |> Graph.build_conn_from_steps()
  |> IO.inspect(label: :graph_dict)

_g =
  s
  |> Graph.get_graph_from_struct()
  |> IO.inspect(label: :graph)

### GET ORDER THE EXECUTE

{:ok, inner} = Graph.get_execution_order(s)

IO.inspect(inner, label: :order)

automatic_running_result =
  Enum.reduce(inner, initial_prams,
    fn step, acc ->
      Step.exec(acc, step_mapper[step])
    end
  )
  |> IO.inspect(label: :running)

if automatic_running_result == mannual_operate_result do
  IO.puts("Success!")
end
