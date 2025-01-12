defmodule QyCore.Param do
  # TODO
  # 理清项目中关于「参数」、「配置」、「选项」的区别以及适用范围
  @moduledoc """
  关于序列参数的相关模块。

  其中的参数（Parameter）是用于表示和操作参数的值本身，包括了和时间步长无关的序列（`element_seq`）
  以及和时间步长有关的序列（`:time_seq`）两类。粗暴地定义就是分别涉及到「指令」以及「结果」，
  但实际上并不是一一对应，所以实质上的类型是包括了参数来源、序列类型以及参数名字的元组。

  从 DDD 的角度出发，这里的参数属于 Value Object 。所以不需要 `id` 。

  TODO: 为什么要设计这个模块
  设计该模块的目的是实现一系列和参数有关的逻辑以及定义一系列的接口以帮助或约束其他使用 `qy_core`
  的开发者使其更专注业务逻辑。

  ## 一瞥————从案例入手

  如果仅凭文字讲述可能过于抽象，因此将结合一个例子予以讲解。

  > *某使用场景需要将音素序列转变为音频以及对应的口型。*
  >
  > -> 音素/声学特征/音频/声道特征

  TODO: 这个模块需要干什么

  - 曲线工具
  - 默认值以及检查验证
  - **简单**操作（需要上下文以及模型操作的不会依照这套运行）
    - 延长截短
    - 截断合并

  ## 如何使用？

  请参见 `QyCore.Param.Proto` 。

  """

  # 参数的通用设置
  @type t :: %__MODULE__{
          type: {param_source(), seq_type(), param_name()} | nil,
          timestep: number() | nil,
          offset: number(),
          sequence: [any()],
          context: map(),
          extra: map()
        }
  defstruct [
    # 参数的类型，包括参数数据的类型以及参数属于的类型
    type: nil,
    # 参数的时间步长
    timestep: nil,
    # 首个参数的时长偏移量
    # 一般为零（因为在 Segment 下）
    offset: 0.0,
    # 参数序列
    # 如果 opts 中的 seq 为 reverse ，数据从反向开始
    sequence: [],
    # 上下文
    # 比方说这个参数黏附的对象是某某句子，或是某某时间戳
    context: %{},
    # 额外信息
    # 像是控制/约定参数的曲线
    # 还有一种案例是记录用户修改模型生成的数据（通过曲线或参数变化）
    extra: %{},
    # 设置
    opts: [seq: :reverse]
  ]

  ## 类型

  @typedoc "参数的来源一个是手动更新，还有一个是模型生成的"
  @type param_source :: :mannual | :generated
  @typedoc "参数的类型一个是时间序列（依赖于 `timestamp`）；另一个是元素序列（比方说音素的某某参数）"
  @type seq_type :: :time_seq | :element_seq
  @typedoc "具体的参数名字"
  @type param_name :: atom()

  # @doc "参数是否是结果"
  # def result?(%__MODULE__{type: {:generated, _, _}}), do: true
  # def result?(_), do: false

  @doc "是否是时间序列"
  def time_seq?(%__MODULE__{type: {_, :time_seq, _}}), do: true
  def time_seq?(%__MODULE__{type: {_, :element_seq, _}}), do: false

  @doc "是否是元素序列"
  def element_seq?(%__MODULE__{type: {_, :element_seq, _}}), do: true
  def element_seq?(%__MODULE__{type: {_, :time_seq, _}}), do: false

  ## 检验参数是否合法

  # 默认值、极限值的设定以及约束
  @spec validate(t(), keyword()) :: {:error, term()} | {:ok, QyCore.Param.t()}
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
