defmodule QyCore.Executor do
  @callback execute(QyCore.Recipe.t(), [QyCore.Param.t()], keyword()) :: {:ok, map()} | {:error, term()}
end

defmodule QyCore.Executor.Serial do
  @behaviour QyCore.Executor
  alias QyCore.Scheduler

  def execute(recipe, initial_params, _opts \\ []) do
    {:ok, ctx} = Scheduler.build(recipe, initial_params)
    loop(ctx)
  end

  defp loop(ctx) do
    case Scheduler.next_ready_steps(ctx) do
      [] ->
        if Scheduler.done?(ctx), do: {:ok, Scheduler.get_results(ctx)}, else: {:error, :stuck}

      # 串行只取第一个
      [{step, idx} | _] ->
        {impl, in_keys, _out, step_opts, _meta} = ensure_full_step(step)

        # 准备参数
        inputs = prepare_inputs(in_keys, ctx.params)

        # 执行 (这里假设 impl 是一个实现了 QyCore.Recipe.Step 的模块)
        # TODO: 这里应该处理 prepare，但在 Serial 模式简化为运行时调用
        case impl.run(inputs, step_opts) do
          {:ok, output} ->
            loop(Scheduler.merge_result(ctx, idx, output))

          error -> error
        end
    end
  end

  defp prepare_inputs(keys, params) when is_list(keys) do
    Enum.map(keys, &Map.fetch!(params, &1))
  end
  defp prepare_inputs(key, params), do: Map.fetch!(params, key)

  defp ensure_full_step({impl, in_k, out_k}), do: {impl, in_k, out_k, [], []}
  defp ensure_full_step(full), do: full
end
