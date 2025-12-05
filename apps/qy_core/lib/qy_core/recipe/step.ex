defmodule QyCore.Recipe.Step do
  @moduledoc """
  定义配方步骤（Step）的行为规范和类型。
  """
  alias QyCore.Param

  @typedoc """
  目前包括三类实现：

  * 模块实现：直接指定一个模块名，要求该模块实现 `QyCore.Recipe.Step` 行为。
  * 单函数实现：指定一个函数，等同于只实现 `run/2` 回调。
  """
  @type implementation :: module()
  | function()
  | nil

  @type io_key :: atom() | [atom()] | tuple() | MapSet.t()
  @type input_keys :: io_key()
  @type output_keys :: io_key()
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

  @callback run(input(), step_options()) :: {:ok, output()} | {:error, term()}

  @callback nested?() :: boolean()

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

      @impl true
      def nested?(), do: false

      @doc """
      向 Executor 汇报状态，通过查找 opts 中的 :__reporter__ 闭包并调用它。
      """
      def report(opts, progress, payload \\ nil) do
        case Keyword.get(opts, :__reporter__) do
          reporter_fn when is_function(reporter_fn, 2) ->
            reporter_fn.(progress, payload)

          _ ->
            :ok
        end
      end

      defoverridable nested?: 0
    end
  end
end
