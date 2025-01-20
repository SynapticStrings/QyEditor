defmodule QySkalaTest do
  use ExUnit.Case
  doctest QySkala

  test "greets the world" do
    assert QySkala.hello() == :world
  end
end
