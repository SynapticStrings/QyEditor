defmodule QyScript.DS.JSON do
  alias QyScript.DS.Sentence

  @spec from_json(list(map())) :: list(Sentence.t())
  def from_json(sentence_list) do
    sentence_list
    |> Enum.map(fn s ->
      parse_note(s, :json)
      |> Map.merge(parse_words(s, :json))
      |> Map.merge(parse_offset_and_params(s, :json))
      |> Enum.into(%Sentence{})
    end)
  end

  @spec to_json(list(Sentence.t())) :: list(map())
  def to_json(sentence_list) do
    # Note tested.
    sentence_list
    |> Enum.map(fn s ->
      parse_note(s, :sentence)
      |> Map.merge(parse_words(s, :sentence))
      |> Map.merge(parse_offset_and_params(s, :sentence))
    end)
  end

  def parse_note(sentence, from) do
    # Prelude
    sentence =
      case from do
        :json ->
          sentence

        :struct ->
          sentence
          |> Map.from_struct()
          |> Map.update(
            :note_seq,
            "rest",
            &Enum.map(&1, fn note -> QyCore.Note.note_to_text(note) end)
          )
      end

    content = do_simple_parse(sentence, [:note_seq, :note_dur, :note_slur], from)

    # Postlude
    case from do
      :json ->
        content
        |> Map.update(
          :note_seq,
          :rest,
          &Enum.map(&1, fn note -> QyCore.Note.parse_spn(note) end)
        )
        |> Map.update(:note_dur, 0.0, &Enum.map(&1, fn note -> String.to_float(note) end))
        |> Map.update(:note_slur, 0, &Enum.map(&1, fn note -> String.to_integer(note) end))

      :struct ->
        content
    end
  end

  def parse_words(sentence, from) do
    content = do_simple_parse(sentence, [:text, :ph_seq, :ph_dur, :ph_num], from)

    # Postlude
    case from do
      :json ->
        content
        |> Map.update(:ph_dur, 0.0, &Enum.map(&1, fn note -> String.to_float(note) end))
        |> Map.update(:ph_num, 0, &Enum.map(&1, fn note -> String.to_integer(note) end))

      :struct ->
        content
    end
  end

  def parse_offset_and_params(sentence, from) do
    offset =
      case from do
        :json -> sentence["offset"]
        :struct -> sentence.offset
      end

    # 在 DiffSinger 中，不同的参数有两个键值
    # "key": bla bla, "key_timestep": bla bla
    valid_keys =
      case from do
        :struct ->
          Sentence.Params.get_validate_params()

        :json ->
          source = Sentence.Params.get_validate_params()

          extra =
            source
            |> Enum.map(&:erlang.atom_to_binary/1)
            |> Enum.map(&(&1 <> "_timestep"))
            |> Enum.map(&String.to_atom/1)

          source ++ extra
      end

    do_simple_parse(sentence, valid_keys, from)
    |> Enum.into(%{if(from == :json, do: :offset, else: "offset") => offset})
  end

  # from: :struct %{k: [a, b, c]} --> %{"k" => "a b c"]}
  # from: :json   %{"k" => "a b c"]} --> %{k: ~w(a b c)}
  @spec do_simple_parse(Sentence.t() | map(), list(atom()), :json | :struct) :: map()
  def do_simple_parse(
        sentence,
        keys_list,
        from \\ :json
      ) do
    keys_list =
      case from do
        :json -> keys_list |> Enum.map(&Atom.to_string/1)
        :struct -> keys_list
        _ -> :error_format
      end

    value_operate_func =
      case from do
        :json -> &String.split(&1, " ")
        :struct -> &Enum.join(&1, " ")
      end

    case from do
      :json ->
        sentence
        |> Enum.filter(fn {k, _} -> k in keys_list end)
        |> Enum.reduce(%{}, fn {k, v}, map ->
          Map.put(map, k, value_operate_func.(v))
        end)
        |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

      :struct ->
        sentence
        |> Map.from_struct()
        |> Map.to_list()
        |> Enum.filter(fn {k, _} -> k in keys_list end)
        |> Enum.reduce(%{}, fn {k, v}, map -> %{map | k => value_operate_func.(v)} end)
        |> Enum.map(fn {k, v} -> {Atom.to_string(k), v} end)
    end
    |> Enum.into(%{})
  end
end
