# alias DiffSinger.Graph

defmodule PortType1 do
  defstruct []
end

defmodule PortType2 do
  defstruct []
end

# 问题：怎么解决循环调用呢？
# A -> B -> A
raw_models = [
  model_1: %{
    port_1: {:input, PortType1},
    port_2: {:input, PortType1},
    port_3: {:output, PortType2}
  },
  model_2: %{
    port_3: {:input, PortType2},
    port_4: {:output, PortType2}
  }
]

get_model = fn model_name -> raw_models[model_name] end

alias DiffSinger.Graph.{Port, Node}
ports_fetcher = fn model -> Enum.map(model,
  fn {port_name, {role, type}} ->%Port{
    name: port_name,
    role: role,
    type: type,
    from: nil
  } end
) end

Node.build(:model_1, get_model.(:model_1), ports_fetcher) |> IO.inspect()

# 约定俗成是模型的端口名字可能会一样
