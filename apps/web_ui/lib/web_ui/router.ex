defmodule WebUI.Router do
  use WebUI, :router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {WebUI.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", WebUI do
    pipe_through :browser

    get "/", PageController, :home

    live "/temp", Demo
  end

  # 其他的范围也可以使用自定义的 plug 栈。
  # scope "/api", WebUI do
  #   pipe_through :api
  # end

  # 在开发时启用 LiveDashboard
  if Application.compile_env(:web_ui, :dev_routes) do
    # 如果要在生产中使用 LiveDashboard，则应将其置于身份验证之后，
    # 只允许管理员访问。如果你的应用程序还没有管理员专用部分，只要使用
    # SSL（无论如何都应该使用），就可以使用 Plug.BasicAuth 设置一些基本身份验证。
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: WebUI.Telemetry
    end
  end

  # 用于开发以及测试
  unless Mix.env() == :prod do
    scope "/dev", WebUI do
      # 用于在网页端单独展示组件
      get "/components", PageController, :component_present
    end
  end
end
