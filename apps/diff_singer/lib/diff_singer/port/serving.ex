defmodule DiffSinger.Port.Serving do
  @moduledoc """
  我先在这空着，我有预感这逼玩意实际上会很复杂。

  大概就两种策略，一个是用于低预算纯 CPU 跑的；
  还有一个是实时体验用显卡来推理。

  这么设计是因为我有一次尝试用轻薄本尝试把 DiffSinger
  的声学模型丢进去。

  您猜怎么着？欸，崩了！

  一个模型都这样，要我把所有的模型都丢进去，那彻底寄。

  也不知道是 CPU 的问题还是内存的问题。所以这个`策略`
  也不能和设备绑定。

  这玩意儿，可能还真是 BEAM 生态独有的。所以应该挺好玩。
  """
  @behaviour Nx.Serving

  def init(_type, _arg, _list) do
  end

  def handle_batch(_arg0, _partition, _state) do
  end
end
