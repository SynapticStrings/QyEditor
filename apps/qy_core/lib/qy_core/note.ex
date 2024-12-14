defmodule QyCore.Note do
  @moduledoc """
  负责处理音符相关的业务。
  （谁能想到，这么多玩意儿，最开始就是为了根据音高算频率的）
  """

  alias QyCore.Note

  # 选用不同的调式
  # 十二平均律、五度相生律
  # [TODO)[required discuss]
  # 需要引入 Well-temp 吗？
  @type tuning_format ::
          :twelve_et
          | :pythagorean

  # 其他没有音高的音符
  @type non_pitch_note :: :rest | nil
  @note_convertor %{
    "A" => :a,
    "a" => :a,
    "B" => :b,
    "b" => :b,
    "C" => :c,
    "c" => :c,
    "D" => :d,
    "d" => :d,
    "E" => :e,
    "e" => :e,
    "F" => :f,
    "f" => :f,
    "G" => :g,
    "g" => :g
  }
  @note_convert_to_text @note_convertor
                        |> Enum.filter(fn {k, _} -> k in String.split("A B C D E F G") end)
                        |> Enum.map(fn {k, v} -> {v, k} end)
                        |> Enum.into(%{})
  @var_convertor_to_text %{
    ss: "ss",
    sharp: "#",
    natural: "",
    flat: "b",
    ff: "bb"
  }
  @type note_name :: :a | :b | :c | :d | :e | :f | :g
  @type note :: {note_name(), :sharp | :flat | :natural | :ss | :ff, integer()} | :rest
  @type note_and_frq :: {note(), number()}

  @spec note_to_text(note()) :: binary()
  def note_to_text({key, var, octave}) do
    Map.get(@note_convert_to_text, key) <>
      Map.get(@var_convertor_to_text, var, "") <> Integer.to_string(octave)
  end

  def note_to_text(:rest), do: "rest"

  @doc """
  将音符从文本（科学音高记号）变成 `note()` 。

  ### Examples

      iex> QyCore.Note.parse_spn("rest")
      :rest
      iex> QyCore.Note.parse_spn("A4")
      {:a, :natural, 4}
  """
  @spec parse_spn(raw_note_or_rest :: <<_::16, _::_*8>>) :: note()
  def parse_spn("rest"), do: :rest

  def parse_spn(<<note::binary-size(1), octave::binary-size(1)>>),
    do:
      {@note_convertor |> Map.get(note, :invalid), :natural, String.to_integer(octave)}
      |> invalid?()

  def parse_spn(<<note::binary-size(1), "#"::binary, octave::binary-size(1)>>),
    do:
      {@note_convertor |> Map.get(note, :invalid), :sharp, String.to_integer(octave)}
      |> invalid?()

  def parse_spn(<<note::binary-size(1), "b"::binary, octave::binary-size(1)>>),
    do:
      {@note_convertor |> Map.get(note, :invalid), :flat, String.to_integer(octave)} |> invalid?()

  # 重升重降
  def parse_spn(<<note::binary-size(1), "##"::binary, octave::binary-size(1)>>),
    do: {@note_convertor |> Map.get(note, :invalid), :ss, String.to_integer(octave)} |> invalid?()

  def parse_spn(<<note::binary-size(1), "bb"::binary, octave::binary-size(1)>>),
    do: {@note_convertor |> Map.get(note, :invalid), :ff, String.to_integer(octave)} |> invalid?()

  def parse_spn(_), do: :invalid_note

  defp invalid?({:invalid, _, _}), do: :invalid_note
  defp invalid?(note), do: note

  # 「修正」音符（format 是动词）
  @doc """
  格式化合法的音符。

  这里的格式化是为了方便后面的计算，将一些【不简单】
  的音高按照设置变成同音不同名的另一个音。

  例如 C## -> D 或是 Fbb -> D# 。

  `opts` 中的 `preference` 选项是偏好的调整范围

  ## Examples

      iex> QyCore.Note.format({:c, :ss, 4})
      {:d, :natural, 4}
      iex> QyCore.Note.format({:c, :ff, 4})
      {:b, :flat, 3}
  """
  @spec format(note(), keyword()) :: note()
  def format(note, opts \\ [])

  def format({_, var, _} = note, opts) do
    prefer =
      opts
      |> Keyword.get(:preference, :natural)

    # 将包含 ff/bb 的情况处理掉
    res =
      case var do
        :ss -> do_format(note, :sharp)
        :sharp -> do_format(note, :sharp)
        :natural -> note
        :flat -> do_format(note, :flat)
        :ff -> do_format(note, :flat)
      end

    case prefer do
      :natural -> res
      # 同音异名的转换
      _ -> res |> do_format(prefer)
    end
  end

  defp do_format({key, :ss, octave}, :sharp) do
    cond do
      key in [:c, :d, :f, :g, :a] -> {key |> Note.Distance.up_opt(), :natural, octave}
      key == :e -> {:f, :sharp, octave}
      key == :b -> {:c, :sharp, octave + 1}
      true -> :invalid_note
    end
  end

  defp do_format({key, :ff, octave}, :flat) do
    cond do
      key in [:d, :e, :g, :a, :b] -> {key |> Note.Distance.down_opt(), :natural, octave}
      key == :f -> {:e, :flat, octave}
      key == :c -> {:b, :flat, octave - 1}
      true -> :invalid_note
    end
  end

  # 用来处理一些诸如 #E bF 之类的情况

  defp do_format({key, :sharp, octave} = note, :sharp) do
    cond do
      key in [:c, :d, :f, :g, :a] -> note
      key == :e -> {:f, :natural, octave}
      key == :b -> {:c, :natural, octave + 1}
    end
  end

  defp do_format({key, :flat, octave} = note, :flat) do
    cond do
      key in [:d, :e, :g, :a, :b] -> note
      key == :f -> {:e, :natural, octave}
      key == :c -> {:b, :natural, octave - 1}
      # true -> :invalid_note
    end
  end

  # 主要用于同音异名

  defp do_format({key, :flat, octave}, :sharp) do
    cond do
      key in [:d, :e, :g, :a, :b] -> {key |> Note.Distance.down_opt(), :sharp, octave}
      key == :f -> {:e, :natural, octave}
      key == :c -> {:b, :natural, octave - 1}
    end
  end

  defp do_format({key, :sharp, octave}, :flat) do
    cond do
      key in [:c, :d, :e, :g, :a] -> {key |> Note.Distance.up_opt(), :natural, octave}
      key == :e -> {:f, :natural, octave}
      key == :b -> {:c, :natural, octave + 1}
      # true -> :invalid_note
    end
  end

  defp do_format({_, :natural, _} = note, _), do: note

  # 比较两个音符的高低
  @compare_note_list [c: 1, d: 2, e: 3, f: 4, g: 5, a: 6, b: 7]
  @compare_var_list [ff: -2, flat: -1, natural: 0, sharp: 1, ss: 2]

  @doc """
  比较两个音符的高低。
  """
  @spec higher?(note_1 :: note(), note_2 :: note()) :: boolean()
  def higher?(note1, note2) do
    do_higher?(
      note1 |> format() |> do_format(:sharp),
      note2 |> format() |> do_format(:sharp)
    )
  end

  defp do_higher?(note1, note2) when note1 == note2, do: false

  defp do_higher?({_, _, octave_1}, {_, _, octave_2}) when octave_1 != octave_2 do
    octave_1 > octave_2
  end

  defp do_higher?({note_1, _, _}, {note_2, _, _}) when note_1 != note_2 do
    Keyword.fetch!(@compare_note_list, note_1) > Keyword.fetch!(@compare_note_list, note_2)
  end

  defp do_higher?({_, var_1, _}, {_, var_2, _}) when var_1 != var_2 do
    Keyword.fetch!(@compare_var_list, var_1) > Keyword.fetch!(@compare_var_list, var_2)
  end

  @spec same?(note_1 :: note(), note_2 :: note()) :: boolean()
  def same?(note_1, note_2),
    do: format(note_1) |> do_format(:sharp) == format(note_2) |> do_format(:sharp)

  # 将音符转变为对应的频率
  @spec do_convert_note(note :: note(), format :: tuning_format(), base_note :: note_and_frq()) :: float()
  def do_convert_note(note, format \\ :twelve_et, base_note \\ {{:a, :natural, 4}, 440.0})

  def do_convert_note(:rest, _, _), do: +0.0

  def do_convert_note(note, :twelve_et, base_pair) do
    # If it is too slowly, please use NIF.
    base_pair
    |> octive_operate(note) |> IO.inspect()
    |> Note.Distance.TwelveETAdapter.calculate_distance_pitch(note)
  end

  def do_convert_note(_note, :pythagorean, _base_pair) do
    # base_pair |> octive_operate(note)
    raise("Pythagorean calculation currently not implemented")
    # |> Note.Distance.PythagoreanAdapter.calculate_distance_pitch(note)
  end

  def do_convert_note(_note, _format, _base_note), do: raise("Not Implemented")

  # 用递归可以做，也可以直接乘上 2 的倍数
  @doc """
  调整基音的八度，使其与目标音的八度对齐。

  该函数会根据基音与目标音的八度差异，递归地将基音的八度逐步调整至目标音的八度范围内；
  如果基音和目标音的八度相同，则返回原始值。
  """
  @spec octive_operate(base_note_and_pitch :: note_and_frq(), target_note :: note()) :: note_and_frq()
  def octive_operate(_, {:invalid, _, _}), do: {:error, :invalid_note}

  def octive_operate({{:invalid, _, _}, _}, _), do: {:error, :invalid_note}

  def octive_operate({{_, _, base_octave} = base_note, pitch}, {_, _, target_octave})
      when base_octave == target_octave,
      do: {base_note, pitch}

  def octive_operate(
        {{base_note, base_var, base_octave}, pitch},
        {_, _, target_octave} = target_note
      )
      when is_integer(base_octave) and is_integer(target_octave) do
    cond do
      base_octave > target_octave ->
        octive_operate({{base_note, base_var, base_octave - 1}, pitch / 2.0}, target_note)

      base_octave < target_octave ->
        octive_operate({{base_note, base_var, base_octave + 1}, pitch * 2.0}, target_note)
    end
  end
end
