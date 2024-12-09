defmodule QyCore.Note.Distance do
  @moduledoc """
  计算音之间的距离。

  重度参考了 [乐理计算器](https://guo-musickit.vercel.app/#/music/readme) 。

  暂时不考虑超过十五度的范畴。
  """

  alias QyCore.Note

  # 纯大小增减
  @type quality :: :perfect | :major | :minor | :augmented | :diminished
  @type degree :: {quality(), integer()}

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

    quanlity =
      gap
      |> gap_to_interval()
      |> Map.get(key_diff)

    {quanlity, key_diff + over * 7}
  end

  @doc """
  计算频率。
  """
  @callback calculate_distance_pitch(
              base_note_and_pitch :: Note.note_and_frq(),
              target_note :: Note.note()
            ) :: number()

  # [TODO) 定义函数
  # 运用 func = %{bla bla}; unquote(func) 之类的语句实现加速
  # 可以用在 up_opt/1 down_opt/1 gap_to_interval/1 三个函数上

  # 上行音程
  def up_opt(source) when is_tuple(source) do
    case source do
      {:c, :natural, i} -> {:c, :sharp, i}
      {:c, :sharp, i} -> {:d, :natural, i}
      {:d, :natural, i} -> {:d, :sharp, i}
      {:d, :sharp, i} -> {:e, :natural, i}
      {:e, :natural, i} -> {:f, :natural, i}
      {:f, :natural, i} -> {:f, :sharp, i}
      {:f, :sharp, i} -> {:g, :natural, i}
      {:g, :natural, i} -> {:g, :sharp, i}
      {:g, :sharp, i} -> {:a, :natural, i}
      {:a, :natural, i} -> {:a, :sharp, i}
      {:a, :sharp, i} -> {:b, :natural, i}
      {:b, :natural, i} -> {:c, :natural, i + 1}
      _ -> :invalid_note
    end
  end

  def up_opt(source) when is_atom(source) do
    case source do
      :c -> :d
      :d -> :e
      :e -> :f
      :f -> :g
      :g -> :a
      :a -> :b
      :b -> :c
      _ -> :invalid_note
    end
  end

  # 下行音程
  def down_opt(source) when is_tuple(source) do
    case source do
      {:c, :natural, i} -> {:b, :natural, i - 1}
      {:b, :natural, i} -> {:b, :flat, i}
      {:b, :flat, i} -> {:a, :natural, i}
      {:a, :natural, i} -> {:a, :flat, i}
      {:a, :flat, i} -> {:g, :natural, i}
      {:g, :natural, i} -> {:g, :flat, i}
      {:g, :flat, i} -> {:f, :natural, i}
      {:f, :natural, i} -> {:e, :natural, i}
      {:e, :natural, i} -> {:e, :flat, i}
      {:e, :flat, i} -> {:d, :natural, i}
      {:d, :natural, i} -> {:d, :flat, i}
      {:d, :flat, i} -> {:c, :natural, i}
      _ -> :invalide_note
    end
  end

  def down_opt(source) when is_atom(source) do
    case source do
      :c -> :b
      :b -> :a
      :a -> :g
      :g -> :f
      :f -> :e
      :e -> :d
      :d -> :c
      _ -> :invalid_note
    end
  end

  @spec calc_note_steps(
          base :: Note.note() | {Note.note_name(), pos_integer()},
          target :: Note.note() | {Note.note_name(), pos_integer()},
          idx :: integer()
        ) :: integer()
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

  # 通过按键之间的距离（gap）
  def gap_to_interval(gap) do
    case gap do
      # 纯一度
      0 -> %{1 => :perfect, 2 => :diminished}
      # 小二度
      1 -> %{2 => :minor}
      # 大二度、减三度
      2 -> %{2 => :major, 3 => :diminished}
      # 增二度、小三度
      3 -> %{2 => :augmented, 3 => :minor}
      # 减四度、大三度
      4 -> %{3 => :major, 4 => :diminished}
      # 增三度、纯四度
      5 -> %{3 => :augmented, 4 => :perfect}
      # 减四度、增五度
      6 -> %{4 => :augmented, 5 => :diminished}
      # 纯五度、减六度
      7 -> %{5 => :perfect, 6 => :diminished}
      # 增五度、小六度
      8 -> %{5 => :augmented, 6 => :minor}
      # 减七度、大六度
      9 -> %{7 => :diminished, 6 => :major}
      # 小七度、增六度
      10 -> %{6 => :augmented, 7 => :minor}
      # 大七度
      11 -> %{7 => :major}
      # 增七度、纯八度
      12 -> %{7 => :augmented, 8 => :perfect}
    end
  end
end

defmodule QyCore.Note.Distance.TwelveETAdapter do
  # 十二平均律
  alias QyCore.{Note.Distance}
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

defmodule QyCore.Note.Distance.PythagoreanAdapter do
  alias QyCore.{Note.Distance}
  @behaviour Distance

  # [TODO)
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
      2 => 9/8,
      4 => 81/64,
      5 => 4/3,
      7 => 3/2,
      9 => 27/16,
      11 => 243/128,
      12 => 2
    }
  end
end
