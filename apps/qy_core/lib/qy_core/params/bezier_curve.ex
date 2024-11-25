defmodule QyCore.Params.BezierCurve do
  @moduledoc """
  参数贝塞尔曲线绘制的相关函数。
  """
  # 此模块深度参考了 http://www.whudj.cn/?p=384

  @typedoc """
  点的坐标。
  """
  @type location :: {number(), number()}

  @spec draw(list(location()), float()) :: list(location())
  defdelegate draw(points, step), to: QyCore.Params.BezierCurve.Drawer

  # 不更换曲线的情况下增加控制点

  # 尽量不修改曲线参数的情况下精简控制点

  # 对控制点的增删改

  # 从曲线到映射的参数（类似于 Cadencii 的功能）
  # 到 ds 脚本的就是纯参数了

  # 约束
  # 比方说一个时间不存在两组参数
end
