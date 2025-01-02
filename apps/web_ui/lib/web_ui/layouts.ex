defmodule WebUI.Layouts do
  @moduledoc """
  这个模块包括你的应用用到的不同的布局。

  在 "layouts_templates" 目录下可以看到所有可用的模板。
  `root` 布局（`root.html.heex`）是作为应用程序路由器的一部分渲染的骨架，
  在 `use WebUI, :controller` 以及 `use WebUI, :live_view`
  中，`app` 布局（`app.html.heex`）被设置为默认布局。
  """
  use WebUI, :html

  embed_templates "layouts_templates/*"
end
