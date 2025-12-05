defmodule QyCore.Recipe.Step do
  alias QyCore.Param

  @typedoc """
  目前包括三类实现：

  * 模块实现：直接指定一个模块名，要求该模块实现 `QyCore.Recipe.Step` 行为。
  * 函数对实现：指定一个包含两个函数的元组，分别对应 `prepare/1` 和 `run/2` 回调。
  * 单函数实现：指定一个函数，等同于只实现 `run/2` 回调，`prepare/1` 为 &(&1) ，不会进行其他操作。
  """
  @type implementation :: module()
  | {function(), function()} |
  function()
  | nil

  @type input_keys :: tuple() | atom()
  @type output_keys :: tuple() | atom()
  @type input :: tuple() | Param.t()
  @type output :: tuple() | Param.t()

  @type step_options :: term()
  @type running_options :: {:running, term()}

  @type step_schema :: {implementation(), input_keys(), output_keys()}
  @type step_with_options :: {
    implementation(), input_keys(), output_keys(),
    # 这里将 step_options 放在元组中是为了方便在运行时对最后的 metadata/running_options 进行注入和修改
    step_options(), keyword()
  }
  @type t :: step_schema() | step_with_options()

  ## module step 实现的回调

  @doc "对参数进行预处理"
  @callback prepare(options :: step_options()) :: {:ok, step_options()} | {:error, term()}

  @callback run(input(), step_options()) :: {:ok, output()} | {:error, term()}

  ## public API

  def inject_options({impl, in_keys, out_keys}, opts, meta), do: {impl, in_keys, out_keys, opts, meta}
  def inject_options({impl, in_keys, out_keys, opts, meta}, {:step, new_opts}) do
    merged_opts = Map.merge(opts, new_opts)
    {impl, in_keys, out_keys, merged_opts, meta}
  end

  def extract_schema({impl, in_keys, out_keys}), do: {impl, in_keys, out_keys}
  def extract_schema({impl, in_keys, out_keys, _opts}), do: {impl, in_keys, out_keys}
  def extract_schema({impl, in_keys, out_keys, _opts, _meta}), do: {impl, in_keys, out_keys}

  defmacro __using__(_opts) do
    quote do
      @behaviour QyCore.Recipe.Step

      # 默认的 prepare 只是原样返回 opts
      def prepare(opts), do: {:ok, opts}

      # 允许覆盖
      defoverridable prepare: 1
    end
  end
end
