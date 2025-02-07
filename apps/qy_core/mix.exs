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

  # 不考虑依赖任何其他非标准库的应用或模块。
  defp deps do
    [
      # GenStage 的 Github 仓库归 elixir-lang ，四舍五入也算标准库了。
      # {:gen_stage, "~> 1.2"}
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
    extras = [
      # "guides_zh/Overview.md",
      "guides_zh/params/BezierCurve.md",
      "guides_zh/operator/Operate.md",
      "guides_zh/operator/OperateGraph.md",
      "guides_zh/segment/StateMachine.md",
      "guides_zh/segment/SegmentManeger.md"
    ]
    groups_for_extras = [
      # Guides: ~r/guides_zh\/[^\/]+\.md/,
      Parameters: ~r/guides_zh\/params\/.?/,
      "Operate-Param": ~r/guides_zh\/operator\/.?/,
      "Segment-Management": ~r/guides_zh\/segment\/.?/
    ]
    [
      main: "QyCore",
      extras: ["README.md"] ++ extras,
      groups_for_extras: groups_for_extras
    ]
  end
end
