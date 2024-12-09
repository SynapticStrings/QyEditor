defmodule WebUI.ConnCase do
  @moduledoc """
  此模块定义了需要设置连接的测试所使用的测试用例。

  这些测试需要 `Phoenix.ConnTest` 并且引入了其他的功能，
  使构建通用数据结构和查询数据层变得更加容易。

  最后，如果测试用例需要与数据库交互，我们启用 SQL 沙盒，
  因此对数据库的更改在测试结束后会恢复。如果你用的是
  PostgreSQL ，你甚至可以通过设置
  `use WebUI.ConnCase, async: true`
  对数据库进行异步测试，其他的数据库并不支持此功能。
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint WebUI.Endpoint

      use WebUI, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import WebUI.ConnCase
    end
  end

  setup _tags do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
