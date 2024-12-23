defmodule QyCore.Segment do
  @moduledoc """
  `QyCore.Segment` 是编辑器处理的基本单位。

  关于对段落的状态管理，请参见 `QyCore.Segment.StateM`
  """

  # 后续 `id` 的具体类型可能需要调整
  @type id :: atom()

  @type segment_and_result :: {QyCore.Segment.t(), any()}

  @type t :: %__MODULE__{
    id: id(),
    offset: number(),
    params: [QyCore.Params.t()],
    comments: any(),
  }
  defstruct [
    :id,
    :offset,
    :params,
    :comments,
  ]

  ## 雷同逻辑
  # 简单来说有两类修改：需要调用模型得到新结果和不需要，其引发了不同的情景
  # def diff?(segment1, segment2, opts \\ [])

  ## 其他约束
  # 相同轨道的 segment 是否存在重叠
  # def overlap?(segment1, segment2, opts \\ [])
end
