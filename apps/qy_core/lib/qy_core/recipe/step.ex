defmodule QyCore.Recipe.Step do
  # 没必要太过奢求所谓的「优雅」
  # 简单就可以
  @enforce_keys [:name_tuple, :init, :call]
  @type t :: %__MODULE__{
          name: any(),
          name_tuple: name_keywords(),
          init: function(),
          call: function()
        }
  defstruct [:name, :name_tuple, :init, :call]

  @type name_keywords :: {tuple(), tuple()}

  def prelude(params, input_key) do
    {
      params,
      input_key
      |> Tuple.to_list()
      |> Enum.map(fn k -> Map.get(params, k) end)
      |> List.to_tuple()
    }
  end

  def exec_step({params, input}, func, opts) do
    {params, func.(input, opts)}
  end

  def postlude({params, result}, output_key) do
    result
    |> then(&(Enum.zip(Tuple.to_list(output_key), Tuple.to_list(&1)) |> Enum.into(%{})))
    |> then(&Map.merge(params, &1))
  end

  @doc """
  ## Example

      iex> result_param = param
      ...> |> exec(step_1, [])
      ...> |> exec(step_2, [])
      ...> |> exec(step_3, [])
  """
  def exec(
        params,
        %__MODULE__{
          name_tuple: {input_key, output_key},
          init: init_func,
          call: call_func
        },
        opts \\ []
      ) do
    params
    |> prelude(input_key)
    |> exec_step(call_func, init_func.(opts))
    |> postlude(output_key)
  end

  def extract(%QyCore.Segment{} = segment), do: segment.params
  def inject(%QyCore.Segment{} = segment, params), do: %{segment | params: params}
end
