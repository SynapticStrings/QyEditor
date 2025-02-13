defmodule QyCore.Recipe do
  @moduledoc """
  菜谱可以包括单步的操作，也可以是制作食物的整个过程，所以这里就等同于「操作」。

  其灵感来源于 [Plug](https://hexdocs.pm/plug/readme.html) 。

  ## 类型

  和 Plug 一样，也包括函数式以及模块式。

  ### 函数式

  简单来说就是形如如下形式的函数：

      (params, options) :: params

  其中 `t:params/0` 是可能会更新的参数的列表或字典，`t:options/0` 是一个选项的列表。

  ### 模块式

  对于复杂的操作流程，例如加载一个模型再通过输入的参数来得到对应的结果，就需要实现一个模块。

  ## 例子

  函数式的例子：

      def load_waveform_from_file(params, opts) do
        file_path = Keyword.get(opts, :waveform_path)

        add(params, :waveform, File.read!(file_path) |> extract_waveform())
      end

  模块式的例子：

      defmodule PitchToWaveform do
        @behaviour QyCore.Recipe

        @impl true
        def init(opts) do
          # TODO: padding default if opt doen't exist.
          opts
        end

        @impl true
        def call(params, [format: :sine_wave] = opts) do
          wave = get(params, :f0)
          |> pitch_to_sine_wave(sample_rate: opts[:sample_rate], init_phase: 0.0)

          params
          |> add(:wave, wave)
        end
      end

  ### 复杂工作流的设计

  TODO
  """

  # TODO: ensure name.
  @type params :: [{atom(), QyCore.Param.t()}] | %{atom() => QyCore.Param.t() | nil}

  @type options :: any()

  @callback init(options()) :: options()

  @callback call(params(), options()) :: params()

  @spec add(params(), atom(), QyCore.Param.t()) :: params()
  def add([_ | _] = params, key, value), do: [{key, value} | params]
  def add(%{} = params, key, value), do: %{params | key => value}

  @spec get(params(), atom()) :: QyCore.Param.t()
  def get(params, key) do
    {_, res} = Enum.find(params, {nil, nil}, fn {k, _} -> key == k end)

    res
  end

  # TODO: impl run
end
