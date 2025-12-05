defmodule QyCore.Scheduler do
  @moduledoc """
  调度器模块，负责管理和调度 Recipe 中的步骤执行顺序。
  """
  alias QyCore.Scheduler.Context
  alias QyCore.{Recipe, Param}
  import QyCore.Utilities, only: [normalize_keys_to_set: 1]

  @doc """
  初始化执行上下文。
  """
  @spec build(QyCore.Recipe.t(), maybe_improper_list()) ::
          {:error, {:missing_inputs, any(), list()}}
          | {:ok, QyCore.Scheduler.Context.t()}
  def build(%Recipe{} = recipe, initial_params) when is_list(initial_params) do
    # 1. 构建 initial_map
    initial_map =
      Map.new(initial_params, fn param ->
        # 兼容 Struct 或 Map，只要有 name 字段即可
        {Map.get(param, :name), param}
      end)

    initial_keys = Map.keys(initial_map)

    # 预检步骤依赖关系是否有环或输入缺如
    case Recipe.Graph.validate(recipe.steps, initial_keys) do
      :ok -> do_build(recipe, initial_map)
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_build(recipe, initial_map) do
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
      {_impl, in_keys, _out} = extract_step_schema(step)

      needed = normalize_keys_to_set(in_keys)

      MapSet.subset?(needed, ctx.available_keys)
    end)
  end

  @doc """
  状态更新：当 Step 执行完后，将结果合并回 Context。
  """
  def merge_result(%Context{} = ctx, step_idx, output_params) do
    # 1. 移除 pending
    new_pending = Enum.reject(ctx.pending_steps, fn {_, idx} -> idx == step_idx end)

    # 2. 合并数据
    new_params_map =
      case output_params do
        p = %Param{} ->
          %{p.name => p}

        [_ | _] ->
          Map.new(output_params, fn %Param{name: n} = p -> {n, p} end)
      end

    merged_params = Map.merge(ctx.params, new_params_map)

    # 3. 更新 available_keys
    new_keys = Map.keys(new_params_map)
    updated_keys = MapSet.union(ctx.available_keys, MapSet.new(new_keys))

    %{
      ctx
      | pending_steps: new_pending,
        params: merged_params,
        available_keys: updated_keys,
        history: ctx.history ++ [step_idx]
    }
  end

  def done?(%Context{pending_steps: []}), do: true
  def done?(%Context{}), do: false

  def get_results(%Context{params: params}), do: params

  def get_results(%Context{params: params}, key),
    do:
      Enum.map(params, fn {k, v} -> if k == key, do: v, else: nil end)
      |> Enum.reject(&is_nil/1)

  defp extract_step_schema(step) do
    case step do
      {impl, in_k, out_k} -> {impl, in_k, out_k}
      {impl, in_k, out_k, _opts} -> {impl, in_k, out_k}
      other -> QyCore.Recipe.Step.extract_schema(other)
    end
  end
end
