defmodule QyCore.NoteValue do
  # 音符时值相关

  @type length ::
          :whole
          | :half
          | :quarter
          | :quaver
          | :semiquaver
          | :demisemiquaver
          | :hemidemisemiquaver
          | {integer(), :th_note}
          | {integer(), :whole_note}

  @type tuplet :: {:tuplet, integer(), length()}

  @type dotted :: {:dotted, length() | dotted()}

  @type bpm :: number()

  # TODO 确定好命名/别称用哪个
  # length alias map
  @length_alias_map %{
    ## x全音符
    maxima: {8, :whole_note},
    longa: {4, :whole_note},
    breve: {2, :whole_note},
    semibreve: {1, :whole_note},
    ## x分音符
    half: {2, :th_note},
    crotchet: {4, :th_note},
    quaver: {8, :th_note},
    semiquaver: {16, :th_note},
    demisemiquaver: {32, :th_note},
    hemidemisemiquaver: {64, :th_note}
  }
  for {a, b} <- @length_alias_map do
    def langth_mapper(unquote(a)), do: unquote(b)
    def langth_mapper(unquote(b)), do: unquote(a)
  end

  # Mannual all
  def langth_mapper(:whole), do: {1, :whole_note}

  # 时值 <--> 绝对时长

  # [TODO) 附点/装饰音 bla bla

  # slur/tie
end
