defmodule QyAudio do
  @moduledoc """
  QyAudio 是 QyEditor 的音频处理模块，负责处理音频的录制、播放、编辑和效果处理。

  核心功能：
  - 音频格式转换
  - 音频效果处理
  - 音频波形生成
  - 音频分析
  - 音频合成
  """

  alias QyAudio.Waveform
  alias QyAudio.Effect
  alias QyAudio.Format
  alias QyAudio.Analyzer

  @doc """
  初始化 QyAudio 模块

  ## Examples

      iex> QyAudio.init()
      :ok
  """
  @spec init() :: :ok
  def init do
    # 初始化音频处理系统
    :ok
  end

  @doc """
  创建一个正弦波形

  ## Parameters

  - `frequency`: 频率（Hz）
  - `duration`: 持续时间（秒）
  - `sample_rate`: 采样率
  - `amplitude`: 振幅（0.0 到 1.0）

  ## Returns

  - `binary()`: 正弦波形音频数据
  """
  @spec generate_sine_wave(frequency :: float(), duration :: float(), sample_rate :: integer(), amplitude :: float()) :: binary()
  def generate_sine_wave(frequency \\ 440.0, duration \\ 1.0, sample_rate \\ 44100, amplitude \\ 0.5) do
    Waveform.generate(:sine, frequency, duration, sample_rate, amplitude)
  end

  @doc """
  应用音频效果

  ## Parameters

  - `audio_data`: 音频数据
  - `effect`: 效果类型
  - `params`: 效果参数
  - `sample_rate`: 采样率

  ## Returns

  - `binary()`: 应用效果后的音频数据
  """
  @spec apply_effect(audio_data :: binary(), effect :: atom(), params :: map(), sample_rate :: integer()) :: binary()
  def apply_effect(audio_data, effect, params \\ %{}, sample_rate \\ 44100) do
    Effect.apply(audio_data, effect, params, sample_rate)
  end

  @doc """
  转换音频格式

  ## Parameters

  - `audio_data`: 音频数据
  - `from_format`: 原始格式
  - `to_format`: 目标格式
  - `params`: 转换参数

  ## Returns

  - `binary()`: 转换后的音频数据
  """
  @spec convert_format(audio_data :: binary(), from_format :: atom(), to_format :: atom(), params :: map()) :: binary()
  def convert_format(audio_data, from_format, to_format, params \\ %{}) do
    Format.convert(audio_data, from_format, to_format, params)
  end

  @doc """
  分析音频数据

  ## Parameters

  - `audio_data`: 音频数据
  - `sample_rate`: 采样率
  - `channels`: 声道数

  ## Returns

  - `map()`: 音频分析结果
  """
  @spec analyze(audio_data :: binary(), sample_rate :: integer(), channels :: integer()) :: map()
  def analyze(audio_data, sample_rate \\ 44100, channels \\ 2) do
    Analyzer.analyze(audio_data, sample_rate, channels)
  end

  @doc """
  计算音频的 RMS 值

  ## Parameters

  - `audio_data`: 音频数据

  ## Returns

  - `float()`: RMS 值
  """
  @spec rms(audio_data :: binary()) :: float()
  def rms(audio_data) do
    Analyzer.rms(audio_data)
  end
end
