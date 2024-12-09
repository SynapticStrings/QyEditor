defmodule WebUI.ErrorHTMLTest do
  use WebUI.ConnCase, async: true

  # 将 render_to_string/4 用于测试自定义试图
  import Phoenix.Template

  test "renders 404.html" do
    assert render_to_string(WebUI.ErrorHTML, "404", "html", []) == "Not Found"
  end

  test "renders 500.html" do
    assert render_to_string(WebUI.ErrorHTML, "500", "html", []) == "Internal Server Error"
  end
end
