defmodule QyScript.DS.Sentence do
  # DS 中以 sentence 为基本单位

  alias QyScript.DS.Sentence

  @type seq(t) :: list(t)
  @type t :: %__MODULE__{
          offset: number(),
          text: seq(String.t()),
          ph_seq: seq(String.t()),
          ph_dur: seq(number()),
          ph_num: seq(pos_integer()),
          note_seq: seq(String.t()),
          note_slur: seq(0 | 1),
          params: %{atom() => [timestep: number(), content: seq(number)]} | nil
        }
  # 抄自 OpenUtau.Core.DiffSinger 的 RawDiffSingerQyScript
  defstruct [
    :offset,
    :text,
    :ph_seq,
    :ph_dur,
    # `text` 中一个对应的 `ph_seq` 的数目
    :ph_num,
    :note_seq,
    :note_dur,
    # 判断音符是否为转音
    :note_slur,
    :params
  ]

  @spec validate(Sentence.t()) :: :ok | {:error, term()}
  def validate(%__MODULE__{} = sentence) do
    with :ok <- validate_words(sentence),
         :ok <- validate_notes(sentence),
         :ok <- validate_params(sentence) do
      :ok
    else
      # Wrapper reason to more abstract layer.
      {:error, error} -> {:error, error}
    end
  end

  defp validate_words(%{
         text: text,
         ph_num: phoneme_num,
         ph_seq: phoneme_sequence,
         ph_dur: phoeneme_duration
       }) do
    case {length(text) == length(phoneme_num),
          Enum.sum(phoneme_num) == length(phoneme_sequence) and
            Enum.sum(phoneme_num) == length(phoeneme_duration)} do
      {true, true} -> :ok
      {true, false} -> {:error, :phoneme_length_not_match}
      {false, _} -> {:error, :word_phoneme_mapping_not_match}
    end
  end

  defp validate_notes(%{note_seq: note_sequence, note_dur: note_duration, note_slur: note_slur}) do
    case {length(note_sequence) == length(note_duration) and
            length(note_sequence) == length(note_slur)} do
      {true} -> :ok
    end
  end

  def validate_params(%{params: nil}), do: :ok

  def validate_params(%{params: params}) when is_map(params) do
    valid_params = Sentence.Params.get_validate_params()

    for {status, param} when status == false <- Enum.map(params, &{&1 in valid_params, &1}) do
      {:error, {:invalid, Map.keys(param)[0]}}
    end
    |> case do
      [] ->
        :ok
        # [TODO) when list not none -> get the key of params and return.
    end
  end
end
