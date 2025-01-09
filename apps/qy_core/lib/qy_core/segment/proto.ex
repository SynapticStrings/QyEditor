defmodule QyCore.Segment.Proto do
  @moduledoc """
  实现状态机与目标模型的通信、检查、报错等函数。
  """

  defmodule LoadSegment do
    @moduledoc "装载片段所用到的回调"

    @typedoc "旧片段与新片段的比较情况，其决定了是否需要调用推理模型"
    @type same_situations :: :required | :update | {:error, term()}

    @doc "更新片段时的回调函数，确定旧片段与新片段的比较逻辑"
    @callback update_or_modify(QyCore.Segment.t(), QyCore.Segment.t()) ::
                same_situations()

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

    # 这个函数还没确定好，如果确定将 Caller 的进程装在入状态机的数据的时候，这个函数就不需要了
    @doc "发送消息给调用者"
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

    @typedoc """
    模型可行性的类型，由状态机的进程向状态机发送。

    此类型以及其 arity 还没有确定，所以暂时只有一个像那回事的返回值。
    """
    @type inference_worker_status :: :ok | {:error, term()}

    @typedoc """
    检查数据是否合法的消息，由状态模型的进程向状态机发送。

    在此设立此类型是为了定义状态机所接受的信息的类型。

    其也是 `QyCore.Segment.Proto.Executor.validate_segment_with_model` 回调的返回类型。
    """
    @type segment_validate_status :: :accpet | {:reject, term()}

    @doc "调用模型相关服务检查数据片段是否合法"
    @callback validate_segment_with_model(QyCore.Segment.t()) ::
                segment_validate_status()

    @doc "确定模型的可用性"
    @callback usability_check() :: inference_worker_status()

    # TODO: 需要确定具体的返回值
    @callback execute_inference(QyCore.Segment.t(), role :: atom()) :: QyCore.Segment.segment_and_result()

    # 处理流程
    # 有无新消息
  end

  def executor() do
    quote do
      # 这里的 Executor 一般是 GenServer
      use GenServer

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
