defmodule QyFlow.MixProject do
  use Mix.Project

  def project do
    [
      app: :qy_flow,
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

  # 想要获得更多信息可运行 "mix help compile.app" 。
  def application do
    [
      extra_applications: [:logger],
      mod: {QyFlow.Application, []}
    ]
  end

  # 运行 "mix help deps" 可学习依赖项的相关信息。
  defp deps do
    [
      {:gen_stage, "~> 1.2"},
      {:qy_core, git: "https://github.com/SynapticStrings/QyCore.git", branch: "core"}
    ]
  end
end
