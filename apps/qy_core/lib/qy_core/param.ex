defmodule QyCore.Param do
  @moduledoc """
  关于序列参数的相关模块。

  设计该模块的目的是实现一系列和参数有关的逻辑以及定义一系列的接口以帮助或约束其他使用 `qy_core`
  的开发者使其更专注业务逻辑。
  """

  @type t :: %__MODULE__{
          name: name(),
          type: param_type(),
          payload: payload(),
          metadata: map()
  }
  defstruct [
    :name, :type,
    :payload,
    metadata: %{}
  ]

  ## 类型

  @type name :: term()
  @type param_type :: atom() | module()
  @type raw_payload :: [any()] | nil
  @type ref_payload :: {:ref, module() | pid(), term()}
  @type payload :: raw_payload() | ref_payload()

  ## 函数

  def new(name, type, payload \\ nil, metadata \\ %{}) do
    %__MODULE__{
      name: name,
      type: type,
      payload: payload,
      metadata: metadata
    }
  end

  def get_payload(%__MODULE__{payload: payload}) when is_list(payload), do: payload
  def get_payload(%__MODULE__{payload: {:ref, repo, id}}) do
    case repo do
      mod when is_atom(mod) ->
        mod.get_param_payload(id)

      # pid when is_pid(pid) ->
      #   send(pid, {:get_param_payload, self(), id})

      #   receive do
      #     {:param_payload, ^id, payload} -> payload
      #   after
      #     5_000 -> raise "Timeout while getting param payload for id #{inspect(id)}"
      #   end
    end
  end

  def set_payload(%__MODULE__{} = param, new_payload) do
    %__MODULE__{param | payload: new_payload}
  end

  # metadata 相关函数后续添加
end
