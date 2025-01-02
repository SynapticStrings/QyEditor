defmodule QyMusic.MixProject do
  use Mix.Project

  def project do
    [
      app: :qy_music,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # 想要获得更多信息可运行 `mix help compile.app` 。
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # 就像是 Phoenix.HTML
  # 虽然名字是 QyMusic ，但是其不依赖于 QyCore
  defp deps do
    []
  end
end
