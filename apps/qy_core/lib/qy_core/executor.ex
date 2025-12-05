defmodule QyCore.Executor do
  @callback execute(QyCore.Recipe.t(), [QyCore.Param.t()], keyword()) ::
              {:ok, [QyCore.Param.t()]} | {:error, term()}
end
