defmodule QyMusic.Note.Distance do
  @moduledoc """
  计算音之间的距离。

  重度参考了 [乐理计算器](https://guo-musickit.vercel.app/#/music/readme) 。

  超过十五度的音报错暂时不管。

  主要的函数：

  * `calculate_distance_sign/2`：计算音之间的度数
  * `calculate_distance_pitch/2`：基于给定音名和音高计算特定音的频率

  """

  alias QyMusic.Note

  # 纯大小增减
  @type quality :: :perfect | :major | :minor | :augmented | :diminished
  @type degree :: {quality(), pos_integer()}

  @spec calculate_distance_sign(Note.note(), Note.note()) :: degree() | {:invalid, term()}
  @doc """
  符号计算，【不返回正负】。

  比方说一个八度里边 do 和 si 之间差七度，以及不同八度间 do 和 si 可能是二度、十五度。
  """
  def calculate_distance_sign({key1, _, octave1} = note1, {key2, _, octave2} = note2) do
    key_diff = calc_note_steps({key1, octave1}, {key2, octave2})

    {gap, over} =
      note1
      |> Note.format()
      |> calc_note_steps(note2 |> Note.format())
      |> then(fn x -> {rem(x, 12), div(x, 12) |> abs()} end)

    quanlity = get_quanlity(gap, key_diff)

    {quanlity, key_diff + over * 7}
  end

  # 考虑到可能存在休止符的情况
  def calculate_distance_sign(_note1, _note2) do
    {:invalid, :maybe_has_rest_note}
  end

  @doc """
  计算频率。
  """
  @callback calculate_distance_pitch(
              base_note_and_pitch :: Note.note_and_frq(),
              target_note :: Note.note()
            ) :: number()

  # 上行音程
  singal_note_name_up_opt_map = %{
    c: :d,
    d: :e,
    e: :f,
    f: :g,
    g: :a,
    a: :b,
    b: :c
  }

  for {from, to} <- singal_note_name_up_opt_map do
    def up_opt(unquote(from)), do: unquote(to)
  end

  # def up_opt(source) when is_atom(source), do: :invalid_note

  note_with_tuple_up_opt = %{
    {:c, :natural} => {:c, :sharp},
    {:c, :sharp} => {:d, :natural},
    {:d, :natural} => {:d, :sharp},
    {:d, :sharp} => {:e, :natural},
    {:e, :natural} => {:f, :natural},
    {:f, :natural} => {:f, :sharp},
    {:f, :sharp} => {:g, :natural},
    {:g, :natural} => {:g, :sharp},
    {:g, :sharp} => {:a, :natural},
    {:a, :natural} => {:a, :sharp},
    {:a, :sharp} => {:b, :natural}
  }

  for {{from_key, from_var}, {to_key, to_var}} <- note_with_tuple_up_opt do
    def up_opt({unquote(from_key), unquote(from_var), from_octave}),
      do: {unquote(to_key), unquote(to_var), from_octave}
  end

  def up_opt({:b, :natural, i}), do: {:c, :natural, i + 1}

  # def up_opt(source) when is_tuple(source), do: :invalid_note

  # 下行音程
  singal_note_name_down_opt_map =
    singal_note_name_up_opt_map
    |> Enum.map(fn {k, v} -> {v, k} end)

  for {from, to} <- singal_note_name_down_opt_map do
    def down_opt(unquote(from)), do: unquote(to)
  end

  # def down_opt(source) when is_atom(source), do: :invalid_note

  note_with_tuple_down_opt = %{
    {:b, :natural} => {:b, :flat},
    {:b, :flat} => {:a, :natural},
    {:a, :natural} => {:a, :flat},
    {:a, :flat} => {:g, :natural},
    {:g, :natural} => {:g, :flat},
    {:g, :flat} => {:f, :natural},
    {:f, :natural} => {:e, :natural},
    {:e, :natural} => {:e, :flat},
    {:e, :flat} => {:d, :natural},
    {:d, :natural} => {:d, :flat},
    {:d, :flat} => {:c, :natural}
  }

  for {{from_key, from_var}, {to_key, to_var}} <- note_with_tuple_down_opt do
    def down_opt({unquote(from_key), unquote(from_var), from_octave}),
      do: {unquote(to_key), unquote(to_var), from_octave}
  end

  def down_opt({:c, :natural, i}), do: {:b, :natural, i - 1}

  # def down_opt(source) when is_tuple(source), do: :invalid_note

  @spec calc_note_steps(
          base :: Note.note() | {Note.note_name(), pos_integer()},
          target :: Note.note() | {Note.note_name(), pos_integer()},
          idx :: integer()
        ) :: integer()
  @doc """
  计算音符之间的半音数目。
  """
  def calc_note_steps(base, target, idx \\ 0)

  # 只用作比较音名，就是 xx 度
  def calc_note_steps({base, _}, {target, _}, idx) when base == target, do: abs(idx) + 1

  def calc_note_steps({base, octave1}, {target, octave2}, idx) do
    # 只用作比较音名，所以升降无所谓
    case Note.higher?({base, :natural, octave1}, {target, :natural, octave2}) do
      true ->
        new_note =
          case down_opt(base) do
            :b -> {down_opt(base), octave1 - 1}
            _ -> {down_opt(base), octave1}
          end

        calc_note_steps(new_note, {target, octave2}, idx - 1)

      false ->
        new_note =
          case up_opt(base) do
            :c -> {up_opt(base), octave1 + 1}
            _ -> {up_opt(base), octave1}
          end

        calc_note_steps(new_note, {target, octave2}, idx + 1)
    end
  end

  def calc_note_steps({_, _, _} = base, {_, _, _} = target, idx) do
    if Note.format(base) == Note.format(target) do
      idx
    else
      case Note.higher?(base, target) do
        true -> calc_note_steps(base |> down_opt(), target, idx - 1)
        false -> calc_note_steps(base |> up_opt(), target, idx + 1)
      end
    end
  end

  # TODO: 计算某个音行多少音程后得到什么音
  # @spec get_note_via_distance(Note.note(), degree(), direction :: :up | :down) :: Note.note()
  def get_note_via_distance(source, {quanlity, key_diff} = _degree, direction \\ :up) do
    raw_note = Note.format(source)

    # _note_without_format =
    # 这个函数需要将下面的 quanlity_mapper 反过来来获得具体的步数
    get_gap_from_quanlity(quanlity, key_diff)
    # 先通过半音数向上/下走到特定的音
    |> then(&get_note_after_walking(raw_note, &1, direction))
    |> Note.format()

    # 再通过 Note.format/2 以及 key_diff 与实际两个音的差来实现标准化
    # 可能会考虑过八度的情况 => 计算 octave_diff 分类讨论
    # 但是暂时不考虑什么形如 C -> Ebb 之类的情况了（因为暂时不支持）
  end

  defp get_note_after_walking(source, 0, _direction), do: source

  defp get_note_after_walking(source, steps, :up),
    do: get_note_after_walking(source |> up_opt(), steps - 1, :up)

  defp get_note_after_walking(source, steps, :down),
    do: get_note_after_walking(source |> down_opt(), steps - 1, :down)

  quanlity_mapper = %{
    # 纯一度
    {0, 1} => :perfect,
    # 减二度
    {0, 2} => :diminished,
    # 小二度
    {1, 2} => :minor,
    # 大二度
    {2, 2} => :major,
    # 减三度
    {2, 3} => :diminished,
    # 增二度
    {3, 2} => :augmented,
    # 小三度
    {3, 3} => :minor,
    # 大三度
    {4, 3} => :major,
    # 减四度
    {4, 4} => :diminished,
    # 增三度
    {5, 3} => :augmented,
    # 纯四度
    {5, 4} => :perfect,
    # 增四度
    {6, 4} => :augmented,
    # 减五度
    {6, 5} => :diminished,
    # 纯五度
    {7, 5} => :perfect,
    # 减六度
    {7, 6} => :diminished,
    # 增五度
    {8, 5} => :augmented,
    # 小六度
    {8, 6} => :minor,
    # 减七度
    {9, 7} => :diminished,
    # 大六度
    {9, 6} => :major,
    # 增六度
    {10, 6} => :augmented,
    # 小七度
    {10, 7} => :minor,
    # 大七度
    {11, 7} => :major,
    # 增七度
    {12, 7} => :augmented,
    # 纯八度
    {12, 8} => :perfect
  }

  for {{gap, key_diff}, quanlity} <- quanlity_mapper do
    def get_quanlity(unquote(gap), unquote(key_diff)), do: unquote(quanlity)

    def get_gap_from_quanlity(unquote(key_diff), unquote(quanlity)), do: unquote(gap)
  end
end

defmodule QyMusic.Note.Distance.TwelveETAdapter do
  # 十二平均律
  alias QyMusic.{Note.Distance}
  @behaviour Distance

  def calculate_distance_pitch({{bkey, bvar, boctave}, base_pitch}, {_, _, toctave} = target_note) do
    # 就是因为转调算音简单，十二平均律才用得多
    pitch_under_same_octave = base_pitch * 2 ** (toctave - boctave)

    clac_scale_within_octave = &:math.pow(2, &1 / 12)

    # 在一个八度里才好算，要不然溢出了
    {bkey, bvar, toctave}
    |> Distance.calc_note_steps(target_note)
    |> then(clac_scale_within_octave)
    |> Kernel.*(pitch_under_same_octave)
  end
end

# 我不知道我有没有必要因为这么相近的音分去写很多的 Adapters
# 反正 DiffSinger 的声码器是不在意那么细节的差异的
# 我也听不大出来其实

defmodule QyMusic.Note.Distance.PythagoreanAdapter do
  alias QyMusic.{Note.Distance}
  @behaviour Distance

  # TODO
  # 需不需要再单独讨论升降音？

  def calculate_distance_pitch(_base_note_and_pitch, _target_note) do
    # 操作到一个八度
    # 算他们之间间音的距离
    # 往里套，在这里边就返回结果，不在就报错
    raise("Not implenented yet!")
  end

  # 这里不写死是因为可能基础音不是 C
  def note_offset() do
    # 对基准音：
    # 频率乘 3/2 ，升纯五度（up 7 step）
    # 频率乘 3/2 再减半，升纯五度再降八度（down 5 step）
    # 频率乘 3/2 ，升纯五度（up 7 step）
    # 频率乘 3/2 再减半，升纯五度再降八度（down 5 step）
    # 频率乘 3/2 ，升纯五度（up 7 step）
    # 对基准音：
    # 频率除 3/2 再乘二，降纯五度再升八度（down 7 step）
    %{
      0 => 1,
      2 => 9 / 8,
      4 => 81 / 64,
      5 => 4 / 3,
      7 => 3 / 2,
      9 => 27 / 16,
      11 => 243 / 128,
      12 => 2
    }
  end
end
