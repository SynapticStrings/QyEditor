defmodule QyCore.Recipe do
  @moduledoc """
  ...
  """
  # TODO: ensure name.
  @type params :: [{atom(), QyCore.Param.t()}]

  @callback init(opts :: keyword()) :: keyword()

  @callback call(params(), opts :: keyword()) :: params()
end
