defmodule QyCore.Segment.Proto do
  @moduledoc """
  实现状态机与目标模型的通信、检查、报错等函数。
  """

  defmodule LoadSegment do
    @moduledoc "装载片段所用到的回调"

    @doc "更新片段时的回调函数，确定旧片段与新片段的比较逻辑"
    @callback update_or_modify(QyCore.Segment.t(), QyCore.Segment.t()) ::
                QyCore.Segment.StateM.same_situations()

    @doc "如果 update_or_modify/2 返回 :update，那么就会调用这个函数"
    @callback modifier(QyCore.Segment.segment_and_result(), QyCore.Segment.t()) ::
                QyCore.Segment.segment_and_result()
  end

  def load_segment() do
    quote do
      @behaviour LoadSegment

      # 由默认实现，所以在这里使用 defdelegate
      defdelegate update_or_modify(old_segment, new_segment), to: QyCore.Segment

      defdelegate modifier(old_segment_and_result, new_segment), to: QyCore.Segment

      # 如果下游模块需要修改的话
      defoverridable update_or_modify: 2, modifier: 2
    end
  end

  defmodule Caller do
    @moduledoc """
    和模型通信时向其他进程（一般是最开始触发推理事务的进程）发送消息时所用到的回调。
    """

    @callback send_event_to_caller(payload :: term()) :: :ok
  end

  def caller() do
    quote do
      @behaviour Caller
    end
  end

  defmodule Executor do
    @moduledoc """
    和推理模型通信时用到的回调。

    通常由下游编写的模块实现。
    """

    @callback validate_segment_with_model(QyCore.Segment.t()) ::
                QyCore.Segment.StateM.check_data_status_msg()

    @doc "确定模型的可行性"
    @callback usability_check() :: QyCore.Segment.StateM.model_usability_msg()

    # TODO 需要确定具体的返回值
    @callback execute_inference(QyCore.Segment.t()) :: QyCore.Segment.segment_and_result()
  end

  def executor() do
    quote do
      @behaviour Executor
    end
  end

  defmacro __using__(opts) do
    enable_opts = Keyword.get(opts, :enabled, [:load_segment])

    # 装载对应的代码片段
    for opt <- enable_opts do
      apply(__MODULE__, opt, [])
    end
  end
end
