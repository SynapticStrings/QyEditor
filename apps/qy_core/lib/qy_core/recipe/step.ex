defmodule QyCore.Recipe.Step do
  @enforce_keys [:name_tuple, :init, :call]
  @type t :: %__MODULE__{
          name: any(),
          name_tuple: name_keywords(),
          init: function(),
          call: function()
        }
  defstruct [
    :name,
    :name_tuple,
    :init,
    :call
  ]

  alias QyCore.Recipe.Step

  @type options :: any()

  @type context :: any()

  @type input_name :: tuple()

  @type output_name :: tuple()

  @type name_keywords :: {input_name(), output_name()}

  @type inner_params :: %{atom() => [any()]}

  @spec prelude(inner_params(), input_name()) :: {inner_params(), tuple()}
  def prelude(params, input_key) do
    {
      params,
      input_key
      |> :erlang.tuple_to_list()
      |> Enum.map(fn k -> Map.get(params, k) end)
      |> :erlang.list_to_tuple()
    }
  end

  @spec prelude(inner_params(), context(), tuple()) :: {inner_params(), context(), tuple()}
  def prelude(params, context, input_key) do
    {params, inputs} = prelude(params, input_key)

    {params, context, inputs}
  end

  @spec exec_step({inner_params(), tuple()}, (any(), any() -> any()), options()) ::
          {inner_params(), tuple()}
  def exec_step({params, input}, func, opts) do
    {params, func.(input, opts)}
  end

  @spec exec_step(
          {inner_params(), context(), tuple()},
          (any(), options(), context() -> {any(), any()}),
          options()
        ) ::
          {inner_params(), tuple(), context()}
  def exec_step({params, context, input}, func, opts) do
    {output, new_context} = func.(input, opts, context)

    {params, output, new_context}
  end

  @spec postlude({inner_params(), tuple()}, output_name()) :: inner_params()
  def postlude({params, result}, output_key) do
    result
    |> then(
      &(:erlang.tuple_to_list(output_key)
        |> Enum.zip(:erlang.tuple_to_list(&1))
        |> Enum.into(%{}))
    )
    |> then(&Map.merge(params, &1))
  end

  @spec postlude({inner_params(), tuple(), context()}, output_name()) ::
          {inner_params(), context()}
  def postlude({params, result, context}, output_key),
    do: {postlude({params, result}, output_key), context}

  @spec exec({inner_params(), context()} | inner_params(), Step.t()) ::
          {inner_params(), context()} | inner_params()
  @doc """
  执行 `Step` 。

  ## Example

  一般情况

      iex> result_param = param
      ...> |> exec(step_1, [])
      ...> |> exec(step_2, [])
      ...> |> exec(step_3, [])

  需要通用上下文（例如下游的步骤需要上游的）

      iex> {result_param, context_after} = {param, conrext_before}
      ...> |> exec(step_1, [])
      ...> |> exec(step_2, [])
      ...> |> exec(step_3, [])
      ...> |> exec(step_4, [])
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

  # 放一个额外的上下文在这
  # 和 opts 不一样的是
  # 这里的上下文也在后续更新 %Params{} 会被用到
  @spec exec({inner_params(), context()}, Step.t(), options()) :: {inner_params(), context()}
  def exec(
        {params, context},
        %__MODULE__{
          name_tuple: {input_key, output_key},
          init: init_func,
          call: call_func
        },
        extra_opts
      )
      when is_function(init_func, 2) and is_function(call_func, 3) do
    params
    |> prelude(context, input_key)
    |> exec_step(call_func, init_func.(context, extra_opts))
    |> postlude(output_key)
  end
end
