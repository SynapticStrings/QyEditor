defmodule WebUI.Application do
  # 访问 https://hexdocs.pm/elixir/Application.html
  # 可查看更多关于 OTP 应用的信息
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      WebUI.Telemetry,
      # 通过调用 WebUI.Worker.start_link(arg) 来启动工作进程
      # {WebUI.Worker, arg},
      # 通常把开始处理请求的进程放在最后一个条目
      WebUI.Endpoint,
      {Phoenix.PubSub, name: WebUI.PubSub}
    ]

    # 访问 https://hexdocs.pm/elixir/Supervisor.html
    # 去查阅其他的策略以及所支持的选项
    opts = [strategy: :one_for_one, name: WebUI.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # 当应用更新时告诉 Phoenix 更新端点的配置。
  @impl true
  def config_change(changed, _new, removed) do
    WebUI.Endpoint.config_change(changed, removed)
    :ok
  end
end
