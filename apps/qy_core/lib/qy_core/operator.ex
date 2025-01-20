defmodule QyCore.Operator do
  # 关于操作的相关模块
  defstruct [:name, :config, :from, :to]

  # 此模块可能会借鉴 Plug
  # 但是和 Plug 不同的是，这里需要在运行时对 Operator 进行增删改查
  # 一个 Operator 可能会有多个 Operator
  # 其他的形式可能时函数或模块
end
