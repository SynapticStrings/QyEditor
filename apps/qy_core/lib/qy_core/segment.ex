defmodule QyCore.Segment do
  @moduledoc """
  片段是编辑器中执行处理操作的基本单位，也是推理服务的上下文与环境。

  其通常由一堆参数依据需要被堆叠而组成。
  """
  alias QyCore.Segment

  @typedoc "片段的唯一标识符"
  @type id :: binary()

  # TODO: 思考这里到底应该怎么定义、决定了什么
  # 来源不可行，因为片段内很多参数的来源都不尽相同
  @typedoc "片段的角色，通常是该片段的来源"
  @type role :: nil

  @typedoc """
  使用这种方式命名的原因是为了避免可能存在的将片段的 id 作为字典的键，但这里的
  `t:id/0` 一定要相同的情况。

  比方说在片段状态机中，对于人工编辑的片段以及模型生成的片段，其 id 一定是不同的
  但是因为其本质上是对同一个事物在同一时间段的不同表征（比方说 f0 与实际波形）所以其 id
  最好保持一致。
  """
  @type id_as_key :: {id(), role()}

  @typedoc "某一个片段以及已经由模型获得了结果的组合元组"
  @type segment_and_result :: {Segment.t(), Segment.t()}

  @type t :: %__MODULE__{
              id: id_as_key(),
              offset: number(),
              params: %{atom() => QyCore.Param.t()},
              comments: any()
            }
  @enforce_keys [:id]
  defstruct [
    :id,
    offset: 0.0,
    comments: "",
    params: %{},
    # TODO: add aviable recipes here.
  ]

  ## 创建 Segment

  def create(id \\ random_id(), params \\ %{}) do
    # 最开始的创建还是由模型生成的
    # 不存在【纯粹的】用户创建
    %__MODULE__{id: {id, nil}, params: params}
  end

  ## 关于 ID

  @doc """
  生成一个随机的 ID 。

  生成的 ID 由两部分组成：

  * 时间戳（10 位）
  * 随机数（16 位）
  """
  def random_id(current \\ DateTime.utc_now()) do
    # 创建的时间戳
    timestamp =
      current
      |> DateTime.to_unix()
      |> Integer.to_string()
      |> Base.encode32(case: :lower)
      |> String.slice(0..9)

    # 随机数
    random =
      :crypto.strong_rand_bytes(8)
      |> Base.encode16(case: :lower)

    timestamp <> random
  end

  @doc "对 ID 进行纯化的函数，即将 ID 从元组/结构体中提取出来"
  def purely_id(%__MODULE__{id: {id, _}}), do: id
  def purely_id({id, _}) when is_binary(id), do: id
  def purely_id(id) when is_binary(id), do: id

  ## 雷同逻辑

  def same_id?(%__MODULE__{} = segment1, %__MODULE__{} = segment2) do
    # IO.inspect(segment1.id)
    # IO.inspect(segment2.id)
    segment1.id == segment2.id or not (segment1.id != nil and segment2.id != nil)
  end

  def same_offset?(%__MODULE__{} = segment1, %__MODULE__{} = segment2) do
    segment1.offset == segment2.offset
  end
end
