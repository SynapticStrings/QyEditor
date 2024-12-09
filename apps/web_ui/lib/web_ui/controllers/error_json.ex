defmodule WebUI.ErrorJSON do
  @moduledoc """
  本模块被 JSON 请求出错时的端点所调用。

  请看 config/config.exs 。
  """

  # 如果你想要定制化特定的状态码，你可以加上你自己的子句（Clause），比如：
  #
  # def render("500.json", _assigns) do
  #   %{errors: %{detail: "Internal Server Error"}}
  # end

  # 默认情况下， Phoenix 从模板名字返回状态信息。
  # 比方说， "404.json" 会变成 "Not Found" 。
  def render(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end
end
