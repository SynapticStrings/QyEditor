defmodule QySynth.Steps.Denoise do
  use QyCore.Recipe.Step
  alias QyCore.Param

  def run(input_param, _opts) do
    # 模拟降噪
    raw_data = Param.get_payload(input_param)
    processed = Enum.map(raw_data, &(&1 <> "_denoised"))
    {:ok, Param.new(:clean_vocal, :audio, processed)}
  end
end

defmodule QySynth.Steps.PitchFix do
  use QyCore.Recipe.Step
  alias QyCore.Param

  def run(input_param, _opts) do
    # 模拟修音
    data = Param.get_payload(input_param)
    processed = Enum.map(data, &(&1 <> "_tuned"))
    {:ok, Param.new(:tuned_vocal, :audio, processed)}
  end
end

defmodule QySynth.Steps.Mix do
  use QyCore.Recipe.Step
  alias QyCore.Param

  # 注意：这里接收两个参数的 List
  def run([vocal_param, bgm_param], _opts) do
    vocal = Param.get_payload(vocal_param)
    bgm = Param.get_payload(bgm_param)

    mixed = Enum.zip_with(vocal, bgm, fn v, b -> "Mix[#{v} + #{b}]" end)
    {:ok, Param.new(:final_track, :audio, mixed)}
  end
end

defmodule QyCoreTest do
  use ExUnit.Case
  doctest QyCore

  test "greets the world" do
    assert QyCore.hello() == :world
  end

  alias QyCore.{Param, Recipe}
  alias QyCore.Executor.Serial

  # 引用上面的 Steps 模块
  alias QySynth.Steps.{Denoise, PitchFix, Mix}

  test "runs the vocal mixing pipeline successfully" do
    # 1. 准备初始素材 (Payload 是 List)
    initial_params = [
      Param.new(:raw_vocal, :audio, ["V1", "V2"]),
      Param.new(:bgm, :audio, ["B1", "B2"])
    ]

    # 2. 定义 Recipe (乱序，测试调度能力)
    steps = [
      # Step 3: Mix (需要 Tuned + BGM)
      {Mix, [:tuned_vocal, :bgm], :final_track},

      # Step 1: Denoise (需要 Raw)
      {Denoise, :raw_vocal, :clean_vocal},

      # Step 2: PitchFix (需要 Clean)
      {PitchFix, :clean_vocal, :tuned_vocal}
    ]

    recipe = Recipe.new(steps)

    # 3. 执行
    assert {:ok, results} = Serial.execute(recipe, initial_params)

    # 4. 验证结果
    final_param = results[:final_track]
    assert final_param.name == :final_track

    # 验证数据流转逻辑是否正确：V1 -> V1_denoised -> V1_denoised_tuned -> Mix[...]
    expected_payload = [
      "Mix[V1_denoised_tuned + B1]",
      "Mix[V2_denoised_tuned + B2]"
    ]

    assert Param.get_payload(final_param) == expected_payload
  end

  test "detects stuck execution (missing dependency)" do
    # 故意少给 BGM
    initial_params = [
      Param.new(:raw_vocal, :audio, ["V1"])
    ]

    steps = [
      {Mix, [:tuned_vocal, :bgm], :final_track}, # 这一步永远无法满足
      {Denoise, :raw_vocal, :clean_vocal},
      {PitchFix, :clean_vocal, :tuned_vocal}
    ]

    recipe = Recipe.new(steps)

    # 预期报错
    assert {:error, :stuck} = Serial.execute(recipe, initial_params)
  end
end
