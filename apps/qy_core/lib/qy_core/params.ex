defmodule QyCore.Params do
  # 参数的通用设置
  @type t :: %__MODULE__{
    id: any(),
    type: param_type(),
    timestep: number(),
    offset: number(),
    sequence: [any()],
    context: map(),
    extra: map(),
  }
  defstruct [
    :id,
    # 参数的 id （因为一个工程不可避免地存在很多个参数）
    :type,
    # 参数的类型
    :timestep,
    # 参数的时间步长
    :offset,
    # 首个参数的时长偏移量
    :sequence,
    # 参数序列
    :context,
    # 上下文
    # 比方说这个参数黏附的对象是某某句子，或是某某时间戳
    :extra,
    # 额外信息
    # 像是控制/约定参数的曲线
  ]

  ## 类型
  @typedoc """
  参数的类型：一个是时间序列（依赖于 `timestamp`）；
  另一个是元素序列（比方说音素的某某参数）
  """
  @type param_type :: :time_seq | :element_seq

  # 默认值、极限值的设定以及约束
  def validate(params = %__MODULE__{}), do: {:ok, params}
  def calidate(_params), do: {:error, :invalid}

  # 贝塞尔曲线特征点 => 参数值
end
