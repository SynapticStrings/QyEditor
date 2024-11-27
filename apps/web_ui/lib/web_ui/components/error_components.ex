defmodule WebUI.ErrorComponents do
  @parent __MODULE__ |> Module.split() |> Enum.drop(-1) |> Module.concat()
  @core Module.concat(@parent, CoreComponents)

  defdelegate error(assigns), to: @core

  defdelegate translate_error(params_tuple), to: @core

  defdelegate translate_errors(errors, field), to: @core
end
