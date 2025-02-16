alias QyCore.Recipe.Step

defmodule Step4 do
  def call({input_1, middle_1}, _opts) do
    {input_1 + middle_1 * 2}
  end

  def inject() do
    %Step{name: :step4, name_tuple: {{:i1, :m1}, {:o2}}, prepare: & &1, call: &call/2}
  end
end

defmodule SimpleStepStack do
  step1 = %Step{
    name: :step1,
    name_tuple: {{:i1, :i2}, {:m1}},
    prepare: & &1,
    call: fn {a, b}, _ -> {a + b} end
  }

  step2 = %Step{
    name: :step2,
    name_tuple: {{:i2}, {:m2}},
    prepare: & &1,
    call: fn {a}, _ -> {a * 2} end
  }

  step3 = %Step{
    name: :step3,
    name_tuple: {{:m1, :m2}, {:o1}},
    prepare: & &1,
    call: fn {a, b}, _ -> {a * b} end
  }

  step4 = Step4.inject()

  def stack(), do: [step1, step2, step3, step4]
end
