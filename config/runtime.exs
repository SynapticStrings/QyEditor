import Config

if config_env() == :prod do
  import Config

  # 密钥库用于签署/加密 cookie 和其他秘密。 config/dev.exs 和 config/test.exs
  # 中使用的是默认值，但你想在生产环境中使用不同的值，而且你很可能不想在版本控制中出现
  # 该值，因此我们使用环境变量来代替。
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  config :web_ui, WebUI.Endpoint,
    http: [
      # 启用 IPv6 且绑定所有接口。
      # 如果只想要本地访问请改成 {0, 0, 0, 0, 0, 0, 0, 1} 。
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: String.to_integer(System.get_env("PORT") || "4000")
    ],
    secret_key_base: secret_key_base

  # ## 使用 releases
  #
  # 如果要进行 OTP 发布，则需要指示 Phoenix 启动每个相关端点：
  #
  #     config :web_ui, WebUI.Endpoint, server: true
  #
  # 然后，你就可以调用 `mix release` 来组装发布。请参阅
  # `mix help release` 获取更多信息。

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :web_ui, WebUI.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :web_ui, WebUI.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.
end
