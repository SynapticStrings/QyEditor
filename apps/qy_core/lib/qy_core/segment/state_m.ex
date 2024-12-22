defmodule QyCore.Segment.StateM do
  @moduledoc """
  对片段状态的管理。

  简单来说就是为了更直观地展示片段的状态（）。

  ## 数据本体

  `{{current_state, inference_result}, tools_func, maybe_new_state_and_input}`

  * `{current_state, inference_result}` 状态与输出的对应，弄成这个元组是因为可能在别的地方用到
    - 最最开始一般就是 `{nil, nil}`
  * `tools_func` 工具函数（例如准备推理以及推理）
  * `maybe_new_state_and_input` 可能是新状态，有模型的输入时还包括着对应的输入或上下文

  ### 工具函数

  主要负责检查、准备模型可用的输入、调用模型、错误处理等方面。

  * `validate`
  * `prepare`
  * `invoke`
  * `error_handler`

  ## 状态变化

  * `:update_segment` 信息更新
    - 片段与输出不对应且需要通过模型推理获得新片段的结果时
    - 通过调用对应的工具函数来准备可以被推理模型使用的输入
    - 状态由 `:idle` 变为 `:required_update`
  * `:opt_segment` 不需要调用推理过程的更新
    - 比方说简单的拖拽时间
    - 状态保持 `:idle` ，但是要更新片段
  * `:update_result` 准备调用模型推理
    - 通过调用对应的工具函数来将片段的数据交由推理模型处理
    - `:required_update` -> `:do_update`
  * `:done` 得到结果，固定新的（Segment 与输出）
    - `:do_update` -> `:idle`
  * `:update_infer_graph` 模型更新
    - 比方说这个片段不再需要某某函数，或者是需要加上某某操作
    - 需要更多讨论

  把 `:required_update` 和 `:do_update` 两个状态分开，
  主要是需要向用户展示工程中的这一片段是否更新到了。

  如果纯粹从性能角度来考虑的话， OpenVPI 官方的编辑器就很不错（）

  ## 如何调用

  用人话讲这段就是怎么把这个模块放到你的应用里，等基本上实现完了再填坑。
  """
  # 这玩意儿可比 Glowworm 里那个 Runner 简单多了
  # [TODO)
  # - validate
  #   - 相关的代码交给对应的应用来写
  #   - 一类是确保用户输入的合法性；还有一类是在下游应用写出错误的代码时可以抛出错误
  # - 出现错误是要怎么处理？回滚并且保留相关数据？

  # 看上去更符合 Elixir 的命名
  alias :gen_statem, as: GenStateM
  @behaviour GenStateM

  # @states []
  # @actions []

  ## Mode

  @impl true
  def callback_mode(), do:
    # 简单来说就是把状态名当成函数
    :state_functions

  ## Public API

  def start(_args) do
    # GenStateM.start(:name, __MODULE__, {}, [])
  end

  def start_link(_args) do
    # GenStateM.start_link(:name, __MODULE__, {}, [])
  end

  # def stop()

  ## Callbacks

  @impl true
  def init(_args) do
    {:ok, :idle, nil}
  end

  # 准备推理模型的输入
  def idle(:update_segment) do
    # ...

    {:next_state, :required_update}
  end

  # 简单更新数据
  def idle(:opt_segment) do
    # ...

    {:keep_state, nil}
  end

  # 调用模型，等待结果
  def required_update(:update_result) do
    # ...

    {:next_state, :do_update}
  end

  # 得到结果，更新数据
  def do_update(:done) do
    # ...

    {:next_state, :idle}
  end

  ## Helpers

  def get_id(%QyCore.Segment{id: id}), do: id
end
