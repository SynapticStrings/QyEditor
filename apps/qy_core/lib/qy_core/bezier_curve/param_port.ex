defmodule QyCore.BezierCurve.ParamPort do
  # 从曲线到映射的参数（类似于 Cadencii 的功能）
  # 需要检查约束，然后依照时间步长把曲线的点变成序列
  # 到 %QyCore.Param{} 的就是纯参数序列了

  ## 曲线 <--> 参数序列

  # def curve_to_param_seq(curve, timestep), do: curve

  # def param_seq_to_curve(params, timestep), do: params
end
