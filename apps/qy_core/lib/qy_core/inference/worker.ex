defmodule QyCore.Inference.Worker do
  @moduledoc """
  ...
  """
  # use GenServer

  @type request_payload :: {}

  @type responce_payload :: {:partial, any()} | {:end, term()}

  @type error_payload :: {:error, term()}
end
