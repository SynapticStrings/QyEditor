defmodule QyCore.Segment do
  @moduledoc """
  `QyCore.Segment` 是编辑器处理的基本单位。

  关于对段落的状态管理，请参见 `QyCore.Segment.StateM`
  """

  @type id :: binary()

  @type role :: :mannual | :generated

  # 使用这种方式命名的原因是为了避免可能存在的将片段的 id 作为字典的键，但是
  # 这里的 id() 一定要相同的情况
  # 比方说在片段状态机中，对于人工编辑的片段以及模型生成的片段，其 id 一定是不同的
  # 但是因为其本质上是对同一个事物在同一时间段的不同表征（比方说 f0 与实际波形）所以其 id
  # 最好保持一致
  @type id_as_key :: {id(), role()}

  @type segment_and_result :: {QyCore.Segment.t(), any()}

  # 参数的位置（通常在多步渲染时会被用到）
  @type param_loc :: any()

  @type t :: nil | %__MODULE__{
          id: id_as_key(),
          offset: number(),
          params: %{param_loc() => QyCore.Params.t()},
          comments: any()
        }
  defstruct [
    :id,
    offset: 0.0,
    comments: "",
    params: %{}
  ]

  ## 创建 Segment

  # def create/2

  ## 关于 ID

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

  def purely_id(%__MODULE__{id: {id, _}}), do: id
  def purely_id({id, _}) when is_binary(id), do: id
  def purely_id(id) when is_binary(id), do: id

  def with_same_id?(segment1, segment2) do
    IO.inspect(segment1.id)
    IO.inspect(segment2.id)
    segment1.id == segment2.id or not (segment1.id != nil and segment2.id != nil)
  end

  def same_offset?(segment1, segment2) do
    segment1.offset == segment2.offset
  end

  ## 雷同逻辑

  # 简单来说有两类修改：需要调用模型得到新结果和不需要，其引发了不同的情景
  @spec diff?(QyCore.Segment.t(), QyCore.Segment.t()) :: :required | :update | {:error, term()}
  def diff?(segment1 = %__MODULE__{}, segment2 = %__MODULE__{}) do
    if with_same_id?(segment1, segment2) do
      case same_offset?(segment1, segment2) do
        # TODO 再加上一个条件：序列一致
        true -> :required
        false -> :update
      end
    else
      {:error, :segments_has_not_same_name}
    end
  end
  # When initial
  def diff?(nil, _), do: :required

  def diff?(_, _), do: {:error, :not_segment}

  @spec simple_update(QyCore.Segment.segment_and_result(), QyCore.Segment.t()) ::
          QyCore.Segment.segment_and_result()
  def simple_update({_old_segment, old_result}, new_segment) do
    {new_segment, %{old_result | offset: new_segment.offset}}
  end

  ## 其他约束
  # 相同轨道的 segment 是否存在重叠
  # def overlap?(segment1, segment2, opts \\ [])
end
