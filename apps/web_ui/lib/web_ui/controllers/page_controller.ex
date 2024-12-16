defmodule WebUI.PageController do
  use WebUI, :controller

  def home(conn, _params) do
    # 主页一般是定制的，所以跳过默认的应用布局。
    render(conn, :home, layout: false)
  end

  def component_present(conn, _param) do
    # 搭建用于渲染 CoreComponents 的组件的网页，便于后面实时检查

    render(conn, :core_components)
  end
end
