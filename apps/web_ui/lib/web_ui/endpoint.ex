defmodule WebUI.Endpoint do
  # 关于 Endpoint 这个词的翻译，好像拿不准，就以「端点」来定了
  use Phoenix.Endpoint, otp_app: :web_ui

  # Session 将在 cookie 中保存并被签名，这意味着它的内容可以被阅读
  # 却无法被篡改。 如果你想要加密的话可以设置 :encryption_salt 。
  @session_options [
    store: :cookie,
    key: "_web_ui_key",
    signing_salt: "huSFnkeo",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  # 将 "priv/static" 目录下的文件映射到 "/" 。
  #
  # 在生产环境下，如果你在运行 phx.digest 你应该把 gzip 设为真。
  plug Plug.Static,
    at: "/",
    from: :web_ui,
    gzip: false,
    only: WebUI.static_paths()

  # 代码重载能够在你的端点的 :code_reloader 配置被显式地启用。
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug WebUI.Router
end
