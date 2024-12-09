import Config

# 我们在开发时禁用缓存，并且启用 debug 以及代码重载。
#
# 观察者配置可用于运行应用程序的外部观察者。例如，我们可以用它来捆绑 .js 和 .css 源。
config :web_ui, WebUI.Endpoint,
  # 绑定到环回 IPv4 地址可防止其他机器访问。
  # 如果想要从其他机器访问请改成 `ip: {0, 0, 0, 0}` 。
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "gwgQ7SCIOBoq21rmO9HMS/p29X7w+3uT0V0w0AF6RhY9kU+97ci/D/dn69dYIYXF",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:web_ui, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:web_ui, ~w(--watch)]}
  ]

# ## SSL 支持
#
# 为了在开发过程中使用 HTTPS，可通过运行以下 Mix 任务生成自签名证书：
#
# mix phx.gen.cert
#
# 运行 `mix help phx.gen.cert` 获取更多信息。
#
# 上面的 `http:` 配置可替换为
#
#   https: [
#     port： 4001,
#     cipher_suite: :strong,
#     keyfile: "priv/cert/selfsigned_key.pem",
#     certfile: "priv/cert/selfsigned.pem"
#   ],
#
# 如果需要，可配置 `http:` 和 `https:` 密钥，以便在不同端口上运行 http 和 https 服务器。

# 为浏览器端的重载监视静态资源与模板。
config :web_ui, WebUI.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/web_ui/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

# 启用开发路由下的控制板和邮箱（邮箱我没用）
config :web_ui, dev_routes: true

# 从其他项目复制过来的
# 如果有问题注释掉

# 开发环境的日志中不包含元数据以及时间戳
config :logger, :console, format: "[$level] $message\n"

# 为加快开发环境的编译在运行时初始化 plug
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  # 将 HEEx 调试注释作为 HTML 注释包含在渲染的标记中
  debug_heex_annotations: true,
  # 启用有用但可能昂贵的运行时检查
  enable_expensive_runtime_checks: true

# 在开发环境设置更高的栈跟踪。但是在生产中不要这么设置，因为性能开销太大。
config :phoenix, :stacktrace_depth, 20
