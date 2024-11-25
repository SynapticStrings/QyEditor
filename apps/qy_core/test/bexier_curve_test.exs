defmodule QyCore.BexierCurveTest.Helpers do
  # 需要一个 helper 来判断曲线是否经过某个区间/点
  # assert_passby / assert_include / assert_exclude
  defmacro assert_passby(_curve, _target, _distance), do: nil
  defmacro assert_include(_curve, _target, _distance), do: nil
  defmacro assert_exclude(_curve, _target, _distance), do: nil
end

defmodule QyCore.BexierCurveTest do
  use ExUnit.Case

  # alias QyCore.Params.BezierCurve
  # require QyCore.BexierCurveTest.Helpers

  describe "画线" do
    # ...
  end
end
