defmodule QyScript.DS.Sentence.Params do
  # 参数设置
  # 暂时没有将 Params 单独设置成一个 struct 的打算
  # 这个模块主要负责的是承载和参数有关的函数
  @validate_params [:energy, :breathness, :gender]

  def get_validate_params, do: @validate_params
end
