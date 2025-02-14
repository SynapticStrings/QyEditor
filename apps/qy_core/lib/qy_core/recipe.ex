defmodule QyCore.Recipe do
  # 当前的难点
  # 参数的检查
  # 不同类型参数的转变
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
        def require(), do: {{:f0}, {:wave}}

        @impl true
        def infer({f0}, [format: :sine_wave] = opts) do
          {pitch_to_sine_wave(f0, sample_rate: opts[:sample_rate], init_phase: 0.0)}
        end
      end

  ### 复杂工作流的设计

  TODO
  """

  # TODO: ensure name.
  @type params :: %{atom() => QyCore.Param.t() | nil}

  @type options :: any()

  @callback init(options()) :: options()

  # 需要改名字吗？
  @callback require() :: {tuple(), tuple()}

  @doc "执行实际推理任务的函数，其输入与输出均为元组"
  @callback infer(tuple(), options()) :: tuple()

  @spec add(params(), atom(), QyCore.Param.t()) :: params()
  def add(params, key, value), do: %{params | key => value}

  @spec get(params(), atom()) :: QyCore.Param.t()
  def get(params, key), do: Map.get(params, key)

  def prelude(params, input_key) do
    # Is it works?
    {params, Enum.map(input_key, fn k -> Map.get(params, k) end)}
  end

  def exec_step({params, input}, func, opts) do
    {params, func.(input, opts)}
  end

  def postlude({params, result}, output_key) do
    result
    |> then(&Enum.zip(output_key, &1) |> Enum.into(%{}))
    |> then(&Map.merge(params, &1))
  end

  @spec exec(params(), {tuple(), tuple()}, function(), function(), options()) :: params()
  def exec(params, {input_key, output_key}, init_func \\ &(&1), infer_func, opts)
      when is_function(infer_func, 2) and is_function(init_func, 1) do
    params
    |> prelude(input_key)
    |> exec_step(infer_func, init_func.(opts))
    |> postlude(output_key)
  end

  defoverridable exec: 4

  defmacro __using__(_opts) do
    quote do
      @behavoir QyCore.Recipe

      import QyCore.Recipe
    end
  end
end
