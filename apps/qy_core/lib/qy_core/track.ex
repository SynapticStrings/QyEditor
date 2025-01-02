defmodule QyCore.Track do
  # 对 QyCore.Segment.Manager 的进一步封装
  # （简单来说，一个音轨就是有默认操作图的片段管理器）

  @type t :: %__MODULE__{
          id: any(),
          manager: QyCore.Segment.Manager.id(),
          name: String.t(),
          # 用于持久化的片段记录
          # （实际的片段以及推理过程归别的进程）
          segments_record: [QyCore.Segment.t()],
          # op means operate
          # 这块还没想好
          default_op_graph: %{atom() => any()}
        }
  defstruct [:id, :manager, :name, :segments_record, :default_op_graph]
end
