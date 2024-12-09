import Config

# 请注意，我们还包含了缓存清单的路径，其中包含静态文件的摘要版本。
# 该清单由 `mix phx.digest` 任务生成，应在生成静态文件后、
# 启动生产服务器之前运行该任务。
config :web_ui, WebUI.Endpoint,
  url: [host: "example.com", port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json"

# 运行时配置，包括读取环境变量的部分，在 config/runtime.exs 中。
