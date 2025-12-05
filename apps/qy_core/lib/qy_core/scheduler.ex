defmodule QyCore.Scheduler do
  alias QyCore.Scheduler.Context
  alias QyCore.{Recipe, Param}

  @doc """
  初始化执行上下文。
  """
  def build(%Recipe{} = recipe, initial_params) when is_list(initial_params) do
    # 预检步骤依赖关系是否有环或输入缺如
    case Recipe.Graph.sort_steps(recipe.steps, initial_params) do
      {:ok, _} -> do_build(recipe, initial_params)
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_build(recipe, initial_params) do
    initial_map = Map.new(initial_params, fn %Param{name: n} = p -> {n, p} end)

    context = %Context{
      pending_steps: Enum.with_index(recipe.steps),
      running_steps: MapSet.new(),
      available_keys: MapSet.new(Map.keys(initial_map)),
      params: initial_map,
      history: []
    }

    {:ok, context}
  end

  @doc """
  核心调度函数：找出所有“原料已就绪”且“未执行”的步骤。
  """
  def next_ready_steps(%Context{} = ctx) do
    # 遍历 pending，看谁的 needed 是 available 的子集
    Enum.filter(ctx.pending_steps, fn {step, _idx} ->
      {_impl, in_keys, _out} = Recipe.Step.extract_schema(step)
      needed = normalize_keys(in_keys)

      MapSet.subset?(MapSet.new(needed), ctx.available_keys)
    end)
  end

  @doc """
  状态更新：当 Step 执行完后，将结果合并回 Context。
  """
  def merge_result(%Context{} = ctx, step_idx, output_params) do
    # 1. 移除 pending
    new_pending = Enum.reject(ctx.pending_steps, fn {_, idx} -> idx == step_idx end)

    # 2. 合并数据
    new_params_map = case output_params do
      p = %Param{} -> %{p.name => p}
      [_ | _] ->
        Map.new(output_params, fn %Param{name: n} = p -> {n, p} end)
    end
    merged_params = Map.merge(ctx.params, new_params_map)

    # 3. 更新 available_keys
    new_keys = Map.keys(new_params_map)
    updated_keys = MapSet.union(ctx.available_keys, MapSet.new(new_keys))

    %{ctx |
      pending_steps: new_pending,
      params: merged_params,
      available_keys: updated_keys,
      history: ctx.history ++ [step_idx]
    }
  end

  def done?(%Context{pending_steps: []}), do: true
  def done?(%Context{}), do: false

  def get_results(%Context{params: params}), do: params
  def get_results(%Context{params: params}, key), do:
    Enum.map(params, fn {k, v} -> if k == key, do: v, else: nil end)
    |> Enum.reject(&is_nil/1)

  # 辅助：规范化 Key
  defp normalize_keys(keys) when is_list(keys), do: keys
  defp normalize_keys(keys) when is_tuple(keys), do: Tuple.to_list(keys)
  defp normalize_keys(key), do: [key]
end
