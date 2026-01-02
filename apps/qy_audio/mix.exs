defmodule QyAudio.MixProject do
  use Mix.Project

  def project do
    [
      app: :qy_audio,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {QyAudio.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # 音频处理相关依赖
      # {:portaudio, "~> 1.0"},  # 可以考虑添加 PortAudio 支持
      # {:soundfile, "~> 0.1"},  # 音频文件处理
      
      # 内部依赖
      {:qy_music, in_umbrella: true}
    ]
  end
end
