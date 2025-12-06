defmodule QyMusic.Note.Format do
  alias QyMusic.Note

  # TODO 实现完全 :perference 是 :ss/:ff 的情况
  def format({_, var, _} = note, opts \\ []) do
    prefer =
      opts
      |> Keyword.get(:preference, :natural)

    case var do
      :ss -> do_format(note, :sharp)
      :sharp -> do_format(note, :sharp)
      :natural -> do_format(note, :natural)
      :flat -> do_format(note, :flat)
      :ff -> do_format(note, :flat)
    end
    |> do_format(prefer)
  end

  @valid_key [:a, :b, :c, :d, :e, :f, :g]

  defp do_format(note, :natural), do: note

  defp do_format({key, :ss, octave}, :sharp) when key in @valid_key do
    case key do
      :e -> {:f, :sharp, octave}
      :b -> {:c, :sharp, octave + 1}
      _ -> {key |> Note.Distance.up_opt(), :natural, octave}
    end
  end

  defp do_format({key, :ff, octave}, :flat) when key in @valid_key do
    case key do
      :f -> {:e, :flat, octave}
      :c -> {:b, :flat, octave - 1}
      _ -> {key |> Note.Distance.down_opt(), :natural, octave}
    end
  end

  # 用来处理一些诸如 #E bF 之类的情况

  defp do_format({key, :sharp, octave} = note, :sharp) when key in @valid_key do
    case key do
      :e -> {:f, :natural, octave}
      :b -> {:c, :natural, octave + 1}
      _ -> note
    end
  end

  defp do_format({key, :flat, octave} = note, :flat) when key in @valid_key do
    case key do
      :f -> {:e, :natural, octave}
      :c -> {:b, :natural, octave - 1}
      _ -> note
    end
  end

  # 主要用于同音异名

  defp do_format({key, :flat, octave}, :sharp) when key in @valid_key do
    case key do
      :f -> {:e, :natural, octave}
      :c -> {:b, :natural, octave - 1}
      _ -> {key |> Note.Distance.down_opt(), :sharp, octave}
    end
  end

  defp do_format({key, :sharp, octave}, :flat) when key in @valid_key do
    case key do
      :e -> {:f, :natural, octave}
      :b -> {:c, :natural, octave + 1}
      _ -> {key |> Note.Distance.up_opt(), :natural, octave}
    end
  end

  ## 用于很特殊的情况

  # sharp -> ss
  defp do_format({key, :sharp, octave}, :ss) when key in @valid_key do
    case key do
      # #C -> ##B
      :c -> {:b, :ss, octave - 1}
      # #F -> ##E
      :f -> {:e, :ss, octave}
      _ -> {key, :sharp, octave}
    end
  end

  # flat -> ss
  defp do_format({key, :flat, octave}, :ss) when key in @valid_key do
    case key do
      # bC -> ##A
      :c -> {:a, :ss, octave - 1}
      # bD -> ##B
      :d -> {:b, :ss, octave - 1}
      # bF -> ##D
      :f -> {key |> Note.Distance.down_opt(), :ss, octave}
      # bG -> ##E
      :g -> {key |> Note.Distance.down_opt(), :ss, octave}
      # bE -> #D
      # bA -> #F
      # bB -> #A
      _ -> {key |> Note.Distance.down_opt(), :sharp, octave}
    end
  end

  # natural -> ss
  defp do_format({key, :natural, octave}, :ss) when key in @valid_key do
    case key do
      # C -> ##B
      :c -> {:b, :natural, octave - 1}
      # F -> #E
      :f -> {:e, :sharp, octave}
      # D, E, G, A, B
      _ -> {key |> Note.Distance.down_opt(), :natural, octave}
    end
  end

  # sharp -> ff
  defp do_format({key, :sharp, _octave}, :ff) when key in @valid_key do
    # case key do
    #   :c
    # end
    raise "Not Implemented yet."
  end

  # flat -> ff
  defp do_format({key, :flat, _octave}, :ff) when key in @valid_key do
    raise "Not Implemented yet."
  end

  # natural -> ff
  defp do_format({key, :natural, _octave}, :ff) when key in @valid_key do
    raise "Not Implemented yet."
  end

  defp do_format({_, :natural, _} = note, _), do: note
end
