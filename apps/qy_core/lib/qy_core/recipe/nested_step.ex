defmodule QyCore.Recipe.NestedStep do
  @moduledoc """
  将一个完整的 Recipe 封装为一个独立的 Step 以实现嵌套操作。

  需要的选项:

  - :recipe -> 要运行的内部 Recipe 结构体
  - :executor (可选) -> 指定运行子流程的执行器模块 (默认 QyCore.Executor.Serial)
  - :input_map (可选) -> %{parent_name => child_name} 参数名映射
  - :output_map (可选) -> %{child_name => parent_name} 结果名映射

  ## Examples

      nested_step = {QyCore.Recipe.NestedStep,
        recipe: inner_recipe,
        executor: QyCore.Executor.Parallel,
        input_map: %{"parent_param1" => "child_paramA"},
        output_map: %{"child_resultX" => "parent_result1"}
      }
  """

  use QyCore.Recipe.Step

  def prepare(opts) do
    inner_recipe = Keyword.fetch!(opts, :recipe)
    executor = Keyword.get(opts, :executor, QyCore.Executor.Serial)
    input_map = Keyword.get(opts, :input_map, %{})
    output_map = Keyword.get(opts, :output_map, %{})

    {:ok, [
      recipe: inner_recipe,
      executor: executor,
      input_map: input_map,
      output_map: output_map
    ]}
  end

  def run(input_params, [
        recipe: inner_recipe,
        executor: executor,
        input_map: input_map,
        output_map: output_map
      ]) do
    # 1. 准备输入
    # 将父层传进来的 Params 重命名为子层需要的名字
    child_initial_params =
      input_params
      |> List.wrap()
      |> Enum.map(fn param ->
        # 如果有映射就改名，没有就保持原名
        new_name = Map.get(input_map, param.name, param.name)
        %{param | name: new_name}
      end)

    # 2. 启动子流程
    # 这是一个递归调用，但发生在 Executor 层面
    case executor.execute(inner_recipe, child_initial_params) do
      {:ok, inner_results} ->
        # inner_results 是 %{name => Param}

        # 3. 提取输出
        # 根据 output_map 或默认规则，从子结果中提取父层需要的数据
        # 这里的 output_map key 是子层名字，value 是父层名字

        final_outputs =
          if map_size(output_map) > 0 do
            # 如果定义了映射，只提取映射中指定的
            Enum.map(output_map, fn {child_name, parent_name} ->
              case Map.fetch(inner_results, child_name) do
                {:ok, param} -> %{param | name: parent_name}
                :error -> raise "Nested Recipe missing expected output: #{child_name}"
              end
            end)
          else
            # 如果没定义映射，为了安全，我们应该只返回在 Step 定义中声明过的 output_keys
            # 但 Step.run 无法直接知道自己的 output_keys 定义。
            # 所以这里我们简单地返回所有子结果（除了改名的），
            # 父级 Executor 会根据 Step 定义自动丢弃不需要的。
            Map.values(inner_results)
          end

        {:ok, final_outputs}

      {:error, reason} ->
        {:error, {:nested_execution_failed, reason}}
    end
  end
end
