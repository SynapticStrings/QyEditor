defmodule QyMusic.Note.Format do
  alias QyMusic.Note

  # 这个函数可能需要添加 :perference 是 :ss/:ff 的情况
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
      key in [:d, :e, :g, :a, :b] ->
        note

      key == :f ->
        {:e, :natural, octave}

      key == :c ->
        {:b, :natural, octave - 1}
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
      key in [:c, :d, :e, :g, :a] ->
        {key |> Note.Distance.up_opt(), :natural, octave}

      key == :e ->
        {:f, :natural, octave}

      key == :b ->
        {:c, :natural, octave + 1}
        # true -> :invalid_note
    end
  end

  # sharp -> ss
  # flat -> ss
  # natural -> ss
  # sharp -> ff
  # flat -> ff
  # natural -> ff

  defp do_format({_, :natural, _} = note, _), do: note
end
