defmodule QyCore.Executor do
  @callback execute(QyCore.Recipe.t(), [QyCore.Param.t()], keyword()) ::
              {:ok, map()} | {:error, term()}
end
