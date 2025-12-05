defmodule QyCore.Recipe do
  @moduledoc """
  定义一个处理流程（菜谱）。
  """

  alias QyCore.Recipe.Step

  @type t :: %__MODULE__{
          steps: [Step.t()],
          name: atom() | nil,
          opts: keyword()
        }
  defstruct steps: [], name: nil, opts: []

  def new(steps, opts \\ []) do
    # TODO: 这里可以做更多的验证和预处理
    %__MODULE__{
      steps: steps,
      name: Keyword.get(opts, :name),
      opts: opts
    }
  end

  @doc """
  全局注入选项 (支持深度注入)。
  """
  def assign_options(%__MODULE__{} = recipe, selector, new_opts) do
    walk(recipe, fn step ->
      {impl, in_k, out_k, current_opts, meta} = normalize_step(step)

      # 判断是否匹配
      match? = case selector do
        :all -> true
        ^impl -> true # 匹配模块
        _ -> false
      end

      if match? do
        # 合并选项
        merged_opts = Keyword.merge(current_opts, new_opts)
        {impl, in_k, out_k, merged_opts, meta}
      else
        step
      end
    end)
  end

  @doc """
  对 Recipe 进行深度遍历。
  func 会被应用到树中的每一个 Step 上。
  如果 Step 是嵌套的 (NestedStep)，会自动递归进入其内部的 recipe。
  """
  def walk(%__MODULE__{steps: steps} = recipe, func) when is_function(func, 1) do
    new_steps = Enum.map(steps, fn step ->
      modified_step = func.(step)

      process_nested(modified_step, func)
    end)

    %{recipe | steps: new_steps}
  end

  defp process_nested(step, func) do
    {impl, in_k, out_k, opts, meta} = normalize_step(step)

    if is_atom(impl) and function_exported?(impl, :nested?, 0) and impl.nested?() do
      case Keyword.get(opts, :recipe) do
        %__MODULE__{} = inner_recipe ->
          new_inner_recipe = walk(inner_recipe, func)

          new_opts = Keyword.put(opts, :recipe, new_inner_recipe)
          {impl, in_k, out_k, new_opts, meta}

        _ ->
          step
      end
    else
      step
    end
  end

  defp normalize_step({impl, in_k, out_k}), do: {impl, in_k, out_k, [], []}
  defp normalize_step({impl, in_k, out_k, opts}), do: {impl, in_k, out_k, opts, []}
  defp normalize_step({impl, in_k, out_k, opts, meta}), do: {impl, in_k, out_k, opts, meta}
end
