defmodule QyCore.Segment.StateM do
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

  `{{current_state, inference_result}, maybe_new_state_and_input}`

  * `{current_state, inference_result}` 状态与输出的对应，弄成这个元组是因为可能在别的地方用到
    - 最开始一般就是 `{nil, nil}`
  * `maybe_new_state_and_input` 可能是新状态，有模型的输入时还包括着对应的输入或上下文
    - 最开始就是准备要推理出结果的输入
    - 如果输入输出对应，数据没有此片段（也就是元组只有两个元素）

  ### 工具函数

  主要负责检查、准备模型可用的输入、调用模型、错误处理等方面。作为 event_content 的上下文引入。

  ### 新状态上下文（`maybe_new_state_and_input`）

  一般来说，新状态的数据是片段的数据，但是也可能是其他数据（主要是模型的输入/能够通过片段得到输入的函数）。

  ## 状态变化

  ### 模型的状态

  主要是以下三种情况：

  * `:idle`
  * `:required_update`
  * `:execute_update`

  （需要考虑错误情况吗？）

  ### 外部事件

  | 事件前状态\\事件后状态 | `:idle` | `:required_update` | `:execute_update` |
  |------------------------|---------|--------------------|-------------------|
  | `:idle` | `:load_segment` | `:ready_for_update` | 违法 |
  | `:required_update` | `:loss_connect_with_model` | `:load_segment` | `:inference_begin` |
  | `:execute_update` | `:inference_end` 或 `:inference_crash` | 违法 | `:recieve_partial` |

  一般情景：

  * `:update_infer_graph` 模型更新
    - 比方说这个片段不再需要某某函数，或者是需要加上某某操作
    - 需要更多讨论

  把 `:required_update` 和 `:execute_update` 两个状态分开，
  主要是需要向用户展示工程中的这一片段是否更新到了的情况。

  如果纯粹从性能角度来考虑的话， 使用 OpenUTAU 或是 OpenVPI 的编辑器就很不错（）

  #### 更新片段

  * `:load_segment` 信息更新
    - 片段与输出不对应且需要通过模型推理获得新片段的结果时
    - 通过调用对应的工具函数来准备可以被推理模型使用的输入
    - `maybe_new_state_and_input` 为新片段
    - 可能包括不需要调用推理过程的更新
      - 比方说简单的拖拽时间
    - 状态保持 `:idle` 或 `:required_update`
    - 关于要否单纯更新片段以及调用推理需要结合工具函数的判断

  #### 准备更新

  * `:ready_for_update`
    - 数据必须是 `{{_, _}, _}` 的形式
    - 对后续的 `maybe_new_state_and_input` 做准备
    - 状态由 `:idle` 变为 `:required_update` 或是保持在 `:required_update`

  #### 与模型的通信

  一般情形：

  * `:inference_begin` 准备调用模型推理
    - 通过调用对应的工具函数来将片段的数据交由推理模型处理
    - `:required_update` -> `:execute_update`
  * `:recieve_partial` 得到部分结果
    - 一般是模型的输出是部分的，需要继续等待
    - `:execute_update` -> `:required_update`
    - 递归性地更新结果
  * `:inference_end` 得到结果，固定新的（Segment 与输出）
    - `:execute_update` -> `:idle`

  错误处理：

  * `:lose_connect_with_model` 与模型失去连接
  * `:inference_crash` 推理过程出现崩溃

  ## 用法

  ### 前置项目

  #### 编写检查片段模型检查与更新的模块

  参见 `QyCore.Segment.Proto.LoadSegment` 模块。

  #### 编写连接模型与状态机的桥接模块

  参见 `QyCore.Segment.Proto.Executor` 模块。

  ### 手动管理

  TODO

  ### 基于通过 `QyCore.Segment.Manager` 来管理

  TODO
  """

  alias QyCore.Segment

  # 看上去更符合 Elixir 的命名
  alias :gen_statem, as: GenStateM
  @behaviour GenStateM

  @typedoc "状态机进程的名字和片段的名字保持一致，一一对应"
  @type segment_id :: Segment.id()

  @typedoc "状态机进程的名字，其通常由私有函数 name/1 由 `segment_id` 生成"
  @type name :: {:global, {:segment, segment_id()}}

  @typedoc "状态机的状态"
  @type states :: :idle | :required_update | :execute_update

  @typedoc """
  状态机的数据。

  其存在两种形式：

  * `{mannual_segment = %Segment{}, generated_segment = %Segment{}}` *没有未被模型推理的新数据的片段组合*
  * `{{mannual_segment = %Segment{}, generated_segment = %Segment{}}, some_new_segment_and_context}` *存在未被模型推理的新数据的片段组合*
  """
  @type data ::
          Segment.segment_and_result()
          | {Segment.segment_and_result(), maybe_new_state_and_input()}

  #
  # inference_begin 事件

  @type inference_begin_event :: :inference_begin

  # recieve_partial 事件

  @type recieve_partial_event :: :recieve_partial

  # inference_end 事件

  @type inference_end_event :: :inference_end

  ## 其他类型

  @typedoc "状态机被动接受事件的事件内容"
  @type events_from_caller ::
          load_segment_event_content() | ready_for_update_event_content() | get_data()

  @typedoc "来自状态机发起请求业务时接收的事件的内容"
  @type events_from_model ::
          inference_begin_event()
          | recieve_partial_event()
          | inference_end_event()
          | :lose_connect_with_model
          | :inference_crash

  @typedoc "状态机的事件集合"
  @type events :: events_from_caller() | events_from_model()

  @typedoc "状态机的动作"
  @type actions_from_segment_stm :: send_data_action() | send_model_status_actions()

  @typedoc """
  新状态相关上下文：

  * 新片段
  * 新片段+调用状态机的进程（用于对其发消息使用）
  * 新片段+调用状态机的进程+其他（还没确定好）
  """
  @type maybe_new_state_and_input ::
          Segment.t() | {Segment.t(), pid()} | {Segment.t(), pid(), any()}

  #
  @type invalid_request_to_statem_msg ::
          {:invalid, current_states :: states(), allowed_states :: [states()]}

  @type send_invalid_req_action :: {:reply, pid(), invalid_request_to_statem_msg()}

  ################################
  ## Mode
  ################################

  @impl true
  def callback_mode(),
    # 简单来说就是把状态名当成函数
    # TODO: 改成 [:hendle_event_function, :enter_state] 吧
    # 这样可以把代码梳理得更贴合业务
    do: :handle_event_function

  ################################
  ## Public API
  ################################

  # 启动

  @spec start(Segment.t()) :: {:ok, pid()} | {:error, term()}
  def start(init_segment) do
    {name, data} = preparing_initial(init_segment)

    :logger.info("Starting segment state machine: #{inspect(name)}")

    GenStateM.start(name, __MODULE__, data, [])
  end

  @spec start_link(Segment.t()) :: {:ok, pid()} | {:error, term()}
  def start_link(init_segment) do
    {name, data} = preparing_initial(init_segment)

    :logger.info("Starting segment state machine: #{inspect(name)}")

    GenStateM.start_link(name, __MODULE__, data, [])
  end

  def child_spec(init_segment = %Segment{}) do
    %{
      id: Segment.purely_id(init_segment.id),
      start: {__MODULE__, :start_link, [init_segment]},
      restart: :permanent,
      shutdown: 5000,
      type: :worker
    }
  end

  # 停止

  @spec stop(pid() | Segment.id()) :: :ok
  def stop(pid) when is_pid(pid), do: do_stop(pid)

  def stop(segment_or_id) do
    segment_or_id
    |> Segment.purely_id()
    |> name()
    |> do_stop()
  end

  defp do_stop(id_or_pid) do
    :logger.info("Stopping segment state machine: #{inspect(id_or_pid)}")

    GenStateM.stop(id_or_pid)
  end

  # 获得数据
  @doc "获得状态机的内部数据"
  @spec get_data(Segment.id()) :: data_and_state()
  def get_data(segment_id) do
    # 这个得重写
    GenStateM.call(name(segment_id), :get_data)
  end

  # 更新片段

  @spec load(
          Segment.id(),
          Segment.t(),
          update_or_modify :: (Segment.t(), Segment.t() -> same_situations()),
          modifier :: (Segment.segment_and_result(), Segment.t() ->
                         Segment.segment_and_result())
        ) :: any()
  def load(
        segment_id,
        new_segment = %Segment{},
        update_or_modify \\ &Segment.update_or_modify/2,
        modifier \\ &Segment.modifier/2
      ) do
    segment_id
    |> name()
    |> GenStateM.call({:load_segment, new_segment, update_or_modify, modifier})
  end

  # 准备推理

  @spec update(
          Segment.id(),
          segment_validator :: (Segment.t() -> check_data_status_msg()),
          model_usability_check :: (-> model_usability_msg())
        ) ::
          any()
  def update(segment_id, validator, usability_check),
    do: GenStateM.call(name(segment_id), {:ready_for_update, validator, usability_check})

  # 添加结果

  def attach(segment_id, result, role), do: GenStateM.cast(name(segment_id), {result, role})

  # 存在错误
  # def raise_error(segment_id, reason, context), do: GenStateM.cast(name(segment_id), {:error, reason})

  ################################
  ## Callbacks
  ################################

  @impl true
  def init(data) do
    # 进程在启动时不进行状态更新
    {:ok, :idle, data}
  end

  ## 获得数据 / get_data 事件

  @typedoc "状态机将获得数据时获得的事件内容"
  @type get_data :: :get_data

  @typedoc "在状态机获得数据时返回给发起请求的进程的信息类型，包括此时的状态以及数据"
  @type data_and_state() :: {states(), data()}

  @typedoc "状态机向请求进程发送动作的信息"
  @type send_data_action :: {:reply, pid(), data_and_state()}

  @impl true
  @spec handle_event({:call, {pid(), :gen_statem.reply_tag()}}, get_data(), states(), data()) ::
          {:keep_state_and_data, send_data_action()}
  def handle_event({:call, from}, :get_data, state, data) do
    send_action =
      {state, data}
      |> reply(from)

    keep_state_and_data([send_action])
  end

  ##  状态片段 / load_segment

  @typedoc "状态机将更新片段时获得的事件内容"
  @type load_segment_event_content ::
          {:load_segment, new_segment :: Segment.t(),
           update_or_modify :: (Segment.t(), Segment.t() -> same_situations()),
           modifier :: (Segment.segment_and_result(), Segment.t() ->
                          Segment.segment_and_result())}

  @typedoc "旧片段与新片段的比较情况，其决定了是否需要调用推理模型"
  @type same_situations :: :required | :update | {:error, term()}

  @typedoc "状态机返回给发起请求的进程的信息类型"
  @type check_segment_result_msg ::
          {:ok, :required_update} | {:ok, :operate_segment_end} | {:error, term()}

  @typedoc "状态机将更新片段时返回给发起请求的进程的完整信息"
  @type send_load_status :: {:reply, pid(), check_segment_result_msg()}

  @spec handle_event(
          {:call, GenStateM.from()},
          load_segment_event_content(),
          states(),
          data()
        ) ::
          {:keep_state_and_data, []}
          | {:keep_state_and_data, [send_data_action()]}
          | {:keep_state_and_data, [send_invalid_req_action()]}
          | {:keep_state, data(), [send_load_status()]}
  def handle_event(
        {:call, _from},
        {:load_segment, _new_segment, _simple_opt_validator, _simple_opt_updator},
        :execute_update,
        _data
      ) do
    # ???
    actions = [{:reply, :execute_update, [:idle, :required_update]}]

    keep_state_and_data(actions)
  end

  def handle_event(
        {:call, from},
        {:load_segment, new_segment, simple_opt_validator, simple_opt_updator},
        _state,
        old_data
      ) do
    data =
      case old_data do
        {_mannual_segment = %Segment{}, _generated_segment} ->
          {old_data, new_segment}

        {old_pair = {%Segment{}, %Segment{}}, _any} ->
          {old_pair, new_segment}
      end

    {{old_segment, old_result}, _} = old_data

    # 检查是否是简单的更新
    case segment_infer?(data, new_segment, simple_opt_validator) do
      :required ->
        :logger.info("Updating segment and required inference: #{inspect(data)}")

        keep_state(data, {:ok, :required_update} |> reply(from) |> then(&[&1]))

      :update ->
        :logger.info(
          "Updating segment: #{do_simple_update({old_segment, old_result}, new_segment, simple_opt_updator) |> inspect}"
        )

        # 直接更新数据
        old_data
        |> do_simple_update(new_segment, simple_opt_updator)
        |> keep_state({:ok, :operate_segment_end} |> reply(from) |> then(&[&1]))

      # 发送错误信息
      {:error, reason} ->
        :logger.warning("Segment update error cause #{inspect(reason)}")

        {:error, reason}
        |> reply(from)
        |> then(&[&1])
        # 保持原来的数据
        |> then(&keep_state(old_data, &1))
    end
  end

  # 调用者、状态机、推理服务三者关联

  # 虽然以下动作由状态机与负责推理的模型交互
  # 但是从用户的视角来看，还是来源于状态机的动作
  # 其大致逻辑如下（没有考虑失败以及错误捕捉的情况）
  #
  # +--------+                       +--------+                  +-------+
  # | Caller | -------update-------> | StateM |                  | Model |
  # +--------+                       +--------+                  +-------+
  #    |                               |        validator         |
  #    |                               |  -and-usability_check->  |-do_check\
  #    |                               |                          |<--------/
  #    |                               |    <--accept-and-ok--    |
  #    |      <--ready_for_update-     |                          |
  #    |                               |                          * when free
  #    |                               |   <--inference_begin--   |
  #    |                               |        --data--->        |
  #    |                               |                          |-do_inference-\
  #    |                               |                          |<-------------/
  #    |                               |   <--recieve_partial-    |
  #    |        <--updated--           |                          |
  #    |                               |   --new_req_with_data->  |
  #    |                               |                          |-do_inference-\
  #    |             ...               |          ...             |<-------------/
  #    |                               |   <--inference_end--     |
  #    |        <---done---            |                          |
  #    |                               * to idle                  |
  #
  # 可以看到，后续用户的进程会受到来自状态机的消息，哪怕并没有相关的命令
  # 故此写在这里
  # TODO

  # 准备更新 / ready_for_update 事件

  @typedoc "状态机将准备更新模型时获得的事件内容"
  @type ready_for_update_event_content ::
          {:ready_for_update, validator :: (Segment.t() -> check_data_status_msg()),
           usability_check :: (-> model_usability_msg())}

  @typedoc """
  检查数据是否合法的消息，由状态模型的进程向状态机发送。

  在此设立此类型是为了定义状态机所接受的信息的类型。

  其也是 `QyCore.Segment.Proto.Executor。validate_segment_with_model/1` 回调的返回类型。
  """
  @type check_data_status_msg :: :accpet | {:reject, term()}

  @typedoc """
  模型可行性的类型，由状态机的进程向状态机发送。

  此类型以及其 arity 还没有确定，所以暂时只有一个像那回事的返回值。
  """
  @type model_usability_msg :: :ok | {:error, term()}

  @typedoc "状态机在请求进程发起有关请求推理的事件后向请求进程发送动作的信息"
  @type send_model_and_segment_msg ::
          {:ok, :required_update}
          | {:error, :segment_not_valid}
          | {:error, :model_not_usable}
          | {:error, :no_new_segment}

  @typedoc "状态机向请求进程发送动作的完整信息"
  @type send_model_status_actions ::
          {:reply, pid(), send_model_and_segment_msg()}

  @spec handle_event(
          {:call, GenStateM.from()},
          ready_for_update_event_content(),
          states(),
          data()
        ) ::
          {:keep_state_and_data, [send_model_status_actions()]}
          | {:next_state, :idle, data(), [send_model_status_actions()]}
          | {:next_state, :required_update, data(), [send_model_status_actions()]}
  def handle_event(
        {:call, from},
        {:ready_for_update, _validator, _usability_check},
        state,
        {%Segment{}, %Segment{}} = data
      ) do
    # 没有新片段你调用个啥
    send_new_segment = {:error, :no_new_segment} |> reply(from) |> then(&[&1])

    case state do
      :idle ->
        # 这种情况就不变了
        keep_state_and_data(send_new_segment)

      _ ->
        next_state(:idle, data, send_new_segment)
    end
  end

  def handle_event(
        {:call, from},
        {:ready_for_update, validator, usability_check},
        state,
        {old_pair = {_, _}, new_segment}
      ) do
    # 无论如何都会干的事情：确定模型可用性
    with :ok <- usable?(usability_check) do
      case segment_valid?(validator, new_segment) do
        :accept ->
          # 可用 -> 下一步
          case state do
            :idle ->
              reply_required_update = {:ok, :required_update} |> reply(from) |> then(&[&1])

              :logger.info("Segment is ready for update")

              # 可能还需要干一件事情，保留 from 进程信息以便后续发送消息
              next_state(:required_update, {old_pair, {new_segment, from}}, reply_required_update)

            _ ->
              keep_state_and_data({} |> reply(from) |> then(&[&1]))
          end

        {:reject, _term} ->
          # 片段非法

          :logger.info("Segment is not valid")

          {:error, :segment_not_valid}
          |> reply(from)
          |> then(&[&1])
          |> then(&keep_state(old_pair, &1))
      end
    else
      # 不可用 -> 返回报错信息
      # 不可用 -> 返回 idle
      _ ->
        reply_model_unusable = {:error, :model_not_usable} |> reply(from) |> then(&[&1])

        :logger.info("Model is not usable")

        case state do
          :idle ->
            keep_state_and_data(reply_model_unusable)

          _state ->
            next_state(:idle, {old_pair, new_segment}, reply_model_unusable)
        end
    end
  end

  # 进入 required_update 的状态检查
  # 是否保留了通信相关的进程 id
  # def handle_event(:enter, oldState, :required_update, data) do
  # 检查数据是否形如 {{_, _}, {_new_segment, _conn_helpers}}
  # end

  # 接收消息 / recieve_partial

  # 接收消息 / inference_end

  @impl true
  def terminate(reason, _current_state, _data) do
    :logger.info("Segment state machine terminated with #{inspect(reason)}")
  end

  # 包括出现不可逆错误时停止
  # 以及正常结束时的清理工作

  ################################
  ## Routines
  #
  # do some dirty work stuff
  ################################

  # 准备初始数据

  defp preparing_initial(initial_segment = %Segment{id: segment_id}) do
    {
      segment_id |> Segment.purely_id() |> name(),
      # 这里必须要确保 id 一致
      {{%Segment{id: segment_id}, %Segment{id: segment_id}}, initial_segment}
    }
  end

  # 与推理服务通信时用到的函数

  # defp send_data_to_caller(caller_pid, payload), do: send(caller_pid, payload)

  # 更新结果时会被用到的函数

  ################################
  ## Helpers and Private Functions
  ################################

  # 常用函数

  defp name(id), do: {:global, {:segment, id}}

  # 在 idle 以及 required_update 的 load_segments 事件下会被用到的函数

  defp segment_infer?(
         {{old_segment, _old_result}, _maybe_new_segment},
         new_segment,
         update_or_modify_validator
       )
       when is_function(update_or_modify_validator, 2) do
    update_or_modify_validator.(old_segment, new_segment)
  end

  defp do_simple_update(old_data, new_segment, modifier) when is_function(modifier, 2) do
    modifier.(old_data, new_segment)
  end

  # 在 idle 的 ready_for_update 事件下会被用到的函数

  defp segment_valid?(validator, segment) when is_function(validator, 1) do
    validator.(segment)
  end

  defp usable?(func) when is_function(func, 0) do
    func.()
  end

  # defp usable?(func, context) when is_function(func, 1) do
  #   func.(context)
  # end

  # 包装 callback | 动作

  defp reply(payload, from), do: {:reply, from, payload}

  # 包装 callback | 状态

  defp keep_state_and_data(actions), do: {:keep_state_and_data, actions}

  defp keep_state(data, actions), do: {:keep_state, data, actions}

  defp next_state(new_state, new_data, actions), do: {:next_state, new_state, new_data, actions}

  # 包装 callback | 消息内容

  #
end
