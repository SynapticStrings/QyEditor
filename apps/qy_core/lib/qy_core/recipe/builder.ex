defmodule QyCore.Recipe.Builder do
  # 附带了简单的检查以及错误处理的步骤整合
  # 包括如 plug 般整合到一个函数以及更复杂的调度
  # 后者可能由 qy_flow 或是什么的来实现

  # 用法
  # pipe(opts) do
  #   step step_1, opts
  #   step step_2, opts
  #   ...
  # end

  # compile like plug
  # def compile(_params, _steps, _opts) do
  #   ...
  # end
end
