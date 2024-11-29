defmodule DiffSinger.Graph.Edge do
  alias DiffSinger.Graph

  @type option_type :: %{
    allow_mannual_input: boolean(),
    # if true, graph will has a vitural injectable port at `to_port` side
    connect_differe_scope: boolean() | nil,
    # two ports at different scopes
  } # | nil

  @default_options %{
    allow_mannual_input: true,
    connect_differe_scope: nil
  }
  @type t :: %__MODULE__{
    name: atom(),
    type: any(),
    path: {from :: Graph.Port.t(), to :: Graph.Port.t()},
    content: any(),
    options: option_type(),
  }
  defstruct [:name, :type, :path, :content, options: @default_options]

  def validate(_from, _to), do: true

  # opts
  # in_same_scope?
  def build(_from, _to, _opts \\ []), do: %__MODULE__{}
end
