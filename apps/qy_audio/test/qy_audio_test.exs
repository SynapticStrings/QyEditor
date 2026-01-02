defmodule QyAudioTest do
  use ExUnit.Case
  doctest QyAudio

  test "generates sine wave" do
    # 生成一个 440Hz 的正弦波，持续 0.1 秒
    wave = QyAudio.generate_sine_wave(440.0, 0.1)
    assert is_binary(wave)
    assert byte_size(wave) > 0
  end

  test "initializes correctly" do
    assert QyAudio.init() == :ok
  end
end
