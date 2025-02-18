defmodule QyCore.Recipe.Step do
  @moduledoc """
  `Step` 是最小可执行、存有数据更新的步骤，其对 `t:inner_params/0` 或
  `t:inner_params_with_context/0` 进行操作。

  一个合格的 `%Step{}` **必须**包含以下的键值：

  * `:name_tuple` 一个包含输入以及输出变量名的元组
  * `:prepare` 一个负责处理参数的函数，其和 `Plug.init/1` 一致
  * `:call` 一个依靠参数或共享上下文负责处理输入的函数，其和 `Plug.call/2` 一致
    * 如果需要上下文的话需要三个 arity

  此外，还有一个包括名字的 `:name` ，其会在 `QyCore.Recipe.Graph` 中被用到。
  """

alias QyCore.Recipe.Step

  @enforce_keys [:name_tuple, :prepare, :call]
  @type t :: %__MODULE__{
          name: any(),
          name_tuple: name_keywords(),
          prepare: function(),
          call: function()
        }
  defstruct [
    :name,
    :name_tuple,
    :prepare,
    :call
  ]

  defmacro __using__(_opts) do
    # 添加行为
    # 实现 inject/0 函数，其会返回一个 %Step{} 对象
    quote do
      import QyCore.Recipe.Step

      @behaviour QyCore.Recipe.Step
    end
  end

  @typedoc "选项"
  @type options :: any()

  @typedoc "上下文"
  @type context :: any()

  @typedoc "输入的名字"
  @type input_name :: tuple()

  @typedoc "输出的名字"
  @type output_name :: tuple()

  @type name_keywords :: {input_name(), output_name()}

  @type inner_params :: %{atom() => [any()]}

  @type inner_params_with_context :: {inner_params(), context()}

  @callback name_tuple :: name_keywords()

  @callback prepare(tuple(), options()) :: tuple()

  # 思考剩下两个 callback 应该怎么实现

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
  @spec exec(inner_params() | inner_params_with_context(), Step.t()) ::
          inner_params() | inner_params_with_context()
  def exec(params, step, opts \\ [])

  @spec exec(inner_params(), Step.t(), options()) :: inner_params()
  def exec(
        params,
        %__MODULE__{
          name_tuple: {input_key, output_key},
          prepare: init_func,
          call: call_func
        },
        opts
      )
      when is_function(init_func, 1) and is_function(call_func, 2) and is_map(params) do
    params
    |> prelude(input_key)
    |> exec_step(call_func, init_func.(opts))
    |> postlude(output_key)
  end

  @spec exec(inner_params_with_context(), Step.t(), options()) :: inner_params_with_context()
  def exec(
        {params, context},
        %__MODULE__{
          name_tuple: {input_key, output_key},
          prepare: init_func,
          call: call_func
        },
        extra_opts
      )
      when is_function(init_func, 1) and is_function(call_func, 3) do
    params
    |> prelude(context, input_key)
    |> exec_step(call_func, init_func.(extra_opts))
    |> postlude(output_key)
  end

  defp prelude(params, input_key) do
    {
      params,
      input_key
      |> :erlang.tuple_to_list()
      |> Enum.map(fn k -> Map.get(params, k) end)
      |> :erlang.list_to_tuple()
    }
  end

  defp prelude(params, context, input_key) do
    {params, inputs} = prelude(params, input_key)

    {params, context, inputs}
  end

  defp exec_step({params, input}, func, opts) do
    {params, func.(input, opts)}
  end

  defp exec_step({params, context, input}, func, opts) do
    {output, new_context} = func.(input, opts, context)

    {params, output, new_context}
  end

  defp postlude({params, result}, output_key) do
    result
    |> then(
      &(:erlang.tuple_to_list(output_key)
        |> Enum.zip(:erlang.tuple_to_list(&1))
        |> Enum.into(%{}))
    )
    |> then(&Map.merge(params, &1))
  end

  defp postlude({params, result, context}, output_key),
    do: {postlude({params, result}, output_key), context}

end

defmodule QyCore.Recipe.Step.Fusion do
  # 将很多 Steps 进行融合
end
