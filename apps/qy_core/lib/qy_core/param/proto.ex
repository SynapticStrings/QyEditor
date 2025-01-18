defmodule QyCore.Param.Proto do
  @moduledoc """
  用于下游程序编写参数的检验与实现相关逻辑的模块。

  可能会批量生成相关模块。

  e.g.

      for {name, quoted} <- param_factory(bla_bla) do
        Module.create(name, quoted)
      end

  ### Example

      iex> defmodule MyApp.Param.Pitch do
      ...>   use QyCore.Param.Proto, type: :time_seq, name: :pitch
      ...>
      ...>   contraint do
      ...>     validate _pitch >= 0.0, or: :pitch_only_allowed_more_than_zero
      ...>   end
      ...> end
  """

  # alias QyCore.Param

  # Meta of params
  defstruct [
    :name,
    :type
  ]

  @doc false
  defmacro __using__(_opts) do
    # 获取当前模块的基本信息
    # e.g. 模块的名称、参数类型
    # 获取检验相关的逻辑
    # 实现 struct
    # 实现一些函数
  end
end
