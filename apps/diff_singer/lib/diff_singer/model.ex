defmodule DiffSinger.Model do
  @moduledoc """
  模型的通用设置，如果想查看各个模型的实现细节，请参见：

  - # TODO

  当前 DiffSinger Elixir 只支持并且只打算支持
  ONNX 版本（也就是 OpenUTAU 用的）。
  """

  @diff_singer_version "2.4.0"

  @type tensor :: Nx.Tensor.t()
  @type model_path :: Path.t()
  @type model :: Ortex.Model.t()

  @callback load_model(path :: model_path()) :: model() | {:error, term()}

  @callback load_config(path :: model_path()) :: any() | {:error, term()}

  @callback validate_model(model :: model()) :: model() | {:error, term()}

  @callback validate_input(input :: any(), context :: any()) :: any() | {:error, term()}

  @callback do_run(input :: any(), model :: model()) :: any()

  defmacro __using__ do
    quote do
      @behavior unquote(__MODULE__)
      import unquote(__MODULE__)
    end
  end

  def version(), do: @diff_singer_version
end

defmodule DiffSinger.ModelConfig do
  # TODO: 各个版本的模型配置 bla bla
end
