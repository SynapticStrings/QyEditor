defmodule QyCore.Recipe do
  @moduledoc """
  定义一个处理流程（菜谱）。
  """

  alias QyCore.Recipe.Step

  @type t :: %__MODULE__{
          steps: [Step.t()],
          name: atom() | nil,
          opts: keyword()
        }

  defstruct steps: [], name: nil, opts: []

  def new(steps, opts \\ []) do
    %__MODULE__{
      steps: steps,
      name: Keyword.get(opts, :name),
      opts: opts
    }
  end

  # def assign_options(steps, options) do
end
