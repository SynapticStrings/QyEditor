defmodule WebUI do
  @moduledoc """
  定义网络界面（如控制器、组件、通道等）的入口点。

  可在应用程序中通过以下方式被调用：

      use WebUI, :controller
      use WebUI, :html

  下面的定义将在每个控制器、组件等中执行，因此要简洁明了，重点放在 import 、
  use 以及 alias 上。

  【请不要】在下面的 quote 表达式内定义函数。相反，请定义附加模块并在此处导入这些模块。
  """

  # 静态路径
  # `~w` 是 Elixir 中的一个魔符
  # [魔符(Sigil) · Elixir School](https://elixirschool.com/zh-hans/lessons/basics/sigils)
  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # 导入在处理管线里被用到的通用的连接以及控制器的函数
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: WebUI.Layouts]

      import Plug.Conn
      use Gettext, backend: WebUI.Gettext

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {WebUI.Layouts, :app}

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # 导入控制器的便捷函数
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      import WebUI.Gettext, only: [default_lang: 0]

      # 导入渲染 HTML 时常用的帮助模块/函数
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # 规避 HTML 转义的功能
      import Phoenix.HTML
      # UI 组件以及翻译功能
      use WebUI.Components, :core
      use Gettext, backend: WebUI.Gettext

      # 方便生成 JS 命令
      alias Phoenix.LiveView.JS

      # 生成路由以及 ~p 魔符
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: WebUI.Endpoint,
        router: WebUI.Router,
        statics: WebUI.static_paths()
    end
  end

  @doc """
  当被 `use WebUI, :blabla` 时，将特定的控制器/画面/等等发送到用它的地方。
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
