defmodule DiffSinger.Graph.Edge do
  alias DiffSinger.Graph
  ## Options
  # name, type
  # path: {from_port, to_port}
  # allow_mannual_input: true/false
  # if true, graph will has a vitural injectable port at `to_port` side
  ## Content
  # content
  @type t :: %__MODULE__{
    name: atom(),
    type: any(),
    path: {Graph.Port.t(), Graph.Port.t()},
    allow_mannual_input: boolean(),
    content: any()
  }
  defstruct [:name, :type, :path, :allow_mannual_input, :content]

  def validate(_from, _to), do: true

  def build(_from, _to, _opts \\ []), do: %__MODULE__{}
end
