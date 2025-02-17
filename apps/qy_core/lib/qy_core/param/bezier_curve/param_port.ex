defmodule QyCore.Param.BezierCurve.ParamPort do
  # 从曲线到映射的参数（类似于 Cadencii 的功能）
  # 需要检查约束，然后依照时间步长把曲线的点变成序列
  # 到 %QyCore.Param{} 的就是纯参数序列了

  ## 曲线 <--> 参数序列

  # def curve_to_param_seq(curve, timestep), do: curve

  # def param_seq_to_curve(params, timestep), do: params

  ## 检查曲线

  # 同一个时间不存在两组参数
  def single_param_in_same_time(curve) do
    for {x, _} <- curve do
      if Enum.count(curve, fn {x_, _} -> x == x_ end) > 1, do: x
    end
    |> case do
      [] -> nil
      p -> {:has_multiple_params, p}
    end
  end
end
