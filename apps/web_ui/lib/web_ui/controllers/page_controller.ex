defmodule WebUI.PageController do
  use WebUI, :controller

  def home(conn, _params) do
    # 主页一般是定制的，所以跳过默认的应用布局。
    render(conn, :home, layout: false)
  end
end
