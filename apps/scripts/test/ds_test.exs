defmodule QyScriptTest do
  use ExUnit.Case
  doctest QyScript

  test "greets the world" do
    assert QyScript.hello() == :world
  end
end
