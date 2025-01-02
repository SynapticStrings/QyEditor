defmodule QyCore.Segment do
  @moduledoc """
  `QyCore.Segment` 是编辑器处理的基本单位。

  关于对段落的状态管理，请参见 `QyCore.Segment.StateM`
  """

  @type id :: binary()

  @type segment_and_result :: {QyCore.Segment.t(), any()}

  # 参数的位置（通常在多步渲染时会被用到）
  @type param_loc :: any()

  @type t :: %__MODULE__{
    id: id(),
    offset: number(),
    params: %{param_loc() => QyCore.Params.t()},
    comments: any(),
  }
  defstruct [
    :id,
    :offset,
    :params,
    :comments,
  ]

  ## 创建 Segment

  # def create/2

  ## 关于 ID

  def random_id() do
    # 创建的时间戳
    timestamp = DateTime.utc_now() |> DateTime.to_unix() |> Integer.to_string() |> String.slice(0..9)
    # 随机数
    random = :crypto.strong_rand_bytes(16) |> Base.encode32(case: :lower)

    timestamp <> random
  end

  def with_same_id?(segment1, segment2) do
    segment1.id == segment2.id
  end

  ## 雷同逻辑
  # 简单来说有两类修改：需要调用模型得到新结果和不需要，其引发了不同的情景
  # def diff?(segment1, segment2, opts \\ [])

  ## 其他约束
  # 相同轨道的 segment 是否存在重叠
  # def overlap?(segment1, segment2, opts \\ [])
end
