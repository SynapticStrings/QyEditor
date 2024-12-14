defmodule QyCore.SegmentStateTest do
  use ExUnit.Case

  doctest QyCore.Segment

  # describe "片段测试" do
  #   # ...
  # end

  doctest QyCore.Segment.StateM

  # describe "简单状态机" do
  #   # 创建一个代表用户的进程以及代表处理模型的进程
  #   # 变换输入的函数使用 QyCore.Note.parse_spn/1 即可
  #   # - 用户进程依照测试对输入进行修改
  #   # - 触发处理操作，得到结果

  #   setup "进程准备" do
  #     def model_process() do
  #       receive do
  #         {:parse_note, raw_note} ->
  #           :timer.sleep(1)

  #           QyCore.Note.parse_spn(raw_note)

  #           model_process()
  #         {:exit, _} -> nil
  #       end
  #     end
  #   end

  #   # 至于怎么操作等我补补课
  # end
end
