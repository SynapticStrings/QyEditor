defmodule QyCore.Recipe do
  @moduledoc """
  菜谱可以包括单步的操作，也可以是制作食物的整个过程，所以这里就等同于「操作」。

  其灵感来源于 [Plug](https://hexdocs.pm/plug/readme.html) 。
  """

  alias QyCore.Recipe

  @spec execute(any(), [{Recipe.Step.t(), Recipe.Step.options()}]) :: any()
  def execute(sector_init, [{%Recipe.Step{}, _} | _] = steps) do
    Enum.reduce(steps, sector_init, fn {step, opts}, sector_current ->
      Recipe.Step.exec(sector_current, step, opts)
    end)
  end

  @spec execute(any(), [Recipe.Step.t()], Recipe.Step.options()) :: any()
  def execute(sector_init, [%Recipe.Step{} | _] = steps, opts) do
    Enum.reduce(steps, sector_init, fn step, sector_current ->
      Recipe.Step.exec(sector_current, step, opts)
    end)
  end
end
