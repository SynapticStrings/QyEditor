defmodule QyCore.Executor do
  @callback execute(QyCore.Recipe.t(), [QyCore.Param.t()], keyword()) ::
              {:ok, map()} | {:error, term()}
end

defmodule QyCore.Executor.Serial do
  @behaviour QyCore.Executor
  alias QyCore.{Scheduler, Param}

  def execute(recipe, initial_params, _opts \\ []) do
    case Scheduler.build(recipe, initial_params) do
      {:ok, ctx} -> loop(ctx)
      {:error, reason} -> {:error, reason}
    end
  end

  defp loop(ctx) do
    case Scheduler.next_ready_steps(ctx) do
      [] ->
        if Scheduler.done?(ctx),
          do: {:ok, Scheduler.get_results(ctx)},
          else:
            IO.inspect(ctx, label: "StuckContext"); {:error, :stuck}

      # 串行只取第一个
      [{step, idx} | _] ->
        {impl, in_keys, out_keys, step_opts, _meta} = ensure_full_step(step)

        # 准备参数
        inputs = prepare_inputs(in_keys, ctx.params)

        # 执行 (这里假设 impl 是一个实现了 QyCore.Recipe.Step 的模块)
        # TODO: 这里应该处理 prepare，但在 Serial 模式简化为运行时调用
        case run_step(impl, inputs, step_opts) do
          {:ok, raw_output} ->
            renamed_output = align_output_names(raw_output, out_keys)

            loop(Scheduler.merge_result(ctx, idx, renamed_output))

          error ->
            error
        end
    end
  end

  defp align_output_names(%Param{} = param, out_key) when is_atom(out_key) do
    %{param | name: out_key}
  end

  # 情况 2: 列表输出，out_keys 是列表/元组
  defp align_output_names(params, out_keys) when is_list(params) do
    keys = normalize_keys(out_keys)

    # 严格按顺序重命名
    # 如果数量不一致这里会报错，这正好起到了校验作用
    Enum.zip_with(params, keys, fn param, key ->
      %{param | name: key}
    end)
  end

  # 容错：如果 Step 返回了单个 Param 但 Recipe 定义了单元素列表 [:name]
  defp align_output_names(%Param{} = param, [out_key]) do
    [%{param | name: out_key}]
  end

  defp prepare_inputs(keys, params) when is_list(keys) do
    Enum.map(keys, &Map.fetch!(params, &1))
  end

  defp prepare_inputs(key, params), do: Map.fetch!(params, key)

  defp run_step(impl, inputs, opts) do
    # 处理模块实现或函数实现
    if Code.ensure_loaded?(impl) and function_exported?(impl, :run, 2) do
      impl.run(inputs, opts)
    else
      # 简单的容错，防止 impl 不是模块的情况（虽然 schema 校验过）
      {:error, {:invalid_step_implementation, impl}}
    end
  end

  defp ensure_full_step({impl, in_k, out_k}), do: {impl, in_k, out_k, [], []}
  defp ensure_full_step({impl, in_k, out_k, opts}), do: {impl, in_k, out_k, opts, []}
  defp ensure_full_step({impl, in_k, out_k, opts, meta}), do: {impl, in_k, out_k, opts, meta}

  defp normalize_keys(k) when is_list(k), do: k
  defp normalize_keys(k) when is_tuple(k), do: Tuple.to_list(k)
  defp normalize_keys(k), do: [k]
end
