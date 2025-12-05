defmodule QyCore.Runner do
  import QyCore.Utilities, only: [ensure_full_step: 1]

  @default_middleware_stack [
    QyCore.Runner.Telemetry,
    QyCore.Runner.Core
  ]

  def run(step, ctx_params, opts, middleware_stack \\ @default_middleware_stack) do
    # 1. 静态分析 (准备元数据)
    {impl, in_keys, out_keys, step_opts} = ensure_full_step(step)

    # 2. 构建初始上下文 (Pipeline Context)
    initial_ctx = %{
      step_implementation: impl,
      in_keys: in_keys,
      out_keys: out_keys,
      step_default_opts: step_opts,
      inputs: prepare_inputs(in_keys, ctx_params),

      opts: opts,

      telemetry_meta: %{impl: impl, in_keys: in_keys, out_keys: out_keys}
    }

    # 3. 启动管道
    run_pipeline(middleware_stack, initial_ctx)
  end

  # 递归执行管道
  defp run_pipeline([], _ctx), do: {:error, :no_executor_plugin}

  # 最后一个中间件不需要 next 函数 (或者由 CoreExecutor 充当终结者)
  defp run_pipeline([plug | rest], ctx) do
    next_fn = fn next_ctx -> run_pipeline(rest, next_ctx) end
    plug.call(ctx, next_fn)
  end

  defp prepare_inputs(keys, params) when is_list(keys), do: Enum.map(keys, &Map.fetch!(params, &1))
  defp prepare_inputs(keys, params) when is_tuple(keys), do: Enum.map(Tuple.to_list(keys), &Map.fetch!(params, &1))
  defp prepare_inputs(key, params), do: Map.fetch!(params, key)
end
