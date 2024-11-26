defmodule DiffSinger.Model.Acoustic do
  @moduledoc false

  @type input_spec :: %{
    tokens: Nx.t(),
    languages: Nx.t()
  }
end
