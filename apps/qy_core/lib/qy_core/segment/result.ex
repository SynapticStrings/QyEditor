defmodule QyCore.Segment.Result do
  # 保存返回的结果
  # 一般是时间序列的多媒体（e.g. 音频、视频）
  # 可能一组 `Segment` 会有很多的结果
  # 可以看成一类特殊的 %QyCore.Param{} 结构

  # 播放时可能加载片段（e.g. 播放音频）
  # 当然，也是会直接返回归来的（例如某段要生成的音频的音高线或频谱）

  # 另外一点是如果要手动编辑
  # 可能会创建一个新的 %P{} 结构体，但是其类型没有 :result 部分
  # def result_to_chunks(%QyCore.Param{})
end
