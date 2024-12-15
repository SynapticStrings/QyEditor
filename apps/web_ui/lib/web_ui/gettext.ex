defmodule WebUI.Gettext do
  @moduledoc """
  提供基于 gettext API 的国际化模块。

  通过使用 [Gettext](https://hexdocs.pm/gettext)，
  您的模块将获得一组用于翻译的宏，例如：

      use Gettext, backend: WebUI.Gettext

      # 单数
      gettext("Here is the string to translate")

      # 复数
      ngettext("Here is the string to translate",
               "Here are the strings to translate",
               3)

      # 基于域的翻译
      dgettext("errors", "Here is the error message to translate")

  详细用法请参见 [Gettext 文档](https://hexdocs.pm/gettext)。
  """
  use Gettext.Backend, otp_app: :web_ui

  @doc """
  返回默认语言。

  当前是简体中文（`zh_CN`），后面可能会写一个相关的 Plug 或模块来读取。
  """
  def default_lang(), do: Gettext.get_locale(WebUI.Gettext)
end
