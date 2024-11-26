defmodule DiffSinger.Model.Param do
  # 关于模型的信息

  def read(content) do
    content
    |> :yamerl.decode()
    |> parse()
  end

  def read_from_path(path) do
    path
    |> :yamerl.decode_file()
    |> parse()
  end

  defp parse(content, _opts \\ []) do
    content
    # Key_as_atom
  end
end
