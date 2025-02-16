defmodule QyCore.Param.SequenceHelper do
  alias QyCore.Param
  # 1.
  # %Param{} <--> seq: [], time_step: timestep, ...
  # %{key => %Param{}} --> param and context

  # 2.
  # seq: [..bigdata..] <--> :ets.select

  def extract(key_and_param) when is_map(key_and_param) do
    Enum.reduce(key_and_param, {%{}, %{}}, &extract/2)
  end

  def extract({key, %Param{} = param}, {key_and_inner, context}) do
    {%{key_and_inner | key => extract_param(param)}, Map.merge(context, extract_args(key, param))}
  end

  defp extract_param(%Param{sequence: data}), do: data

  defp extract_args(key, %Param{name: name, timestep: timestep}) do
    %{"#{key}_name": name, "#{key}_timestep": timestep}
  end

  # def merge(key, inner_seq, related_context, relatedparam)
end
