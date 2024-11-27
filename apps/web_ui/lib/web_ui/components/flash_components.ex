defmodule WebUI.FlashComponents do
  @parent __MODULE__ |> Module.split() |> Enum.drop(-1) |> Module.concat()
  @core Module.concat(@parent, CoreComponents)

  defdelegate flash(assigns), to: @core

  defdelegate flash_group(assigns), to: @core
end
