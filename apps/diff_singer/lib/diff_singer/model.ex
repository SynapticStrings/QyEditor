defmodule DiffSinger.Model do
  @moduledoc false

  defstruct [:model, :config]

  defmacro __using__ do
    quote do
      import __MODULE__
    end
  end

  def load_model(path, device \\ [:cpu]) do
    Ortex.load(path, device)
  end
end
