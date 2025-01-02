alias QyCore.Segment
alias QyCore.Segment.{StateM}

## 一些工具模块与函数
defmodule ParamExecutor do
  def inject() do
    %{}
  end
end

defmodule ExampleExecutor do
  # ...
end

## 实际执行

# 片段
id = Segment.random_id()
segment = %Segment{
  id: {id, :mannual},
  params: ParamExecutor.inject(),
}

# 创建一个状态机进程
{:ok, pid} = StateM.start_link(segment)

# 执行一次更新

# 停止该状态机进程
if Process.alive?(pid), do: StateM.stop(id)
