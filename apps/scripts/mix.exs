defmodule QyScripts.MixProject do
  use Mix.Project

  def project do
    [
      app: :scripts,
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

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # JSON parser
      # Same with :web_ui
      {:jason, "~> 1.2"},
      # Qy related
      {:qy_music, in_umbrella: true}
    ]
  end
end
