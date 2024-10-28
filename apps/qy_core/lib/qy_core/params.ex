defmodule QyCore.Params do
  # 参数的通用设置
  defstruct [
    :id,
    # 参数的 id （因为不可避免地存在很多个参数）
    :timestep,
    # 参数的时间步长
    :offset,
    # 首个参数的时长偏移量
    :sequence,
    # 参数序列
    :context,
    # 上下文
    # 比方说这个参数黏附的对象是某某句子，或是某某时间戳
    :extra,
    # 额外信息
    # 像是控制/约定参数的曲线
  ]

  # 默认值、极限值的设定以及约束

  # 贝塞尔曲线特征点 => 参数值
end
