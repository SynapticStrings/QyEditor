defmodule QyCore.Scheduler.Context do
  alias QyCore.Param

  defstruct [
    :pending_steps,       # 还未执行的步骤列表 [{step, idx}]
    :available_keys,      # 当前已有的数据 keys (MapSet<Atom>)
    :params,              # 实际数据 (Map<Name, Param>)
    :running_steps,       # 正在运行中的 steps (用于并行控制)
    :history              # 执行历史 [{step_idx, output_params}
  ]

  # 初始化 Context
  def new(steps, initial_params) do
    # 将 Param 列表转为 Map 方便查询，同时提取 keys
    param_map = case initial_params do
      [_ | _] -> Map.new(initial_params, fn %Param{name: n} = p -> {n, p} end)
      %{} = m -> m
    end
    keys = MapSet.new(Map.keys(param_map))

    # 给 step 标号，方便后续追踪
    indexed_steps = Enum.with_index(steps)

    %__MODULE__{
      pending_steps: indexed_steps,
      available_keys: keys,
      params: param_map,
      running_steps: MapSet.new(),
      history: []
    }
  end

  def merge_params(%__MODULE__{} = ctx, new_params) when is_list(new_params) do
    new_map = Map.new(new_params, fn %Param{name: n} = p -> {n, p} end)
    new_keys = Map.keys(new_map)

    %{ctx |
      params: Map.merge(ctx.params, new_map),
      available_keys: MapSet.union(ctx.available_keys, MapSet.new(new_keys))
    }
  end

  # 标记某些 steps 已经运行完成，从 pending 中移除
  def mark_completed(%__MODULE__{} = ctx, step_indices) do
    remaining = Enum.reject(ctx.pending_steps, fn {_, idx} -> idx in step_indices end)
    %{ctx | pending_steps: remaining}
  end
end
