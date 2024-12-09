# 此模块仅需要编译 Ortex 以及 Nx 即可
# 如果你需要使用 CUDA 请查看相关文档并且修改你的配置
# （Windows 下可能需要 Visual Studio 环境用于编译以及链接）
# 此外你还需要下载声库，本脚本使用的是绮萱 v2.5.0 的 OpenUTAU 声库
# 选择此声库是因为其由 OpenVPI 维护，具备更大的参考价值

join = fn sub -> Path.join(File.cwd!(), sub) end
project_path = join.("priv/_project")
model_path = Application.compile_env(:diff_singer, :singer_repo)["Qixuan"]

unless File.exists?(model_path), do:
  raise("Model doesn't exist! Please download and unzip at ...")

unless File.exists?(project_path) do
  project_path
  |> File.mkdir!()

  IO.puts("Create project folder")
end

## 信息的编码

# 时间（基于 BPM 以及歌词的节拍）

##模块的通用属性
defmodule PhonemeConvetor do
  @moduledoc """
  自动化实现声库音素读取的函数。
  """
  defmacro __using__(opts) do
    root_path = Keyword.get(opts, :root_path)

    phoneme_path = data_path(root_path <> "/*.phonemes.json")
    language_path = data_path(root_path <> "/*.languages.json")

    phoneme_data = read_data(phoneme_path)
    language_data = read_data(language_path)

    phonemes_func = define_phonemes_func(phoneme_data)
    languages_func = define_languages_func(language_data)

    quote do
      @external_resource unquote(phoneme_path)
      @external_resource unquote(language_path)

      unquote(phonemes_func)
      unquote(languages_func)
    end
  end

  defp define_phonemes_func(data) do
    # store kv in function, faster than map
    funs = for {key, value} <- data do
      quote do
        def convert_ph(unquote(key)) do
          unquote(value)
        end
      end
    end

    helper_funs = quote do
      def convert_ph(_), do: nil

      def convert_ph(lang, phoneme) do
        if phoneme in ["AP", "SP"] do
          convert_ph(phoneme)
        else
          convert_ph(lang <> "/" <> phoneme)
        end
      end
    end

    funs ++ [helper_funs]
  end

  defp define_languages_func(data) do
    # store kv in function, faster than map
    for {key, value} <- data do
      quote do
        def convert_lang(unquote(key)) do
          unquote(value)
        end
      end
    end ++ [
      quote do
        def convert_lang(_), do: nil
      end
    ]
  end

  defp data_path(path) do
    path
    |> Path.wildcard()
    |> List.first()
  end

  defp read_data(path) do
    path
    |> File.read!()
    |> Jason.decode!()
  end
end

# 先实际成功跑通了再来动这个
defmodule OrtexRunnable do
  @moduledoc """
  省略关于 Ortex 的重复代码。
  """
  defmacro __using__(opts) do
    _root_path = Keyword.get(opts, :root_path)
    # TODO fetch model's path
    quote do
      # import unquote(__MODULE__)
    end
  end
  @callback prepare() :: any()

  @callback run() :: any()
end

# 要不要干脆用 OpenUTAU 调教一下把参数导出来？
## 歌曲的基本信息
# （用这个是因为手头没其他合适的谱子了，以及一种对未完成情结的补足，或升华）
# 砂糖协会 - 雨后甜点 的第一句：
# 与梦游的流星和漫不经心云 徘徊在午后水汽里 小心思交织漂浮 亲吻不安定
_songLang = "zh"
_songBPM = 128.0

modules_require_dict = [
  ## 音素时长的预测
  {DSDur, "dsdur"},
  ## 音高的预测
  {DSPitch, "dspitch"},
  ## 唱法模型
  {DSVariance, "dsvariance"},
  ## 声学模型
  # 在根目录
  {DSAcoustic, ""},
]
|> Enum.map(fn {name, path} ->
  {name, Path.join(model_path, path)}
end)

for {name, path} <- modules_require_dict do
  Module.create(
    name,
    quote do
      use PhonemeConvetor, root_path: unquote(path)
    end,
    Macro.Env.location(__ENV__)
  )
end

defmodule DSVocoder do
end
