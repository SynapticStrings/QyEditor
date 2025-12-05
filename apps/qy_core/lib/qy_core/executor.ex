defmodule QyCore.Executor do
  # 完整版 step 的最后一个参数就是给 executor 用的
  @callback execute(QyCore.Recipe.t(), [QyCore.Param.t()], keyword()) ::
              {:ok, map()} | {:error, term()}
end
