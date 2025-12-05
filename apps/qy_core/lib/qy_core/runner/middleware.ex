defmodule QyCore.Runner.Middleware do
  @type context :: map()
  @type next_fn :: (context -> {:ok, any()} | {:error, any()})

  @callback call(context, next_fn) :: {:ok, any()} | {:error, any()}
end
