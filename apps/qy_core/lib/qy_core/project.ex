defmodule QyCore.Project do
  @moduledoc """
  此模块用于配置整个工程项目。
  """

  @type t :: %__MODULE__{
    name: String.t(),
    description: String.t()
  }
  defstruct [
    :name,
    :description,
  ]

  @type entry :: %{
    name: String.t(),
    type: :url,
    url: String.t()
  }
  | %{
    name: String.t(),
    type: :file,
    path: Path.t()
  }

  ## 建立新工程
  # 一个工程对应一个 QyCore.Segment.Manager

  ## 工程相关配置的修改

  ## 对片段的增删改查
  # 操作入口

  ## 对推理模型的操作
  # （形如 ComfyUI）
  # 对节点的增删改查
  # 依赖图的操作

  ## 渲染/输出
end
