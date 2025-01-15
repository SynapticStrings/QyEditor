defmodule QyMusic.Note.Key do
  # 关于调号
  # 关于这个模块的必要性可能需要讨论下
  alias QyMusic.Note

  @type key_sharp_num :: integer()
  # 降号负数，没有调号是零

  # 教会调式
  @type church_modes ::
          :ionian | :dorian | :phrygian | :lydian | :mixolydian | :aeolian | :locrian
  # 背诵可以借鉴官大为老师某期节目的「我的霹雳猫阿洛」

  # @church_modes_step %{
  #   :ionian => [2, 2, 1, 2, 2, 2, 1],
  #   :dorian => [2, 1, 2, 2, 2, 1, 2],
  #   :phrygian => [1, 2, 2, 2, 1, 2, 2],
  #   :lydian => [2, 2, 2, 1, 2, 2, 1],
  #   :mixolydian => [2, 2, 1, 2, 2, 1, 2],
  #   :aeolian => [2, 1, 2, 2, 1, 2, 2],
  #   :locrian => [1, 2, 2, 1, 2, 2, 2]
  # }

  @spec build_note(church_modes(), Note.note()) :: nil
  def build_note(_mode, _tonic) do
    # 构建该调式下的音符
  end
end
