defmodule QyCore.BexierCurveTest.Helpers do
  # 需要一个 helper 来判断曲线是否经过某个区间/点
  # assert_passby / assert_include / assert_exclude

  # import ExUnit.Assertions

  @doc "曲线经过某点"
  def curve_passby_target(curve, target, distance \\ 0.01) do
    # 存在点经过或两点连线经过
    curve_has_target(curve, target, distance) or
      Enum.any?(Enum.zip(curve, Enum.drop(curve, 1)), fn {point1, point2} ->
        clac_points_distance(point1, target) + clac_points_distance(point2, target) ==
          clac_points_distance(point1, point2)
      end)
  end

  @doc "曲线包含某点"
  def curve_has_target(curve, target, distance \\ 0.01) do
    Enum.any?(curve, fn point -> clac_points_distance(point, target) < distance end)
  end

  # 计算两点之间的距离
  defp clac_points_distance({x1, y1}, {x2, y2}) do
    :math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2))
  end
end

defmodule QyCore.BexierCurveTest do
  use ExUnit.Case

  import QyCore.BexierCurveTest.Helpers

  describe "测试 Helper" do
    test "assert_include" do
      assert curve_has_target([{0, 0}, {1, 1}, {2, 2}], {1, 1})
    end

    test "assert_passby" do
      assert curve_passby_target([{0, 0}, {1, 1}, {2, 2}], {1.5, 1.5})
    end
  end

  alias QyCore.Params.BezierCurve

  describe "画" do
    test "直线" do
      assert curve_passby_target(BezierCurve.draw([{0, 0}, {1, 1}], 0.01), {0.5, 0.5})
    end

    test "二阶贝塞尔曲线" do
      assert curve_passby_target(BezierCurve.draw([{0, 0}, {1, 1}, {2, 0}], 0.01), {1, 0.5})
    end

    test "三阶贝塞尔曲线" do
      assert curve_passby_target(
               BezierCurve.draw([{0, 0}, {1, 1}, {2, 1}, {3, 0}], 0.01),
               {1.5, 0.75}
             )
    end

    test "更高阶的曲线" do
      # 四阶
      assert curve_passby_target(
               BezierCurve.draw([{0, 0}, {1, 1}, {2, 1}, {3, 1}, {4, 0}], 0.01),
               {2, 0.875}
             )
    end
  end
end
