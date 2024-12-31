defmodule QyCore.Params.BezierCurve do
  @moduledoc """
  贝塞尔曲线绘制参数的相关函数。
  """
  # 此模块深度参考了 http://www.whudj.cn/?p=384

  @typedoc "点的坐标。"
  @type point_location :: {number(), number()}
  @type control_points :: [point_location()]
  @type curve :: [point_location()]

  ## 平移

  @doc "将曲线或控制点整体平移"
  @spec shift(curve() | control_points(), shift_vector :: point_location()) :: curve() | control_points()
  def shift(points_or_curve, {offset_x, offset_y} \\ {0.0, 0.0}), do:
    Enum.map(points_or_curve, fn {x, y} -> {x + offset_x, y + offset_y} end)

  ## 绘图

  @doc """
  根据控制点绘制曲线。

  ## Params

  - `points` 控制点的坐标
  - `step` 每次迭代所走的步数，大于零小于一的浮点数，其倒数【一般】是点的数目
  """
  @spec draw(control_points :: control_points(), step :: float()) :: curve()
  defdelegate draw(points, step), to: QyCore.Params.BezierCurve.Drawer

  # 从曲线本身反推控制点
  # https://jermmy.github.io/2016/08/01/2016-8-1-Bezier-Curve-SVG/

  # 不更换曲线的情况下增加控制点（升阶）
  # http://www.whudj.cn/?p=445
  @spec degree_elevation(old_control_points :: control_points(), non_neg_integer()) :: control_points()
  def degree_elevation(points, _append_point_num), do: points

  # 尽量不修改曲线参数的情况下精简控制点

  # 一堆三次曲线 <--> 多次曲线
  # 可能需要用到这一章
  # http://www.whudj.cn/?p=419
  # def to_third_order(points)
  # def from_third_order(points)

  # 从曲线到映射的参数（类似于 Cadencii 的功能）
  # 需要检查约束，然后依照时间步长把曲线的点变成序列
  # 到 ds 脚本的就是纯参数了

  # 约束
  # 比方说一个时间不存在两组参数
  def constraint(_curve_or_points, :single_param_in_same_time), do: nil
end
