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

  其中 `params` 是可能会更新的参数的列表或字典，`options` 是一个选项的列表。

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
end
