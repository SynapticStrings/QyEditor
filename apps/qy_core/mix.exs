defmodule QyCore.MixProject do
  use Mix.Project

  def project do
    [
      app: :qy_core,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # 想要获得更多信息可运行 `mix help compile.app` 。
  def application do
    [
      extra_applications: [:logger],
      mod: {QyCore.Application, []}
    ]
  end

  # 不考虑依赖任何其他非标准库的应用或模块。
  defp deps do
    []
  end
end
