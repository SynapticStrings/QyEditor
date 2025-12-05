defmodule QyCore.Recipe.Graph do
  @moduledoc """
  负责分析 Recipe 的拓扑结构，计算执行顺序，并进行静态检查。
  """

  alias QyCore.Recipe.Step

  @type error :: {:missing_inputs, step_idx :: integer(), missing :: [term()]}
               | {:cycle_detected, remaining_steps :: [Step.t()]}

  @doc """
  对步骤进行拓扑排序。

  输入：原始的步骤列表，以及（可选的）初始已知参数列表。
  输出：{:ok, 排序后的步骤列表} 或 {:error, 原因}
  """
  @spec sort_steps([Step.t()], [atom()]) :: {:ok, [Step.t()]} | {:error, error()}
  def sort_steps(steps, initial_params \\ []) do
    # 1. 预处理：给每个步骤打上索引，方便报错定位，并规范化 input/output keys
    indexed_steps =
      steps
      |> Enum.with_index()
      |> Enum.map(fn {step, idx} ->
        {_impl, in_keys, out_keys} = Step.extract_schema(step)
        # 规范化：将单个 atom 转为 list，tuple 转为 list
        needed = normalize_keys(in_keys)
        provides = normalize_keys(out_keys)

        %{
          original: step,
          index: idx,
          needed: MapSet.new(needed),
          provides: MapSet.new(provides)
        }
      end)

    # 2. 初始可用资源集合
    available = MapSet.new(initial_params)

    # 3. 开始解析
    do_sort(indexed_steps, available, [])
  end

  # 递归基：没有剩余步骤了，解析完成
  defp do_sort([], _available, acc) do
    {:ok, Enum.reverse(acc)}
  end

  defp do_sort(remaining, available, acc) do
    # 尝试在剩余步骤中，找到一个“所有输入都已被满足”的步骤
    {ready, not_ready} = Enum.split_with(remaining, fn %{needed: needed} ->
      MapSet.subset?(needed, available)
    end)

    case ready do
      [] ->
        # 如果还有步骤剩余，但没有一个是 Ready 的，说明存在循环依赖或缺少输入
        analyze_stuck_reason(remaining, available)

      _ ->
        # 将 Ready 的步骤加入结果集，并将其产出加入可用资源池
        # 这里我们就简单的按列表顺序取，实际上如果支持并发，这里 ready 的都是可以并行的

        # 这里的 new_available 累加了这些步骤的所有产出
        new_produced =
          ready
          |> Enum.map(& &1.provides)
          |> Enum.reduce(MapSet.new(), &MapSet.union/2)

        new_available = MapSet.union(available, new_produced)

        # 提取原始 step 结构用于返回
        ready_steps = Enum.map(ready, & &1.original)

        do_sort(not_ready, new_available, Enum.reverse(ready_steps) ++ acc)
    end
  end

  defp analyze_stuck_reason(remaining, available) do
    # 简单分析：检查第一个卡住的步骤缺什么
    first_stuck = List.first(remaining)
    missing =
      MapSet.difference(first_stuck.needed, available)
      |> MapSet.to_list()

    if missing != [] do
      {:error, {:missing_inputs, first_stuck.index, missing}}
    else
      # 如果看起来不缺输入（理论上不应走到这，除非逻辑有误），或是纯粹的死锁/环
      {:error, {:cycle_detected, Enum.map(remaining, & &1.original)}}
    end
  end

  # 辅助函数：将 keys 统一转为 list
  defp normalize_keys(keys) when is_atom(keys), do: [keys]
  defp normalize_keys(keys) when is_tuple(keys), do: Tuple.to_list(keys)
  defp normalize_keys(keys) when is_list(keys), do: keys
end
