defmodule QyCore.Executor.StepRunner do
  @moduledoc """
  负责运行单个 Step 的原子操作。
  封装了：输入准备、Hook 触发、Reporter 注入、输出重命名。
  """
  alias QyCore.Param
  import QyCore.Utilities, only: [ensure_full_step: 1, normalize_keys: 1]

  # 定义 Hook 规范 (使用标准 Telemetry 后可简化，这里先保留回调模式演示逻辑)
  def run(step, ctx_params, opts) do
    # 1. 解包与标准化
    {impl, in_keys, out_keys, step_opts, _meta} = ensure_full_step(step)

    # 2. 准备输入
    inputs = prepare_inputs(in_keys, ctx_params)

    # 3. 触发 Start Hook (或 Telemetry)
    trigger_hook(opts, :on_step_start, {impl})

    # 4. 注入 Reporter
    # injected_opts = inject_reporter(step_opts, opts, impl)

    # 5. 实际运行
    result =
      # try do
        run_step(impl, inputs, step_opts)
      # rescue
      #   e -> {:error, e}
      # end

    # 6. 处理结果
    case result do
      {:ok, raw_output} ->
        renamed = align_output_names(raw_output, out_keys)
        trigger_hook(opts, :on_step_finish, {impl, renamed})
        {:ok, renamed}

      {:error, reason} ->
        trigger_hook(opts, :on_step_error, {impl, reason})
        {:error, reason}
    end
  end

  defp trigger_hook(hooks, event, args) do
    # 从 opts[:hooks] 中查找对应的回调函数并执行
    case Keyword.get(hooks, event) do
      cb when is_function(cb) ->
        # 使用 apply 动态调用，支持不同数量的参数
        try do
          apply(cb, Tuple.to_list(args))
        rescue
          # 避免 Hook 里的错误导致主流程崩溃
          _ -> :ignore
        end

      _ ->
        :ok
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

  defp prepare_inputs(keys, params) when is_tuple(keys) do
    Enum.map(Tuple.to_list(keys), &Map.fetch!(params, &1))
  end

  defp prepare_inputs(key, params), do: Map.fetch!(params, key)


  defp run_step(impl, inputs, opts) when is_atom(impl) do
    if Code.ensure_loaded?(impl) and function_exported?(impl, :run, 2) do
      if function_exported?(impl, :prepare, 1) do
        with {:ok, prepared_opts} <- impl.prepare(opts),
           {:ok, result} <- impl.run(inputs, prepared_opts) do

           {:ok, result}
        else
          {:error, reason} -> {:error, reason}
        end
      else
        impl.run(inputs, opts)
      end

    else
      # 简单的容错，防止 impl 不是模块的情况（虽然 schema 校验过）
      {:error, {:invalid_step_implementation, impl}}
    end
  end

  defp run_step({prepare_fun, run_fun}, inputs, opts)
       when is_function(prepare_fun, 1) and is_function(run_fun, 2) do
    case prepare_fun.(opts) do
      {:ok, prepared_opts} -> run_fun.(inputs, prepared_opts)
      {:error, reason} -> {:error, reason}
    end
  end

  defp run_step(run_fun, inputs, opts) when is_function(run_fun, 2) do
    run_fun.(inputs, opts)
  end

  defp run_step(_, _, _), do: {:error, :invalid_step_implementation}
end
