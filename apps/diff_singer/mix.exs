defmodule DiffSinger.MixProject do
  use Mix.Project

  @version "0.1.0"
  # TODO:
  # Add version of DiffSinger.

  def project do
    [
      app: :diff_singer,
      version: @version,
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {DiffSinger.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nx, "~> 0.8"},
      # Use it until my fork can running ONNXRuntime
      # on Intel Arc via OpenVINO.
      {:ortex, "~> 0.1.0"}
      # Only used when in development.
      # Inspect the model
    ]
  end
end
