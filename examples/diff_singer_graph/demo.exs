# alias DiffSinger.Graph

porttype_1 = {Nx.Tensor}

defmodule PortType1 do
  defstruct []
end

defmodule PortType2 do
  defstruct []
end

# 问题：怎么解决循环调用呢？
# A -> B -> A
_raw_models = [
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

# 约定俗成是模型的端口名字可能会一样
