defmodule QyCore.Params do
  @moduledoc """
  参数的设置。

  目前 QyEditor 计划实现以下的参数（待思考完成后再对其共性进行整理进而确定该模块的业务范围）：

  * 音符（MIDI-like）
  * 音素
    * 音素序列
    * 音素时长 -> 音素序列 & 音符
  * 音高曲线

  """

  # 参数的通用设置
  @type t :: %__MODULE__{
          id: any(),
          type: {param_type(), param_name()},
          timestep: number(),
          offset: number(),
          sequence: [any()],
          context: map(),
          extra: map()
        }
  defstruct [
    :id,
    # 参数的 id （因为一个工程不可避免地存在很多个参数）
    :type,
    # 参数的类型，包括参数数据的类型以及参数属于的类型
    :timestep,
    # 参数的时间步长
    :offset,
    # 首个参数的时长偏移量
    :sequence,
    # 参数序列
    # 因为 Elixir 列表的实质，所以这里的序列是相反的，即 [last_element [... [first_element]]]
    :context,
    # 上下文
    # 比方说这个参数黏附的对象是某某句子，或是某某时间戳
    :extra
    # 额外信息
    # 像是控制/约定参数的曲线
  ]

  ## 类型

  @typedoc "参数的类型一个是时间序列（依赖于 `timestamp`）；另一个是元素序列（比方说音素的某某参数）"
  @type param_type :: :time_seq | :element_seq
  @typedoc "具体的参数名字"
  @type param_name :: atom()

  def time_seq?(%__MODULE__{type: {:time_seq, _}}), do: true
  def time_seq?(%__MODULE__{type: {:element_seq, _}}), do: false
  def element_seq?(%__MODULE__{type: {:element_seq, _}}), do: true
  def element_seq?(%__MODULE__{type: {:time_seq, _}}), do: false

  ## 检验参数是否合法

  # 默认值、极限值的设定以及约束
  def validate(params, opts \\ [])

  def validate(params = %__MODULE__{}, _opts) do
    # 解析设置

    # 依据设置分别调用相关的子函数
    # ...

    {:ok, params}
  end

  def validate(_params, _opts), do: {:error, :invalid}

  # 比方说参数不能超过或是低于什么
  def validate_sequence(%__MODULE__{type: {param_type, _}, sequence: _seq})
      when param_type == :time_seq do
    # ...
  end
  def validate_sequence(%__MODULE__{type: {param_type, _}, sequence: _seq})
      when param_type == :element_seq do
    # ...
  end

  def validate_context(_context, _type), do: nil
  def validate_extra(_extra, _type), do: nil

  ## 上下文

  ## 额外信息
end
