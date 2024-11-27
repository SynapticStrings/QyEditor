defmodule WebUI.ShowComponents do
  @parent __MODULE__ |> Module.split() |> Enum.drop(-1) |> Module.concat()
  @core Module.concat(@parent, CoreComponents)

  defdelegate header(assigns), to: @core

  defdelegate table(assigns), to: @core

  defdelegate list(assigns), to: @core

  defdelegate back(assigns), to: @core

  defdelegate icon(assigns), to: @core

  alias Phoenix.LiveView.JS

  defdelegate show(js \\ %JS{}, selector), to: @core

  defdelegate hide(js \\ %JS{}, selector), to: @core
end
