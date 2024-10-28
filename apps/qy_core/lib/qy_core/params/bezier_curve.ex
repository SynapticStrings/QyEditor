defmodule QyCore.Params.BezierCurve do
  # 贝塞尔曲线
  # 此模块深度参考了 http://www.whudj.cn/?p=384
  @type location :: {number(), number()}

  @spec draw(list(location()), float()) :: list(location())
  defdelegate draw(points, step), to: QyCore.Params.BezierCurve.Drawer

  # 不更换曲线的情况下增加控制点

  # 尽量不修改曲线参数的情况下精简控制点

  # 对控制点的增删改

  # 从曲线到映射的参数（类似于 Cadencii 的功能）
  # 到 ds 脚本的就是纯参数了
end
