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

# 配置 Elixir 日志
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]
