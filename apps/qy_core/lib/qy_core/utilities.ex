defmodule QyCore.Utilities do
  @doc """
  标准化步骤的输入输出键为 MapSet。
  """
  def normalize_keys_to_set(nil), do: MapSet.new()
  def normalize_keys_to_set(atom) when is_atom(atom), do: MapSet.new([atom])
  def normalize_keys_to_set(list) when is_list(list), do: MapSet.new(list)
  def normalize_keys_to_set(tuple) when is_tuple(tuple), do: MapSet.new(Tuple.to_list(tuple))
  def normalize_keys_to_set(mapset), do: mapset

  @doc """
  辅助：规范化 Step 结构，支持多种形式的 Step 定义。
  """
  def ensure_full_step({impl, in_k, out_k}), do: {impl, in_k, out_k, [], []}
  def ensure_full_step({impl, in_k, out_k, opts}), do: {impl, in_k, out_k, opts, []}
  def ensure_full_step({impl, in_k, out_k, opts, meta}), do: {impl, in_k, out_k, opts, meta}

  @doc """
  标准化输出名称。
  """
  def normalize_keys(k) when is_list(k), do: k
  def normalize_keys(k) when is_tuple(k), do: Tuple.to_list(k)
  def normalize_keys(k), do: [k]
end
