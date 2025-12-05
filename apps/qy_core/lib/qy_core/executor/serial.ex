defmodule QyCore.Executor.Serial do
  @moduledoc """
  串行执行器，实现 `QyCore.Executor` 行为。
  它按顺序执行 Recipe 中的步骤，每次只执行一个步骤，等待其完成后再执行下一个步骤。
  默认的执行器即为串行执行器。
  """
  @behaviour QyCore.Executor
  alias QyCore.{Scheduler, Param}
  import QyCore.Utilities, only: [ensure_full_step: 1, normalize_keys: 1]

  @impl true
  def execute(recipe, initial_params, _opts \\ []) do
    case Scheduler.build(recipe, initial_params) do
      {:ok, ctx} -> loop(ctx)
      {:error, reason} -> {:error, reason}
    end
  end

  defp loop(ctx, opts \\ []) do
    Scheduler.next_ready_steps(ctx)

    case Scheduler.next_ready_steps(ctx) do
      [] ->
        if Scheduler.done?(ctx) do
          {:ok, Scheduler.get_results(ctx)}
        else
          {:error, :stuck}
        end

      # 串行只取第一个
      [{step, idx} | _] ->
        {_impl, _in_keys, out_keys, _step_opts, _meta} = ensure_full_step(step)

        # 执行 (这里假设 impl 是一个实现了 QyCore.Recipe.Step 的模块)
        case QyCore.Executor.StepRunner.run(step, ctx.params, opts) do
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
end
