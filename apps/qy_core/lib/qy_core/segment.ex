defmodule QyCore.Segment do
  @moduledoc """
  对于工程的模块。

  关于对段落的状态管理，请参见 `QyCore.Segment.StateM`
  """

  defstruct [
    :offset,
    :params,
  ]

  # def check_diff(segment1, segment2)
end
