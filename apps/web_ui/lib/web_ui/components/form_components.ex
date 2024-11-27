defmodule WebUI.FormComponents do
  @parent __MODULE__ |> Module.split() |> Enum.drop(-1) |> Module.concat()
  @core Module.concat(@parent, CoreComponents)

  defdelegate simple_form(assigns), to: @core

  defdelegate button(assigns), to: @core

  defdelegate input(assigns), to: @core

  defdelegate label(assigns), to: @core
end
