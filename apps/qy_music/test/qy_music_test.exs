defmodule QyMusicTest do
  use ExUnit.Case
  doctest QyMusic

  test "Все в порядке." do
    assert QyMusic.ping() == :pong
  end
end
