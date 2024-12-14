defmodule QyCore.Segment do
  @moduledoc """
  `QyCore.Segment` 是编辑器处理的基本单位。

  关于对段落的状态管理，请参见 `QyCore.Segment.StateM`
  """

  @type t :: %__MODULE__{
    id: atom(),
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
  # 简单来说有两类修改：需要调用模型得到新结果和不需要，其需要不同的情景
  # def diff?(segment1, segment2, opts \\ [])
end
