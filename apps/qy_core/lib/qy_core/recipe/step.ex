defmodule QyCore.Recipe.Step do
  # 这个模块的 call/2 回调的输出以及输出强制使用 tuple 而非 list
  # 主要是因为 tuple 无法被修改，更容易把函数的逻辑确定下来
  # 但是其中需要反复将 tuple 与 list 来回转化确实有点拟人了
  @enforce_keys [:name_tuple, :init, :call]
  @type t :: %__MODULE__{
          name: any(),
          name_tuple: name_keywords(),
          init: function(),
          call: function()
        }
  defstruct [:name, :name_tuple, :init, :call]

  alias QyCore.Recipe.Step
  alias QyCore.Param

  @type options :: any()

  @type name_keywords :: {tuple(), tuple()}

  @type inner_params :: %{atom() => [any()]}

  @spec prelude(inner_params(), tuple()) :: {inner_params(), tuple()}
  def prelude(params, input_key) do
    {
      params,
      input_key
      |> :erlang.tuple_to_list()
      |> Enum.map(fn k -> Map.get(params, k) end)
      |> :erlang.list_to_tuple()
    }
  end

  @spec exec_step({inner_params(), tuple()}, (any(), any() -> any()), options()) ::
          {inner_params(), tuple()}
  def exec_step({params, input}, func, opts) do
    {params, func.(input, opts)}
  end

  @spec postlude({inner_params(), tuple()}, tuple()) :: inner_params()
  def postlude({params, result}, output_key) do
    result
    |> then(
      &(
        :erlang.tuple_to_list(output_key)
        |> Enum.zip(:erlang.tuple_to_list(&1))
        |> Enum.into(%{})
      )
    )
    |> then(&Map.merge(params, &1))
  end

  @doc """
  执行 `Step` 。

  ## Example

      iex> result_param = param
      ...> |> exec(step_1, [])
      ...> |> exec(step_2, [])
      ...> |> exec(step_3, [])
  """
  def exec(params, step, opts \\ [])

  @spec exec(inner_params(), Step.t(), options()) :: inner_params()
  def exec(
        params,
        %__MODULE__{
          name_tuple: {input_key, output_key},
          init: init_func,
          call: call_func
        },
        opts
      )
      when is_function(init_func, 1) and is_map(params) do
    params
    |> prelude(input_key)
    |> exec_step(call_func, init_func.(opts))
    |> postlude(output_key)
  end

  @spec exec({inner_params(), %{atom() => Param.t()}}, Step.t(), options()) ::
          map()
  def exec(
        {params, raw_params},
        %__MODULE__{
          name_tuple: {input_key, output_key},
          init: init_func,
          call: call_func
        },
        extra_opts
      )
      when is_function(init_func, 2) and is_map(params) do
    # 这块有点难评
    # 但是对之前的程序没有副作用，不妨先留着
    # 说不好主要是因为确定两套 inner_param_map 和 outter_param_map 再丢进来
    # ……有点耗内存
    # 有些很大的数据可能在 Param 里就是一个 Reference ，在这个函数的范围内负责推理的进程
    # 可以把这个 Reference 的内容提取出来再进行计算
    # 但在不考虑这种情形的一般情况下确实有点多此一举了
    {_, related_raw_param} = prelude(raw_params, input_key)

    updated_param = params
    |> prelude(input_key)
    # 在这里，init/2 可能会用到对应 %Params
    |> exec_step(call_func, init_func.(related_raw_param, extra_opts))
    |> postlude(output_key)

    {raw_params, updated_param}
  end

  # def extract(%QyCore.Segment{} = segment), do: segment.params
  # def inject(%QyCore.Segment{} = segment, params), do: %{segment | params: params}
end
