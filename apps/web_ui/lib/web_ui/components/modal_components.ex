defmodule WebUI.ModalComponents do
  @parent __MODULE__ |> Module.split() |> Enum.drop(-1) |> Module.concat()
  @core Module.concat(@parent, CoreComponents)

  defdelegate modal(assigns), to: @core

  alias Phoenix.LiveView.JS

  defdelegate show_modal(js \\ %JS{}, id), to: @core

  defdelegate hide_modal(js \\ %JS{}, id), to: @core
end
