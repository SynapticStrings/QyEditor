defmodule QyCore.Segment.StateM do
  # TODO: 逻辑还很乱，需要再梳理下
  @moduledoc """
  对片段状态的管理，为了更直观地向用户展示片段的状态。

  为了确保片段能够实行增量式的渲染（输入变化时，只重新计算受影响的内容），
  故该负责片段状态管理的模块基于状态机设计。

  简单来说以下几步：

  1. 输入更新后并得到推理请求后挂起，等待推理模型可用
  2. 作为客户端与推理模型通信，等待推理的结果并更新
  3. 得到全部结果后更新片段的状态

  如果其中存在出错可能还会进行简单的错误处理。

  设计该模块考虑的视角是用户与模型两端对片段都会有所修改。
  """
  defstruct [
    # 进程 ID
    :id,
    # 对应的 Segment 本体
    :reference,
    # 可能有的输入（一般是 nil）
    :maybe_new_input,
    # 不同的工作对应着不同的函数
    # 这是能够得到结果的操作
    :available_jobs
  ]

  alias QyCore.Segment

  # 看上去更符合 Elixir 的命名
  alias :gen_statem, as: GenStateM
  @behaviour GenStateM

  @type t :: %__MODULE__{
    id: segment_id(),
    reference: Segment.t() | %{DateTime.t() => Segment.t()},
    maybe_new_input: nil | any(),
    available_jobs: atom() | %{atom() => job_payload()}
  }

  #
  @type job_payload :: function()

  @typedoc "状态机进程的名字和片段的名字保持一致，一一对应"
  @type segment_id :: Segment.id()

  @typedoc "状态机进程的名字，其通常由私有函数 name/1 由 `segment_id` 生成"
  @type name :: {:global, {:segment, segment_id()}}

  @typedoc "状态机的状态"
  @type states :: :idle | :has_new_segment | :required_update | :execute_update

  ################################
  ## Mode
  ################################

  @impl GenStateM
  def callback_mode(),
    # 简单来说就是把状态名当成函数
    # 这样可以把代码梳理得更贴合业务
    do: [:state_functions, :state_enter]

  ################################
  ## Public API
  ################################

  # 更新片段

  ################################
  ## Callback
  ################################

  ## 初始化
  @impl GenStateM
  def init(_args) do
    {:ok, :idle, {}}
  end

  ## idle
  # 该状态下没有 dirty input

  # enter

  # 更新片段

  # 其他的事件

  ## has_new_input
  # 有未被推理的输出，其他的和 idle 一样

  # enter
  def has_new_input(:enter) do
    # 简单是否有输入
  end

  # 准备更新

  ## ready_for_update
  # ？ 要确定这种状态有必要吗？

  # 推理服务空闲，可以更新

  ## during_update

  # 执行更新

  # 出错

  # 其他事件

  ################################
  ## Helpers and Private Functions
  ################################

  # 用于检查内部的状态是否正确

  def validate(%__MODULE__{maybe_new_input: nil}), do: :idle

  def validate(%__MODULE__{}), do: :other

  def validate(_), do: :error

  # 包装 callback | 动作

  # defp reply(payload, from), do: {:reply, from, payload}

  # defp reply_action(payload, from), do: reply(payload, from) |> then(&[&1])

  # # 包装 callback | 状态

  # defp keep_state_and_data(actions), do: {:keep_state_and_data, actions}

  # defp keep_state(data, actions), do: {:keep_state, data, actions}

  # defp next_state(new_state, new_data, actions), do: {:next_state, new_state, new_data, actions}

  # # 包装 callback | 消息内容

  # defp as_err(reason), do: {:error, reason}

  # defp as_ok(reason), do: {:ok, reason}
  # defp as_ok(), do: :ok
end
