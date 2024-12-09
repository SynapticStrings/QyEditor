import Config

# 我们不需要在测试时运行服务器。
# 如果需要的话，可以启用下面的 `server` 选项。
config :web_ui, WebUI.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "9qBuNlK623tCbJ3HMwvXMGa1ENG/RVnEwgWiOGNUP695VB9GslLoDy25V01qxkbR",
  server: false

## 复制过来而非生成的

# 在测试时只需要输出警告和错误信息
config :logger, level: :warning

# 在运行时初始化 plug ，以加快测试编译速度
config :phoenix, :plug_init_mode, :runtime

# 启用有用但可能昂贵的运行时检查
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
