defmodule QyCore.Params.BezierCurve do
  @moduledoc """
  贝塞尔曲线绘制参数的相关函数。
  """

  # 此模块深度参考了 http://www.whudj.cn/?p=384

  @typedoc "点的坐标"
  @type point_location :: {number(), number()}

  @typedoc "控制点的坐标"
  @type control_points :: [point_location()]

  @typedoc "三阶贝塞尔曲线组成的曲线控制点的坐标"
  @type third_scale_control_points :: [{point_location(), point_location()}]
  # 因为考虑到编辑的性质，所以这里的格式是 [last_points, ..., first_points]
  # 其中 points 的格式是 {start_point, end_point}

  @typedoc "曲线本体"
  @type curve :: [point_location()]

  ## 移动

  # 平移

  @doc "将曲线或控制点整体平移"
  @spec shift(curve() | control_points(), shift_vector :: point_location()) ::
          curve() | control_points()
  def shift(points_or_curve, {offset_x, offset_y} \\ {0.0, 0.0}),
    do: Enum.map(points_or_curve, fn {x, y} -> {x + offset_x, y + offset_y} end)

  # 缩放

  @doc "将曲线或控制点整体缩放"
  @spec scale(curve() | control_points(), scale_vector :: point_location()) ::
          curve() | control_points()
  def scale(points_or_curve, {scale_x, scale_y} \\ {1.0, 1.0}),
    do: Enum.map(points_or_curve, fn {x, y} -> {x * scale_x, y * scale_y} end)

  # 旋转

  @doc "将曲线或控制点整体旋转"
  @spec rotate(curve() | control_points(), angle_in_rad :: float()) ::
          curve() | control_points()
  def rotate(points_or_curve, angle_in_rad \\ :math.pi / 2),
    do:
      Enum.map(points_or_curve, fn {x, y} ->
        {x * :math.cos(angle_in_rad) - y * :math.sin(angle_in_rad),
         x * :math.sin(angle_in_rad) + y * :math.cos(angle_in_rad)}
      end)

  ## 曲线 <--> 控制点

  # 绘图

  @doc """
  根据控制点绘制曲线。

  ## Params

  - `points` 控制点的坐标
  - `step` 每次迭代所走的步数，大于零小于一的浮点数，其倒数【一般】是点的数目
  """
  @spec draw(control_points :: control_points(), step :: float()) :: curve()
  defdelegate draw(points, step), to: QyCore.Params.BezierCurve.Drawer

  # 从曲线本身反推控制点
  # 这篇文章的算法返回的是三次贝塞尔曲线的控制点，如果需要多次的话另当讨论
  # https://jermmy.github.io/2016/08/01/2016-8-1-Bezier-Curve-SVG/

  ## 控制点的增减

  # 不更换曲线的情况下增加控制点（升阶）
  # http://www.whudj.cn/?p=445
  @spec degree_elevation(old_control_points :: control_points(), non_neg_integer()) ::
          control_points()
  def degree_elevation(points, _append_point_num), do: points

  # 尽量不修改曲线参数的情况下精简控制点

  ## 三次曲线 <--> 多次曲线

  # def subdivide(control_points, t), do: curve

  # 可能需要用到这一章
  # http://www.whudj.cn/?p=419

  # def to_third_order(points = [_, _, _, _]), do: points
  # def to_third_order(points)

  # def from_third_order(points = [_, _, _, _]), do: points
  # def from_third_order(points)

  ## 与参数序列的互换
  # TODO
end
