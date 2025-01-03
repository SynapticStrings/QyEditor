alias QyCore.{Segment, Segment.StateM, Params}

## 一些工具模块与函数
defmodule ParamExecutor do
  @moduledoc """
  ~~演奏太君的雅乐 *Sakura sakura*~~

  简单来说执行音符序列这个参数的注入
  """
  # la la si - | la la si - | la si do si | la si-la sol -
  @note_seq ~w(A4 A4 B4 A4 A4 B4 A4 B4 C5 B4 A4 B4 A4 G4)
  @note_value_seq [2, 2, 4, 2, 2, 4, 2, 2, 2, 2, 2, 1, 1, 4] |> Enum.map(fn x -> x / 2 end)

  def inject() do
    # raw to params
    raw()
    |> Enum.map(fn k, v ->
      {k, %Params{type: {:mannual, :element_seq, k}, sequence: v |> Enum.reverse()}}
    end)
    |> Enum.into(%{})
  end

  def raw() do
    %{note: @note_seq, note_value: @note_value_seq}
  end
end

defmodule ExampleExecutor do
  @moduledoc "将音符序列转变成绝对时间下该乐器的基频序列"
  use GenServer

  # @bpm 72.0
  # @beat {4, 4}
  # @timestep_in_timeseq 0.05

  def init(_args) do
    # TODO
    {:ok, nil}
  end

  def handle_call(:bing, _from, state) do
    {:reply, :bang, state}
  end

  # TODO impl validate and operate
  # Operate 1: 变成一系列单个音符
  def opt_1(_param_map = %{note: _note, note_value: _note_value}) do
    # TODO
  end

  # Operate 2: 计算每个音符的持续时间并且输出基频
  # opts: has_gap / overlap
  def opt_2(_param_map = %{note_seq: _note_seq}) do
    # TODO
  end

  # Operate 3: 根据基频变成波形文件
  def opt(_param_map = %{f0: _f0}) do
    # TODO
  end
end

## 实际执行过程

# 片段
id = Segment.random_id()

segment = %Segment{
  id: {id, :mannual}
}

# 创建一个状态机进程
{:ok, state_pid} = StateM.start_link(segment)

# 执行一次更新并且输出更新前后的数据
StateM.get_data(id) |> IO.inspect(label: :data_before_inject)

StateM.load(id, %{segment | params: ParamExecutor.inject()})

StateM.get_data(id) |> IO.inspect(label: :data_after_inject)

# 创建推理模型进程
# {:ok, model_pid} = ExampleExecutor.start_link(nil)

# 准备更新

# 执行更新

# 装载到新的片段

if Process.alive?(state_pid) do
  # 停止该状态机进程
  StateM.stop(id)
end
