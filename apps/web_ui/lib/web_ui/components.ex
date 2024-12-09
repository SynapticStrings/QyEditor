defmodule WebUI.Components do
  @moduledoc false

  # 通用的导入
  def common do
    quote do
      use Phoenix.Component
      alias Phoenix.LiveView.JS

      use Gettext, backend: WebUI.Gettext
    end
  end

  # 等价于原来的 WebUI.CoreComponents
  def core do
    quote do
      import WebUI.{
        FlashComponents,
        ModalComponents,
        FormComponents,
        ShowComponents,
        ErrorComponents
      }
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
