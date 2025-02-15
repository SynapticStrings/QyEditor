defmodule QyCore.Param do
  @moduledoc """
  关于序列参数的相关模块。

  其中的参数（Parameter）是用于表示和操作参数的值本身，包括了和时间步长无关的序列（`:element_seq`）
  以及和时间步长有关的序列（`:time_seq`）两类。粗暴地定义就是分别涉及到「指令」以及「结果」，
  但实际上并不是一一对应，所以实质上的类型是包括了参数来源、序列类型以及参数名字的元组。

  从 DDD 的角度出发，这里的参数属于 Value Object 。所以不需要 `id` 。

  TODO: 为什么要设计这个模块
  设计该模块的目的是实现一系列和参数有关的逻辑以及定义一系列的接口以帮助或约束其他使用 `qy_core`
  的开发者使其更专注业务逻辑。

  ## 一瞥————从案例入手

  如果仅凭文字讲述可能过于抽象，因此将结合一个例子予以讲解。

  在某使用场景需要将元音**音素序列**转变为**音频**以及对应的**舌位**中，
  其将音素通过**声学特征**变为音频以及舌位。

  ## 实现的功能

  - 曲线工具
  - 默认值以及检查验证
  - **简单**操作（需要上下文以及模型操作的不会依照这套运行）
    - 延长截短
    - 截断合并

  ## 如何使用？

  请参见 `QyCore.Param.Proto` 。

  """

  @type as_struct :: %__MODULE__{
          # created_at: DateTime.t(),
          name: {param_name(), param_source()} | nil,
          timestep: number() | nil,
          offset: number(),
          sequence: [any()],
          context: map(),
          extra: map()
        }
  defstruct [
    # 修改的时间
    # 用在可能需要修改模型生成的参数的情景
    # 其是具体的参数得到确定时的时间（只有曲线但是没有参数的情况就不算）
    # :created_at,
    # 参数的名字
    # 包括参数的名字以及来源，这么区分是因为有些参数是手动修改的
    name: nil,
    # 参数的时间步长
    timestep: nil,
    # 首个参数的时长偏移量
    # 一般为零（因为在 Segment 下）
    offset: 0.0,
    # 参数序列（序列是前向还是反向需要讨论一下）
    sequence: [],
    # 上下文
    # 比方说这个参数黏附的对象是某某句子，或是某某时间戳
    context: %{},
    # 额外信息
    # 像是控制/约定参数的曲线
    # 还有一种情况是记录用户修改模型生成的数据（通过曲线或参数变化）
    extra: %{}
  ]

  ## 类型

  @typedoc "参数的来源一个是手动更新，还有一个是模型生成的，前者的优先级高于后者"
  @type param_source :: :mannual | :generated
  @typedoc "参数的类型一个是时间序列（依赖于 `timestamp`）；另一个是元素序列（比方说音素的某某参数）"
  @type seq_type :: :time_seq | :element_seq
  @typedoc "具体的参数名字（如果是模块可能是定义参数的模块）"
  @type param_name :: atom() | module()
  @typedoc "实际的类型包括 `t:as_struct/0` 、暂时没有数据的空值以及索引键的 `t:atom/0`"
  @type t :: as_struct() | nil | atom()
end
