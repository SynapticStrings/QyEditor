defmodule DiffSinger.Graph.Node do
  alias DiffSinger.Graph

  @type node_name :: atom()
  @type t :: %__MODULE__{
    name: node_name(),
    reference: any(),
    ports: [Graph.Port.t()]
  }
  defstruct [:name, :reference, :ports]

  def build(name, model, ports_fetcher) when is_function(ports_fetcher, 1) do
    # get reference model's ports
    ports = ports_fetcher.(model)

    %__MODULE__{name: name, reference: model, ports: ports}
  end
  def build(name, model, ports) do
    %__MODULE__{name: name, reference: model, ports: ports}
  end

  def run(%__MODULE__{} = node, inputs, execute_func)
      when is_function(execute_func, 2) do
    execute_func.(node, inputs)
  end
end
