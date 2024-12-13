defmodule QyCore.Segment.StateM do
  # alias :gen_statem, as: GenStateM
  # @behavior GenStateM

  ## 状态本体
  # {maybe_new_state, {current_state, inference_result}, tools_keyword}
  # maybe_new_state: nil 或新状态
  # {current_state, inference_result} 状态与输出的对应，可能在别的地方用到
  # tools_keyword: 工具函数（例如准备推理以及推理）

  ## 状态变化
  # 信息更新（Segment 与输出不对应） :idle -> :required_update
  # 准备调用模型推理 :required_update -> :do_update
  # 得到结果，固定新的（Segment 与输出） :do_update -> :idle
  # @states [:required_update, :do_update, :idle]

  ## Public API

  # def start_link()
  # def stop()

  ## Callbacks

  ## Helpers
end
