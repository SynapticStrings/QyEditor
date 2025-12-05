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

      raw_params: ctx_params, # 全部数据池
      inputs: nil,            # 待填充
      opts: opts,             # 外部注入的 opts (resources 等)

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
end
