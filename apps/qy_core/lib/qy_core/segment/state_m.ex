defmodule QyCore.Segment.StateM do
  # 参考资料
  # https://www.erlang.org/doc/system/statem.html
  @moduledoc """
  对片段状态的管理，为了更直观地向用户展示片段的状态。

  为了确保片段能够实行增量式的渲染（输入变化时，只重新计算受影响的内容），
  故该负责片段状态管理的模块基于状态机设计。

  简单来说以下几步：

  1. 输入更新时挂起，等待推理模型可用
  2. 等待推理的结果
  3. 得到结果后更新片段的状态

  如果其中存在出错可能还会进行简单的错误处理。

  ## 数据本体

  数据等同于状态机包含的所有数据，主要是：

  `{{current_state, inference_result}, tools_func, maybe_new_state_and_input}`

  * `{current_state, inference_result}` 状态与输出的对应，弄成这个元组是因为可能在别的地方用到
    - 最开始一般就是 `{nil, nil}`
  * `tools_func` 工具函数（参见下面的「工具函数」一节）
  * `maybe_new_state_and_input` 可能是新状态，有模型的输入时还包括着对应的输入或上下文
    - 最开始就是准备要推理出结果的输入
    - 如果输入输出对应，数据没有此片段（也就是元组只有两个元素）

  ### 工具函数

  主要负责检查、准备模型可用的输入、调用模型、错误处理等方面。

  * `validate/1`
    - 检查数据（片段）是否合法
    - 返回格式 `{:ok, data}` 或者 `{:error, reason}`
  * `invoke/1`
    - 调用推理模型，其接受【模型的】输入
  * `error_handler/2`
    - 输入 `{:error, reason}, context`
    - 决定结束状态机并返回报错信息还是其他
  * `persist/1` 持久化保存

  ### 新状态上下文（`maybe_new_state_and_input`）

  一般来说，新状态的数据是片段的数据，但是也可能是其他数据（主要是模型的输入/能够通过片段得到输入的函数）。

  ## 状态变化

  ### 模型的状态

  主要是以下三种情况：

  * `:idle`
  * `:required_update`
  * `:do_update`

  （需要考虑错误情况吗？）

  ### 状态变化的情景

  一般情景：

  * `:update_segment` 信息更新
    - 片段与输出不对应且需要通过模型推理获得新片段的结果时
    - 通过调用对应的工具函数来准备可以被推理模型使用的输入
    - 状态由 `:idle` 变为 `:required_update`
    - `maybe_new_state_and_input` 为新片段
      - 一般是 `{input, func/1}` 或者 `{input, nil}` ，其中后者的 `nil` 将会在准备推理时被 `model_input` 取代
      - 其中 `model_input = func.(input)` ，`func` 是一个 arity 的函数，其通过片段得到输入
  * `:opt_segment` 不需要调用推理过程的更新
    - 比方说简单的拖拽时间
    - 状态保持 `:idle` ，但是要更新片段，但也仅仅是更新了片段而已，不需要调用推理
  * `:update_result` 准备调用模型推理
    - 通过调用对应的工具函数来将片段的数据交由推理模型处理
    - `:required_update` -> `:do_update`
  * `:recieve_partial` 得到部分结果
    - 一般是模型的输出是部分的，需要继续等待
    - `:do_update` -> `:required_update`
    - 递归性地更新结果
  * `:done` 得到结果，固定新的（Segment 与输出）
    - `:do_update` -> `:idle`
    - [TODO) 需要深入讨论可能会修改 Segment 本身的情况（例如音高参数，其既可以由模型生成，有可能被手动修改）
  * `:update_infer_graph` 模型更新
    - 比方说这个片段不再需要某某函数，或者是需要加上某某操作
    - 需要更多讨论

  错误处理：

  * `segment_invalid` 状态存在非法数据
  * `inference_crash` 推理过程出现崩溃

  把 `:required_update` 和 `:do_update` 两个状态分开，
  主要是需要向用户展示工程中的这一片段是否更新到了的情况。

  如果纯粹从性能角度来考虑的话， 使用 OpenUTAU 或是 OpenVPI 的编辑器就很不错（）

  ## 用法

  基于通过 `QyCore.Segment.Manager` 来管理。
  """

  alias QyCore.Segment

  # 看上去更符合 Elixir 的命名
  alias :gen_statem, as: GenStateM
  @behaviour GenStateM

  @typedoc "状态机进程的名字和片段的名字保持一致，一一对应"
  @type segment_id :: Segment.id()

  @type name :: {:global, {:segment, segment_id()}}

  @typedoc "状态机的状态"
  @type states :: :idle | :required_update | :do_update

  @typedoc "一般情况下状态机的状态变化"
  @type normal_actions :: :update_segment | :opt_segment | :update_result | :done

  @typedoc "错误处理的有关状态"
  @type error_actions :: :segment_invalid | :inference_crash

  @typedoc "状态机的状态变化"
  @type actions :: normal_actions() | error_actions()

  @typedoc "新状态相关上下文"
  @type maybe_new_state_and_input ::
          {Segment.segment_and_result(), function() | any() | nil}

  @typedoc "状态机的数据"
  @type container ::
          {Segment.segment_and_result(), keyword(function())}
          | {Segment.segment_and_result(), keyword(function()),
             maybe_new_state_and_input()}

  @typedoc "状态机保存的所有内容"
  @type data :: {states(), container()}

  ## Mode

  @impl true
  def callback_mode(),
    # 简单来说就是把状态名当成函数
    do: :state_functions

  ## Public API

  # 启动

  def start(init_segment) do
    {name, container} = preparing_initial(init_segment)

    GenStateM.start(name, __MODULE__, {container}, [])
  end

  def start_link(init_segment) do
    {name, container} = preparing_initial(init_segment)

    GenStateM.start_link(name, __MODULE__, container, [])
  end

  # 停止

  def stop(pid) when is_pid(pid), do: GenStateM.stop(pid)
  def stop(segment_or_id) do
    segment_or_id
    |> Segment.purely_id()
    |> name()
    |> GenStateM.stop()
  end

  # 获得数据

  def get_container(segment_id) do
    # 这个得重写
    GenStateM.call(name(segment_id), :get_container)
  end

  # def get_segment(segment_id) do
    # segment_id
    # |> get_container()
  # end

  # def get_result(segment_id) do
  # end

  # def done?(segment_id) do
    # segment_id
    # |> get_container()
    # |> check_done()
  # end

  # 更新数据
  # def update(id, new_segment, opts \\ [])

  # def update(id, opts \\ []), do: GenStateM.cast()

  ## Callbacks

  @impl true
  def init(container) do
    # 进程在启动时不进行状态更新
    {:ok, :idle, container}
  end

  # 获得状态机的数据
  # 本质上是一个发送消息的 Action
  defp exec_send_data(from, data) do
    IO.inspect(from, label: :from)
    # Send current data to `from`

    {:keep_state, data}
  end

  def idle({:call, from}, :get_container, data), do: exec_send_data(from, data)
  def required_update({:call, from}, :get_container, data), do: exec_send_data(from, data)
  def do_update({:call, from}, :get_container, data), do: exec_send_data(from, data)

  # 准备推理模型的输入
  def idle({:update_segment, new_segment}, old_container) do

    # 需要一个向推理模型发送请求的 Event

    # 数据变化： {_, _} -> {_, _, new_segment}
    {segment_pair, func} = old_container

    {:next_state, :required_update, {segment_pair, func, new_segment}}
  end

  # 简单更新数据
  # 通常是只涉及 offset 的更新
  def idle({:opt_segment, new_segment}, old_container) do
    # 数据变化：{_, _, new_segment} -> {_, _, {new_segment, input_or_func}}
    {{_old_segment, result}, func} = old_container

    {:keep_state, {{new_segment, result}, func}}
  end

  # 片段非法
  def idle({:segment_invalid, _invalid_segment}, container) do
    # 发送错误信息

    # 保持原来的数据
    {:keep_state, container}
  end

  # 调用模型，等待结果
  def required_update(:update_result) do
    # ...

    # 为了保留出错时可能出现的上下文，所以数据不变，只变状态
    {:next_state, :do_update}
  end

  def do_update({:recieve_partial, _partial_result}) do
    # ...

    # 数据变化：需要讨论
    {:keep_state, :newSegmentAndResult}
  end

  # 得到结果，更新数据
  def do_update({:done, _new_result}) do
    # ...

    # 数据变化：{{_old_segment, _old_result}, _, {new_segment, input_or_func}} -> {{new_segment, new_result}, _}
    {:next_state, :idle, :newSegmentAndResult}
  end

  # 模型出错
  def do_update({:error, :reason}) do
    # ...

    # [TODO) Action 改成 stop
    # 将 {new_segment, input_or_func} 交由 error_handler 处理
    # {:next_state, :idle, nil}
  end

  # 推理模型崩溃
  # 停止应用
  # def when_crash(_reason, _container) do

  # def AnyState(:inference_crash) do bla bla

  @impl true
  def terminate(_reason, _current_state, _data) do
    # ...
  end
  # 包括出现不可逆错误时停止
  # 以及正常结束时的清理工作

  # def handle_event

  ## Inner API and Helpers

  # defp validate_segment(data) do

  # defp prepare_input({_, _, {segment, input_or_func}}) when is_function(input_or_func), do: input_or_func.(segment)
  # defp prepare_input({_, _, {_segment, input_or_func}}), do: input_or_func

  # defp invoke_inference(data) do

  # defp handle_error(data) do

  # defp check_done({_segment_and_result, _functions}), do: true
  # defp check_done({_segment_and_result, _functions, _maybe_new_state_and_input}), do: false

  # def get_id(%Segment{id: id}), do: id

  defp name(id), do: {:global, {:segment, id}}

  def preparing_initial(initial_segment = %Segment{id: segment_id}, func \\ []) do
    # [TODO) prepare function tools.
    {name(segment_id), {{nil, nil}, func, initial_segment}}
  end

  def get_func_from_data(_data, _role) do
    # ...
  end
end
