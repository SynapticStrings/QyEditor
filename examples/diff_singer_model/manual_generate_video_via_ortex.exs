# 此模块仅需要编译 Ortex 以及 Nx 即可
# 如果你需要使用 CUDA 请查看相关文档并且修改你的配置
# （Windows 下可能需要 Visual Studio 环境用于编译以及链接）
# 此外你还需要下载声库，本脚本使用的是绮萱 v2.5.0 的 OpenUTAU 声库
# 选择此声库是因为其由 OpenVPI 维护，具备更大的参考价值

join = fn sub -> Path.join(File.cwd!(), sub) end
project_path = join.("priv/_project")
model_path = join.("priv/Qixuan_v2.5.0_DiffSinger_OpenUtau")

unless File.exists?(model_path), do:
  raise("Model doesn't exist! Please download and unzip at ...")

unless File.exists?(project_path) do
  project_path
  |> File.mkdir!()

  IO.puts("Create project folder")
end

## 另一些前期准备
# 语言 id
languages_repo = fn relative_model_root_path ->
  [file] = Path.wildcard(relative_model_root_path <> "/*.languages.json")

  file
  |> File.read!()
  |> Jason.decode!()
end
language_id_fetcher = fn lang_ids, lang -> Map.get(lang_ids, lang) end

# 拼音 id
phonemes_repo = fn relative_model_root_path ->
  [file] = Path.wildcard(relative_model_root_path <> "/*.phonemes.json")

  file
  |> File.read!()
  |> Jason.decode!()
end
phoneme_id_fetcher = fn phoneme_ids, lang, phoneme ->
  cond do
    phoneme in ["AP", "SP"] -> Map.get(phoneme_ids, phoneme)
    true -> Map.get(phoneme_ids, lang <> "/" <> phoneme)
  end
end

# 要不要干脆用 OpenUTAU 调教一下把参数导出来？
## 歌曲的基本信息
# （用这个是因为手头没其他合适的谱子了，以及一种对未完成情结的补足，或升华）
# 砂糖协会 - 雨后甜点 的第一句：
# 与梦游的流星和漫不经心云 徘徊在午后水汽里 小心思交织漂浮 亲吻不安定
_songLang = "zh"
_songBPM = 128.0

## 信息的编码

# 时间（基于 BPM 以及歌词的节拍）

##模块的通用属性
defmodule PhonemeConvetor do
  @moduledoc """
  自动化实现声库音素读取的函数。
  """
  defmacro __using__(_opts) do
    quote do
      # 从模块中调用 @root_path 这个属性
      _root_path = Module.get_attribute(__MODULE__, :root_path)

      # @before_compile unquote(__MODULE__)

      # 并且实现从语言/音素名字到 id 的转化函数
      def convert_ph(phone), do: phone
      def convert_lang(lang), do: lang
    end
  end

  defmacro __before_compile__(_env) do
    # 为加快速度，对字典的读取最好在编译前完成
    # 将其变成一个仅有 __using__ 的函数可以使用的属性
    # Module.register_attribute(__MODULE__, :phoneme_dict)
    # Module.put_attribute(__MODULE__, :phoneme_dict)
  end
end

# 先实际成功跑通了再来动这个
defmodule OrtexRunnable do
  @moduledoc """
  省略关于 Ortex 的重复代码。
  """
  defmacro __using__(_opts) do
    quote do
      # @behavior unquote(__MODULE__)
      # import unquote(__MODULE__)
    end
  end

  # @callback load() :: any()

  @callback prepare() :: any()

  @callback run() :: any()
end

## 音素时长的预测
defmodule DSDur do
  use PhonemeConvetor, lang: "zh"
  # use OrtexRunnable
  # @root_path Path.join(model_path, ["dsdur"])
end

## 音高的预测
defmodule DSPitch do
  use PhonemeConvetor, lang: "zh"
end

## 方差模型
defmodule DSVariance do
  use PhonemeConvetor, lang: "zh"
end

defmodule DSAcoustic do
  use PhonemeConvetor, lang: "zh"
end

defmodule DSVocoder do
end
