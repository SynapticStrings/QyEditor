defmodule DiffSinger.Graph.Port do
  alias DiffSinger.Graph
  # name
  # role: input, output
  # type
  # attached
  @type port_name :: atom()
  @type t :: %__MODULE__{
    name: port_name(),
    type: any(),
    role: :input | :output,
    from: Graph.Node.node_name()
  }
  defstruct [:name, :type, :role, :from]

  def as_input?(%__MODULE__{role: :input}), do: true
  def as_input?(%__MODULE__{role: :output}), do: false

  def connectable?(%__MODULE__{} = port_1, %__MODULE__{} = port_2, type_validate_func)
      when is_function(type_validate_func) do
    as_input?(port_1) != as_input?(port_2)
    and type_validate_func.(port_1) == type_validate_func.(port_2)
  end
  def connectable?(%__MODULE__{} = port_1, %__MODULE__{} = port_2) do
    port_1.type == port_2.type and as_input?(port_1) != as_input?(port_2)
  end

  def attached_from(%__MODULE__{} = port) do
    port.from
  end

  def build_edge_path(port_1, port_2) when connectable?(port_1, port_2) do
    # from, to
    case port_1.role do
      :input -> {port_1, port_2}
      :output -> {port_2, port_1}
    end
  end
  def build_edge_path(_p1, _p2), do: {:error, :does_not_connectable}
end
