defmodule QyCore.Recipe do
  # 当前的难点
  # 参数的检查
  # 不同类型参数的转变
  @moduledoc """
  菜谱可以包括单步的操作，也可以是制作食物的整个过程，所以这里就等同于「操作」。

  其灵感来源于 [Plug](https://hexdocs.pm/plug/readme.html) 。

  ## 类型

  和 Plug 一样，也包括函数式以及模块式。

  ### 函数式

  简单来说就是形如如下形式的函数：

      (params, options) :: params

  其中 `params` 是可能会更新的参数的列表或字典，`options` 是一个选项的列表。

  ### 模块式

  对于复杂的操作流程，例如加载一个模型再通过输入的参数来得到对应的结果，就需要实现一个模块。

  ### 复杂工作流的设计

  TODO
  """
end
