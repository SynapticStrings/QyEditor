alias QyCore.{Segment, Segment.StateM, Params}

## 一些工具模块与函数
defmodule ParamExecutor do
  @moduledoc """
  ~~演奏太君的雅乐 *Sakura sakura*~~

  简单来说执行音符序列这个参数的注入
  """
  # la la si - | la la si - | la si do si | la si-la sol -
  @note_seq ~w(A4 A4 B4 A4 A4 B4 A4 B4 C5 B4 A4 B4 A4 G4)
  @note_value_seq [2, 2, 4, 2, 2, 4, 2, 2, 2, 2, 2, 1, 1, 4]

  def inject() do
    %{note: @note_seq, note_value: @note_value_seq}
  end
end

defmodule ExampleExecutor do
  @moduledoc "将音符序列转变成绝对时间下该乐器的基频序列"

  # @bpm 72.0
  # @beat {4, 4}

  # TODO impl validate and operate
  # Operate 1: 变成一系列单个音符

  # Operate 2: 计算每个音符的持续时间并且输出基频
end

## 实际执行过程

# 片段
id = Segment.random_id()
segment = %Segment{
  id: {id, :mannual},
  # params: ParamExecutor.inject(),
}

# 创建一个状态机进程
{:ok, pid} = StateM.start_link(segment)

if Process.alive?(pid) do
  # 执行一次更新
  StateM.update(id, %{segment | params: ParamExecutor.inject()})

  # 准备更新

  # 执行更新

  # 装载到新的片段

  # 停止该状态机进程
  StateM.stop(id)
end
