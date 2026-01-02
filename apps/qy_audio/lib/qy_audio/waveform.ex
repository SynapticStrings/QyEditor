defmodule QyAudio.Waveform do
  @moduledoc """
  负责生成各种音频波形，包括正弦波、方波、三角波等。
  """

  @doc """
  生成指定类型的波形

  ## Parameters

  - `type`: 波形类型（:sine, :square, :triangle, :sawtooth）
  - `frequency`: 频率（Hz）
  - `duration`: 持续时间（秒）
  - `sample_rate`: 采样率
  - `amplitude`: 振幅（0.0 到 1.0）

  ## Returns

  - `binary()`: 波形音频数据
  """
  @spec generate(type :: atom(), frequency :: float(), duration :: float(), sample_rate :: integer(), amplitude :: float()) :: binary()
  def generate(type, frequency, duration, sample_rate, amplitude) do
    case type do
      :sine -> generate_sine(frequency, duration, sample_rate, amplitude)
      :square -> generate_square(frequency, duration, sample_rate, amplitude)
      :triangle -> generate_triangle(frequency, duration, sample_rate, amplitude)
      :sawtooth -> generate_sawtooth(frequency, duration, sample_rate, amplitude)
      _ -> raise ArgumentError, "Unknown waveform type: #{inspect(type)}"
    end
  end

  @doc """
  生成正弦波形
  """
  @spec generate_sine(frequency :: float(), duration :: float(), sample_rate :: integer(), amplitude :: float()) :: binary()
  def generate_sine(frequency, duration, sample_rate, amplitude) do
    num_samples = trunc(duration * sample_rate)

    # 生成样本列表
    samples = for sample_idx <- 0..(num_samples - 1) do
      # 计算当前样本的相位
      phase = 2 * :math.pi() * frequency * (sample_idx / sample_rate)
      # 生成正弦波样本
      sample = :math.sin(phase) * amplitude
      # 转换为 16 位整数
      trunc(sample * 32767)
    end

    # 将整数列表转换为二进制数据（16位小端格式）
    for sample <- samples, into: <<>> do
      <<sample::little-signed-16>>
    end
  end

  @doc """
  生成方波
  """
  @spec generate_square(frequency :: float(), duration :: float(), sample_rate :: integer(), amplitude :: float()) :: binary()
  def generate_square(frequency, duration, sample_rate, amplitude) do
    num_samples = trunc(duration * sample_rate)
    period = sample_rate / frequency

    # 生成样本列表
    samples = for sample_idx <- 0..(num_samples - 1) do
      # 计算当前样本在周期中的位置
      position_in_period = rem(sample_idx, trunc(period))
      # 生成方波样本
      sample = if position_in_period < period / 2, do: amplitude, else: -amplitude
      # 转换为 16 位整数
      trunc(sample * 32767)
    end

    # 将整数列表转换为二进制数据（16位小端格式）
    for sample <- samples, into: <<>> do
      <<sample::little-signed-16>>
    end
  end

  @doc """
  生成三角波
  """
  @spec generate_triangle(frequency :: float(), duration :: float(), sample_rate :: integer(), amplitude :: float()) :: binary()
  def generate_triangle(frequency, duration, sample_rate, amplitude) do
    num_samples = trunc(duration * sample_rate)
    period = sample_rate / frequency

    # 生成样本列表
    samples = for sample_idx <- 0..(num_samples - 1) do
      # 计算当前样本在周期中的位置
      position_in_period = rem(sample_idx, trunc(period)) / period
      # 生成三角波样本
      sample =
        if position_in_period < 0.25 do
          position_in_period * 4 * amplitude
        else
          if position_in_period < 0.75 do
            (0.5 - position_in_period) * 4 * amplitude
          else
            (position_in_period - 1) * 4 * amplitude
          end
        end
      # 转换为 16 位整数
      trunc(sample * 32767)
    end

    # 将整数列表转换为二进制数据（16位小端格式）
    for sample <- samples, into: <<>> do
      <<sample::little-signed-16>>
    end
  end

  @doc """
  生成锯齿波
  """
  @spec generate_sawtooth(frequency :: float(), duration :: float(), sample_rate :: integer(), amplitude :: float()) :: binary()
  def generate_sawtooth(frequency, duration, sample_rate, amplitude) do
    num_samples = trunc(duration * sample_rate)
    period = sample_rate / frequency

    # 生成样本列表
    samples = for sample_idx <- 0..(num_samples - 1) do
      # 计算当前样本在周期中的位置
      position_in_period = rem(sample_idx, trunc(period)) / period
      # 生成锯齿波样本
      sample = (position_in_period - 0.5) * 2 * amplitude
      # 转换为 16 位整数
      trunc(sample * 32767)
    end

    # 将整数列表转换为二进制数据（16位小端格式）
    for sample <- samples, into: <<>> do
      <<sample::little-signed-16>>
    end
  end
end
