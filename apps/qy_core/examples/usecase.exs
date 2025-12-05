# Gemini 给出的例子，没有涉及到时间序列
alias QyCore.Param

defmodule MyKitchen do

  # 1. 定义磨豆步骤 (输入: :beans -> 输出: :powder)
  def grind(_opts) do
    # 这里返回两个函数 {prepare, run}
    {
      fn opts -> {:ok, opts} end,
      fn inputs, opts ->
        # inputs 是一个 map 或 list，包含了 Param
        # 模拟业务逻辑
        IO.puts("⚙️  正在磨豆...")
        {:ok, Param.new(:powder, :string, "香喷喷的粉")}
      end
    }
  end

  # 2. 定义萃取步骤 (输入: {:powder, :water} -> 输出: :coffee_liquid)
  def brew(_opts) do
    {
      fn opts -> {:ok, opts} end,
      fn _inputs, _opts ->
        IO.puts("💧 正在萃取...")
        {:ok, Param.new(:coffee_liquid, :string, "热咖啡液")}
      end
    }
  end

  # 3. 定义加糖步骤 (输入: {:coffee_liquid, :sugar} -> 输出: :sweet_coffee)
  def add_sugar(_opts) do
    {
      fn opts -> {:ok, opts} end,
      fn _inputs, _opts ->
        IO.puts("🍬 正在加糖...")
        {:ok, Param.new(:sweet_coffee, :string, "好喝的加糖咖啡")}
      end
    }
  end

  def to_guests(guests_name) do
    {
      fn opts -> {:ok, opts} end,
      fn _inputs, _opts ->
        IO.puts("☕️ 递给 #{guests_name} 一杯咖啡，享受吧！")
        {:ok, Enum.map(guests_name, &Param.new(:served_coffee, :string, "递给 #{&1} 的咖啡")) |> List.to_tuple}
      end
    }
  end
end

# --- 模拟框架运行 ---

# 1. 初始食材 (我们手里只有这些)
initial_params = %{
  beans: Param.new(:beans, :string, "优质咖啡豆"),
  water: Param.new(:water, :string, "纯净水"),
  sugar: Param.new(:sugar, :string, "白砂糖")
}

# 2. 定义 Recipe (注意：顺序是完全乱的！)
# 格式: {实现, 输入key, 输出key}
steps = [
  # 这一步本来应该是最后做的，但我写在了第一个
  {MyKitchen.add_sugar([]), {:coffee_liquid, :sugar}, :sweet_coffee},

  # 这一步是中间的
  {MyKitchen.brew([]), {:powder, :water}, :coffee_liquid},

  # 这一步才是最开始的
  {MyKitchen.grind([]), :beans, :powder},

  # 再加了一步递给客人
  {MyKitchen.to_guests(["Alice", "Bob"]), :sweet_coffee, {:served_coffee_for_alice, :served_coffee_for_bob}}
]

context_init = QyCore.Executor.Context.new(steps, initial_params)
|> IO.inspect(label: "Context New Example")

next_ready_steps = QyCore.Executor.next_ready_steps(context_init)
|> IO.inspect(label: "Next Ready Steps Example")
