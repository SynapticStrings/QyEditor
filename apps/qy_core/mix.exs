defmodule QyCore.MixProject do
  use Mix.Project

  def project do
    [
      app: :qy_core,
      version: "0.1.3",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ] ++ doc_opts()
  end

  # 想要获得更多信息可运行 `mix help compile.app` 。
  def application do
    [
      extra_applications: [:logger],
      mod: {QyCore.Application, []}
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev], runtime: false},
      {:stream_data, "~> 0.6", only: [:test]}
    ] ++ deps_doc()
  end

  # 文档相关

  defp deps_doc do
    [{:ex_doc, "~> 0.36", only: :dev, runtime: false}]
  end

  defp doc_opts do
    [
      name: "QyCore",
      source_url: "https://github.com/SynapticStrings/QyEditor/tree/main/apps/qy_core",
      docs: &docs/0
    ]
  end

  defp docs do
    extras = []

    groups_for_extras = []

    [
      main: "QyCore",
      extras: ["README.md"] ++ extras,
      groups_for_extras: groups_for_extras
    ]
  end
end
