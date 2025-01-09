defmodule QyCore.Segment.StateM do
  # TODO: 状态需要进一步地解耦
  @moduledoc """
  对片段状态的管理，为了更直观地向用户展示片段的状态。

  为了确保片段能够实行增量式的渲染（输入变化时，只重新计算受影响的内容），
  故该负责片段状态管理的模块基于状态机设计。

  简单来说以下几步：

  1. 输入更新后并得到推理请求后挂起，等待推理模型可用
  2. 作为客户端与推理模型通信，等待推理的结果并更新
  3. 得到全部结果后更新片段的状态

  如果其中存在出错可能还会进行简单的错误处理。

  ## 状态变化

  ### 模型的状态

  主要是以下四种情况：

  * `:idle`
  * `:has_new_segment`
  * `:required_update`
  * `:execute_update`

  （需要考虑错误情况吗？）

  ### 外部事件

  | **原状态 \\ 后状态**          | **`:idle`**                  | **`:has_new_segment`** | **`:required_update`**               | **`:execute_update`** |
  |------------------------|------------------------------|------------------------|--------------------------------------|-----------------------|
  | **`:idle`**            | 更新片段且片段可以被直接更新               | 更新片段且片段需要更新            | /                                    | /                     |
  | **`:has_new_segment`** | 撤回；更新的最新片段可以被更新              | 更新片段且片段需要更新；请求推理失败     | `Caller` 发起请求、状态机向推理模型发送申请且得到推理模型的回复 | /                     |
  | **`:required_update`** | 更新的最新片段可以被更新且像推理模型发起取消请求并被同意 | 推理服务崩溃                 | 更新片段且片段需要更新                          | 推理服务触发事件，开始推理         |
  | **`:execute_update`**  | 更新参数（附带推理结束）                 | 推理服务崩溃或超时              | /                                    | 更新参数                  |

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

  状态机无法被单独使用。

  ### 前置项目

  #### 编写检查片段模型检查与更新的模块

  参见 `QyCore.Segment.Proto.LoadSegment` 模块。

  #### 编写连接模型与状态机的桥接模块

  参见 `QyCore.Segment.Proto.Executor` 模块。

  ### 手动管理

  #### 用例：最小化的状态机与更新服务

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
  @type states :: :idle | :has_new_segment | :required_update | :execute_update

  @typedoc "没有额外输入的数据"
  @type data_without_input_context :: Segment.segment_and_result()

  @typedoc "暂时只有新片段的数据"
  @type data_with_only_segment :: {Segment.segment_and_result(), Segment.t()}

  @typedoc "只有新片段以及 Caller 的 PID 时的数据"
  @type data_with_segment_and_caller ::
          {Segment.segment_and_result(), {Segment.t(), GenStateM.from()}}

  @typedoc "状态机的数据。"
  @type data ::
          data_without_input_context()
          | data_with_only_segment()
          | data_with_segment_and_caller()

  #
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

  # 不需要，这里出错一般是程序员的锅，直接 FunctionError 就行
  # 不好说，问题是要将【状态检查】这个职责归于什么地方
  # @typedoc "简单来说就是在不适合状态的触发不适合的事件"
  # @type invalid_request_to_statem_msg ::
  #         {:invalid_state, current_states :: states(), allowed_states :: [states()]}
  # @type send_invalid_req_action :: {:reply, GenStateM.from(), invalid_request_to_statem_msg()}

  ################################
  ## Mode
  ################################

  @impl true
  def callback_mode(),
    # 简单来说就是把状态名当成函数
    # 这样可以把代码梳理得更贴合业务
    do: [:handle_event_function, :state_enter]

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
          update_or_modify :: (Segment.t(), Segment.t() ->
                                 Segment.Proto.LoadSegment.same_situations()),
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
          segment_validator :: (Segment.t() -> Segment.Proto.Executor.segment_validate_status()),
          model_usability_check :: (-> Segment.Proto.Executor.inference_worker_status())
        ) ::
          any()
  def update(segment_id, validator, usability_check),
    do: GenStateM.call(name(segment_id), {:ready_for_update, validator, usability_check})

  # 准备最开始的推理

  @spec begin(Segment.id(), (Segment.t(), atom() | nil -> any())) :: any()
  def begin(segment_id, input_wrapper),
    do: GenStateM.call(name(segment_id), {:begin_inference, input_wrapper})

  # 添加结果
  # 咖啡不断加 加 加 加 加到厌倦~

  def attach(segment_id, result, :end),
    do: GenStateM.cast(name(segment_id), {:inference_end, result})

  # 有必要让状态机与推理服务持续通信
  def attach(segment_id, result, role),
    do: GenStateM.call(name(segment_id), {:recieve_partial, result, role})

  # 重置数据

  # def reset(segment_id), do: GenStateM.

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
  @type send_data_action :: {:reply, GenStateM.from(), data_and_state()}

  @impl true
  @spec handle_event({:call, GenStateM.from()}, get_data(), states(), data()) ::
          {:keep_state_and_data, send_data_action()}
  def handle_event({:call, from}, :get_data, state, data) do
    {state, data}
    |> reply_action(from)
    |> keep_state_and_data()
  end

  ## 进入 idle 时的检查
  # 从不同的状态都可以返回 idle

  def handle_event(:enter, _, :idle, data) do
    case data do
      {%Segment{}, %Segment{}} ->
        keep_state_and_data([])

      {{%Segment{}, %Segment{}} = pair, _extra_input} ->
        # 怎么解决错误信息
        keep_state(pair, [])
    end
  end

  ## 更新状态片段 / load_segment

  @typedoc "状态机将更新片段时获得的事件内容"
  @type load_segment_event_content ::
          {:load_segment, new_segment :: Segment.t(),
           update_or_modify :: (Segment.t(), Segment.t() ->
                                  Segment.Proto.LoadSegment.same_situations()),
           modifier :: (Segment.segment_and_result(), Segment.t() ->
                          Segment.segment_and_result())}

  @typedoc "状态机返回给发起请求的进程的信息类型"
  @type check_segment_result_msg ::
          {:ok, :required_update} | {:ok, :operate_segment_end} | {:error, term()}

  @typedoc "状态机将更新片段时返回给发起请求的进程的完整信息"
  @type send_load_status :: {:reply, GenStateM.from(), check_segment_result_msg()}

  @spec handle_event(
          {:call, GenStateM.from()},
          load_segment_event_content(),
          states(),
          data_with_only_segment() | data_without_input_context()
        ) ::
          {:keep_state_and_data, []}
          | {:keep_state_and_data, [send_data_action()]}
          | {:keep_state, data(), [send_load_status()]}
  def handle_event(
        {:call, from},
        {:load_segment, new_segment, simple_opt_validator, simple_opt_updator},
        :idle,
        pair
      ) do
    pair_and_new_segment = {pair, new_segment}

    case segment_infer?(pair_and_new_segment, new_segment, simple_opt_validator) do
      :required ->
        do_when_required_update(pair_and_new_segment, from)

      :update ->
        do_when_update_without_request(pair, new_segment, simple_opt_updator, from)

      {:error, reason} ->
        do_when_segment_offset_cause_error({:error, reason}, pair, from)
    end
  end

  def handle_event(
        {:call, from},
        {:load_segment, new_segment, simple_opt_validator, simple_opt_updator},
        :has_new_segment,
        {old_pair = {%Segment{}, %Segment{}}, _any}
      ) do
    pair_and_new_segment = {old_pair, new_segment}

    case segment_infer?(pair_and_new_segment, new_segment, simple_opt_validator) do
      :required ->
        do_when_required_update(pair_and_new_segment, from)

      :update ->
        do_when_update_without_request(old_pair, new_segment, simple_opt_updator, from)

      {:error, reason} ->
        do_when_segment_offset_cause_error({:error, reason}, old_pair, from)
    end
  end

  def handle_event(
        {:call, from},
        {:load_segment, new_segment, simple_opt_validator, simple_opt_updator},
        :required_update,
        {old_pair = {%Segment{}, %Segment{}}, _any}
      ) do
    pair_and_new_segment = {old_pair, new_segment}

    case segment_infer?(pair_and_new_segment, new_segment, simple_opt_validator) do
      :required ->
        # 只要没和 InferenceWorker 握手，更新还来得及
        do_when_required_update(pair_and_new_segment, from)

      :update ->
        # TODO: 发送请求

        do_when_update_without_request(old_pair, new_segment, simple_opt_updator, from)

      {:error, reason} ->
        # TODO: 发送请求

        do_when_segment_offset_cause_error({:error, reason}, old_pair, from)
    end
  end

  def handle_event(
        {:call, from},
        {:load_segment, _new_segment, _simple_opt_validator, _simple_opt_updator},
        :execute_update,
        _data
      ) do
    # 我现在正在想应该怎么处理这个消息
    :during_inference
    |> as_err()
    |> reply_action(from)
    |> keep_state_and_data()
  end

  # 后续处理

  def handle_event(:enter, :idle, :has_new_segment, data) do
    case data do
      {{_, _}, %Segment{}} -> keep_state_and_data([])
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

  # 需要讨论
  @typedoc "状态机将准备更新模型时获得的事件内容"
  @type ready_for_update_event_content ::
          {:ready_for_update,
           validator :: (Segment.t() -> Segment.Proto.Executor.segment_validate_status()),
           usability_check :: (-> Segment.Proto.Executor.inference_worker_status())}

  @typedoc "状态机在请求进程发起有关请求推理的事件后向请求进程发送动作的信息"
  @type send_model_and_segment_msg ::
          {:ok, :required_update}
          | {:error, :segment_not_valid}
          | {:error, :model_not_usable}
          | {:error, :no_new_segment}

  @typedoc "状态机向请求进程发送动作的完整信息"
  @type send_model_status_actions ::
          {:reply, GenStateM.from(), send_model_and_segment_msg()}

  @spec handle_event(
          {:call, GenStateM.from()},
          ready_for_update_event_content(),
          states(),
          data_with_only_segment() | data_without_input_context()
        ) ::
          {:keep_state_and_data, [send_model_status_actions()]}
          | {:next_state, :idle, data(), [send_model_status_actions()]}
          | {:next_state, :required_update, data(), [send_model_status_actions()]}
  def handle_event(
        {:call, from},
        {:ready_for_update, _validator, _usability_check},
        # 剩下两种状态就让它报错吧
        :has_new_segment,
        {%Segment{}, %Segment{}}
      ) do
    # 没有新片段你调用个啥
    send_new_segment =
      :no_new_segment
      |> as_err()
      |> reply_action(from)

    # 这种情况就不变了
    keep_state_and_data(send_new_segment)
  end

  # TODO: refrac this callback
  def handle_event(
        {:call, from},
        {:ready_for_update, validator, usability_check},
        state,
        {old_pair = {_, _}, new_segment}
      ) do
    # 无论如何都会干的事情：确定模型可用性
    with :ok <- usable?(usability_check) do
      case segment_valid?(validator, new_segment) do
        {:reject, _term} ->
          # 片段非法

          :logger.info("Segment is not valid")

          {:segment_not_valid, new_segment}
          # 把存在非法数据的片段丢回去
          |> as_err()
          |> reply_action(from)
          |> then(&next_state(:idle, old_pair, &1))

        :accept ->
          # 可用 -> 下一步
          case state do
            :idle ->
              reply_required_update =
                :required_update
                |> as_ok()
                |> reply_action(from)

              :logger.info("Segment is ready for update")

              # 可能还需要干一件事情，保留 from 进程信息以便后续发送消息
              next_state(:required_update, {old_pair, {new_segment, from}}, reply_required_update)

            _ ->
              keep_state_and_data({} |> reply_action(from))
          end
      end
    else
      # 不可用 -> 回复报错信息且返回 idle
      _ ->
        reply_model_unusable = :model_not_usable |> as_err() |> reply_action(from)

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

  # 开始推理 / begin_inference

  @type inference_begin_event :: {:inference_begin, (-> any())}

  @spec handle_event(
          {:call, GenStateM.from()} | :cast,
          inference_begin_event(),
          states(),
          data()
        ) :: any()
  # 因为推理服务不知道状态机的状态，所以必须每个状态都写出对应的处理方式
  def handle_event(
        {:call, from},
        {:begin_inference, _input_wrapper},
        :idle,
        _data
      ) do
    # 我也不知道要写啥
    "blabla"
    |> reply_action(from)
    |> keep_state_and_data()
  end

  def handle_event(
        {:call, _from},
        {:begin_inference, _input_wrapper},
        :ready_for_update,
        {{_, _}, {_input, _caller_ref}}
      ) do
    # ...
  end

  def handle_event({:call, from}, {:begin_inference, _input_wrapper}, :execute_update, _data) do
    # 不好意思，我已经有男朋友了（bushi）
    :during_inference
    |> as_err()
    |> reply_action(from)
    |> keep_state_and_data()
  end

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

  # 检查片段可能有的更新类型

  defp do_when_required_update(pair_with_new_segment, from) do
    :logger.info("Updating segment and required inference: #{inspect(pair_with_new_segment)}")

    :required_update
    |> as_ok()
    |> reply_action(from)
    |> then(&next_state(:has_new_segment, pair_with_new_segment, &1))
  end

  defp do_when_update_without_request(old_pair, new_segment, simple_opt_updator, caller) do
    :logger.info(
      "Updating segment: #{do_simple_update(old_pair, new_segment, simple_opt_updator) |> inspect}"
    )

    reply =
      :operate_segment_end
      |> as_ok()
      |> reply_action(caller)

    # 更新数据
    old_pair
    |> do_simple_update(new_segment, simple_opt_updator)
    # 甭管啥状态只要能够证明新片段跟旧数据的结果对应的话，返回到 :idle
    # 适用场景：回滚到此前的某状态
    |> then(&next_state(:idle, &1, reply))
  end

  defp do_when_segment_offset_cause_error({:error, reason}, old_pair, caller) do
    :logger.warning("Segment update error cause #{inspect(reason)}")

    # 发送错误信息
    {:error, reason}
    |> reply_action(caller)
    # 保持原来的数据
    |> then(&keep_state(old_pair, &1))
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

  # TODO: 在此确定到底是 {{_, _}, _} 还是 {_, _}
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

  defp reply_action(payload, from), do: reply(payload, from) |> then(&[&1])

  # 包装 callback | 状态

  defp keep_state_and_data(actions), do: {:keep_state_and_data, actions}

  defp keep_state(data, actions), do: {:keep_state, data, actions}

  defp next_state(new_state, new_data, actions), do: {:next_state, new_state, new_data, actions}

  # 包装 callback | 消息内容

  defp as_err(reason), do: {:error, reason}

  defp as_ok(reason), do: {:ok, reason}
  # defp as_ok(), do: :ok
end
