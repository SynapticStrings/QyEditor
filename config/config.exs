# 通过 Config 模块的帮助，这个文件负责配置你的伞项目以及【所有的应用】
# 以及其依赖。
#
# 请注意，伞项目中的所有应用程序都共享相同的配置和依赖关系，这也是它们使用
# 相同配置文件的原因。如果你希望每个应用程序有不同的配置或依赖关系，最好将
# 这些应用程序移出保护伞。
import Config

# 实例配置：
#
#     config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]
#

config :web_ui,
  namespace: WebUI,
  generators: [context_app: false]

# 配置端点
config :web_ui, WebUI.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: WebUI.ErrorHTML, json: WebUI.ErrorJSON],
    layout: false
  ],
  pubsub_server: WebUI.PubSub,
  live_view: [signing_salt: "YC6yG9Jt"]

# 配置 esbuild （需要版本号）
config :esbuild,
  version: "0.17.11",
  web_ui: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../apps/web_ui/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# 配置 tailwind （需要版本号）
config :tailwind,
  version: "3.4.3",
  web_ui: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../apps/web_ui/assets", __DIR__)
  ]

# 配置 Elixir 日志
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# 在 Phoenix 中使用 Jason 来解析 JSON
config :phoenix, :json_library, Jason

# 将简体中文设置为缺省语言
config :gettext,
  default_locale: "zh_CN",
  locales: ~w(en zh_CN)

# 依据环境导入不同的配置，这一行必须在文件的最后因此其他配置其可以覆写上面的。
import_config "#{config_env()}.exs"
