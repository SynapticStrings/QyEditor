defmodule QyCore.Executor.StepRunner do
  @moduledoc """
  负责运行单个 Step 的原子操作。
  封装了：输入准备、Hook 触发、Reporter 注入、输出重命名。
  """
  # TODO: 未来可考虑集成 Telemetry，简化 Hook 机制
  # TODO: 对于存在两步的 steps ，考虑将 prepare 与 run 分离调用
  alias QyCore.Param
  import QyCore.Utilities, only: [ensure_full_step: 1]

  @spec run(
          QyCore.Recipe.Step.t(),
          any(),
          nil | maybe_improper_list() | map()
        ) :: {:error, any()} | {:ok, [QyCore.Param.t()] | QyCore.Param.t()}
  def run(step, ctx_params, opts) do
    {impl, in_keys, out_keys, step_opts} = ensure_full_step(step)

    telemetry_metadata = %{
      impl: impl,
      in_keys: in_keys,
      out_keys: out_keys
    }

    # --- Telemetry: Start ---
    :telemetry.execute(
      [:qy_core, :step, :start],
      %{system_time: System.system_time()},
      telemetry_metadata
    )
    start_time = System.monotonic_time()

    inputs = prepare_inputs(in_keys, ctx_params)

    reporter_fn = fn progress, payload ->
      :telemetry.execute(
        [:qy_core, :step, :progress],
        %{progress: progress}, # Measurements
        Map.merge(telemetry_metadata, %{payload: payload}) # Metadata
      )
    end

    injected_opts =
      step_opts
      |> Keyword.merge(opts[:resources] || [])
      # 假设 resources 在 opts 里
      |> Keyword.put(:__reporter__, reporter_fn)

    try do
      case run_step(impl, inputs, injected_opts) do
        {:ok, raw_output} ->
          renamed = align_output_names(raw_output, out_keys)

          duration = System.monotonic_time() - start_time

          # --- Telemetry: Stop (Success) ---
          :telemetry.execute(
            [:qy_core, :step, :stop],
            %{duration: duration},
            telemetry_metadata
          )

          {:ok, renamed}

        {:error, reason} ->
          # --- Telemetry: Stop (Error) ---
          duration = System.monotonic_time() - start_time
          :telemetry.execute(
            [:qy_core, :step, :exception],
            %{duration: duration},
            Map.put(telemetry_metadata, :reason, reason)
          )

          {:error, reason}
      end
    rescue
      e ->
        duration = System.monotonic_time() - start_time
        stack = __STACKTRACE__

        # --- Telemetry: Exception (Crash) ---
        :telemetry.execute(
          [:qy_core, :step, :exception],
          %{duration: duration},
          Map.merge(telemetry_metadata, %{kind: :error, reason: e, stacktrace: stack})
        )

        {:error, e}
    catch
      kind, reason ->
         # 处理 throw/exit
         duration = System.monotonic_time() - start_time
         :telemetry.execute(
          [:qy_core, :step, :exception],
          %{duration: duration},
          Map.merge(telemetry_metadata, %{kind: kind, reason: reason})
        )
        {:error, {kind, reason}}
    end
  end

  defp align_output_names(%Param{} = param, out_key) when is_atom(out_key) do
    %{param | name: out_key}
  end

  defp align_output_names(params, out_keys) when is_list(params) do
    keys = List.wrap(out_keys)
    Enum.zip_with(params, keys, fn param, key -> %{param | name: key} end)
  end

  defp align_output_names(%Param{} = param, [out_key]) do
    [%{param | name: out_key}]
  end

  defp align_output_names(param, out_key) when is_tuple(param) do
    align_output_names(Tuple.to_list(param), Tuple.to_list(out_key))
  end

  defp prepare_inputs(keys, params) when is_list(keys), do: Enum.map(keys, &Map.fetch!(params, &1))
  defp prepare_inputs(keys, params) when is_tuple(keys), do: Enum.map(Tuple.to_list(keys), &Map.fetch!(params, &1))
  defp prepare_inputs(key, params), do: Map.fetch!(params, key)

  defp run_step(impl, inputs, opts) when is_atom(impl) do
    if Code.ensure_loaded?(impl) and function_exported?(impl, :run, 2) do
      impl.run(inputs, opts)
    else
      {:error, {:invalid_step_implementation, impl}}
    end
  end

  defp run_step(run_fun, inputs, opts) when is_function(run_fun, 2) do
    run_fun.(inputs, opts)
  end

  defp run_step(_, _, _), do: {:error, :invalid_step_implementation}
end
