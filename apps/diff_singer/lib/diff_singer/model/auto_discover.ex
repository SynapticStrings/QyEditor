defmodule DiffSinger.Model.AutoDiscover do
  @moduledoc false
  @type model_type :: :open_utau, :pytorch
  @type t :: %__MODULE__{
    root_path: Path.t(),
    name: String.t(),
    model_type: model_type(),
    mapper: any()
  }
  defstruct [:root_path, :name, :model_type, :mapper]

  @spec return_all_onnx_path(root_path :: Path.t()) :: [Path.t()]
  def return_all_onnx_path(root_path) do
    Path.type(root_path)
    |> case do
      :absolute -> root_path
      :relative -> Path.join(File.cwd!(), root_path)
      :volumerelative -> Path.expand(root_path)
    end
    |> String.replace(~r(\\), "/")
    |> then(& &1 <> "/**/*.onnx")
    |> Path.wildcard()
  end

  # 返回出现最多的词语作为名字
  def get_model_name_with_file_name(model_paths \\ [""]) do
    [{first_freq_item, _} | _] = model_paths
    |> Enum.map(&Path.basename(&1, ".onnx"))
    # 把所有存在的共同部分统计出来
    # 不考虑通用格式了，太麻烦
    |> Enum.map(&String.split(&1, [".", "_"]))
    |> List.flatten()
    |> Enum.frequencies()
    |> Enum.sort(fn {_, v1}, {_, v2} -> v1 >= v2 end)

    first_freq_item
  end

  #
  def get_model_name_from_dsconfig(file_path) do
    file_path
    |> :yamerl.decode_file()
  end

  def get_vocoder(model_name_list) do
    model_name_list
    |> Enum.find(&String.contains?(&1, ["nsf", "hifigan"]))
  end

  _comment = """

  # root_path = "priv/Qixuan_v2.5.0_DiffSinger_OpenUtau"

  # Used for the scene that need automatic linking DiffSinger.
  @spec show_port(Ortex.Model.t()) :: {any(), any()}
  def show_port(%Ortex.Model{reference: model}) do
    case Ortex.Native.show_session(model) do
      {:error, msg} -> raise msg
      {inputs, outputs} -> {port_opt(inputs), port_opt(outputs)}
    end
  end

  # References `native/ortex/src/model.rs` in ortex
  # And related code in ort.
  # This may not stable.
  defp port_opt(inputs_or_outputs) do
    inputs_or_outputs
    |> Enum.map(fn {name, _repr, dims} ->
      # 怕有模型使用数字做开头，还是用字符串吧
      # 对于为什么把 repr 丢掉，参见下面
      %{name => {dims}}
    end)
    |> Enum.into(%{})
  end

  # 如有必要的话，实现 parse_ort_value_type/1 ，其负责解析
  # Ortex.Native.show_session/1 返回的结果中的字符串。`Ortex` 中相关负责处理的代码是
  # `// let repr = format!("{:#?}", input.input_type);`
  # 其中 `input.input_type` 和 `output.output_type` 同属 `ort::value::ValueType`
  # 根据相关源代码以及 ONNX 的文档，其包括 Tensor ，还可以是 Seq 或 Map ；
  # 另一个问题很自然地出现了。该怎么表现出来？
  # （1. 用户可读；2. 能够直观地判断出值具体的类型）
  # 例子：
  # {"f0",
  #   "Tensor {\n    ty: Float32,\n    dimensions: [\n        1,\n        -1,\n    ],\n}",
  #   [1, -1]}
  # =>
  # %{"f0" => {"Tensor", "Float32", [1, -1]}}
  # 或者是干脆变成 %Nx.Tensor{} ？
  """
end
