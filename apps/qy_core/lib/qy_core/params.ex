defmodule QyCore.Params do
  # TODO
  # 理清项目中关于「参数」、「配置」、「选项」的区别以及适用范围
  @moduledoc """
  参数的设置。

  目前 QyEditor 计划实现以下的参数（待思考完成后再对其共性进行整理进而确定该模块的业务范围）：

  * 音符（MIDI-like）
  * 音素
    * 音素序列
    * 音素时长 -> 音素序列 & 音符
  * 音高曲线
  * 音频
    * 波形
    * 频谱
    * 梅尔谱
    * etc.

  """

  # 参数的通用设置
  @type t :: %__MODULE__{
          id: any(),
          type: {param_source(), param_type(), param_name()} | nil,
          timestep: number(),
          offset: number(),
          sequence: [any()],
          context: map(),
          extra: map()
        }
  defstruct [
    :id,
    # 参数的 id （因为一个工程不可避免地存在很多个参数）
    type: nil,
    # 参数的类型，包括参数数据的类型以及参数属于的类型
    timestep: 0.0,
    # 参数的时间步长
    offset: 0.0,
    # 首个参数的时长偏移量
    # 一般为零（因为在 Segment 下）
    sequence: [],
    # 参数序列
    # 因为 Elixir 列表的实质，所以这里的序列是相反的，即 [last_element [... [first_element]]]
    context: %{},
    # 上下文
    # 比方说这个参数黏附的对象是某某句子，或是某某时间戳
    extra: %{}
    # 额外信息
    # 像是控制/约定参数的曲线
  ]

  ## 类型

  @typedoc "参数的来源一个是手动更新，还有一个是模型生成的"
  @type param_source :: :mannual | :generated
  @typedoc "参数的类型一个是时间序列（依赖于 `timestamp`）；另一个是元素序列（比方说音素的某某参数）"
  @type param_type :: :time_seq | :element_seq
  @typedoc "具体的参数名字"
  @type param_name :: atom()

  @doc "参数是否是结果"
  def result?(%__MODULE__{type: {:generated, _, _}}), do: true
  def result?(_), do: false

  @doc "是否是时间序列"
  def time_seq?(%__MODULE__{type: {_, :time_seq, _}}), do: true
  def time_seq?(%__MODULE__{type: {_, :element_seq, _}}), do: false

  @doc "是否是元素序列"
  def element_seq?(%__MODULE__{type: {_, :element_seq, _}}), do: true
  def element_seq?(%__MODULE__{type: {_, :time_seq, _}}), do: false

  ## 检验参数是否合法

  # 默认值、极限值的设定以及约束
  @spec validate(t(), keyword()) :: {:error, term()} | {:ok, QyCore.Params.t()}
  def validate(params, opts \\ [])

  def validate(params = %__MODULE__{}, _opts) do
    # 解析设置

    # 依据设置分别调用相关的子函数
    # ...

    {:ok, params}
  end

  def validate(_params, _opts), do: {:error, :invalid}

  def validate_context(_context, _type), do: nil
  def validate_extra(_extra, _type), do: nil

  ## 约束

  def check_constraint(param_seq, opts) when is_list(opts) do
    for opt <- opts do
      constraint(param_seq, opt)
    end
    |> Enum.reject(&is_nil/1)
  end

  def constraint(param_seq, {:less_than, maxinum_value}) do
    Enum.all?(param_seq, fn x -> x < maxinum_value end)
  end

  def constraint(param_seq, {:greater_than, mininum_value}) do
    Enum.all?(param_seq, fn x -> x > mininum_value end)
  end

  # 当前参数是否被手动修改过
  def constraint(param_seq, {:dirty, default_value_or_validator})
      when is_function(default_value_or_validator) do
    default_value_or_validator.(param_seq)
  end

  def constraint(param_seq, {:dirty, default_value_or_validator}) do
    Enum.all?(param_seq, fn x -> x == default_value_or_validator end)
  end

  def constraint(_param_seq, _), do: nil

  ## 上下文

  ## 额外信息
end
