defmodule DiffSinger.Model do
  @moduledoc """
  模型的通用设置，如果想查看各个模型的实现细节，请参见：

  - `DiffSinger.Model.Acoustic`
  - `DiffSinger.Model.Variance`
  - `DiffSinger.Model.Vocoder`
  - [TODO)

  当前 DiffSinger Elixir 只（还没）支持并且只打算支持
  ONNX 版本（也就是 OpenUTAU 用的）。
  """

  _unused_comment = """

  @type tensor :: Nx.Tensor.t()
  @type model_path :: Path.t()
  @type model :: Ortex.Model.t()

  # @callback load_model(path :: model_path()) :: model() | {:error, term()}

  # @callback validate_model(model :: model()) :: model() | {:error, term()}

  # @callback validate_input(input :: any(), context :: any()) :: any() | {:error, term()}

  # @callback do_run(input :: any(), model :: model()) :: any()

  defmacro __using__ do
    quote do
      @behavior unquote(__MODULE__)
      import unquote(__MODULE__)
    end
  end

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
