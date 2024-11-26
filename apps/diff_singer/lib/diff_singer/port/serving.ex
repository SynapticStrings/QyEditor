defmodule DiffSinger.Port.Serving do
  @moduledoc """
  我先在这空着，我有预感这逼玩意实际上会很复杂。

  大概就两种策略，一个是用于低预算纯 CPU 跑的；还有一个是实时体验用显卡来推理。

  这么设计是因为我有一次尝试用轻薄本尝试把 DiffSinger 的声学模型丢进去。

  您猜怎么着？欸，崩了！

  一个模型这个进程都暴毙掉了，要我把所有的模型都丢进去，那彻底寄。

  也不知道是 CPU 的问题还是内存的问题。所以这个【策略】也不能和 `device` 绑定。

  这玩意儿，可能还真是 BEAM 生态独有的，应该挺好玩，所以我就单独写一份了。

  另外，因为有很多中间量（音高、梅尔谱），有些模型甚至连音素时长之类的都会自动生成，其中有些场景，
  是不需要给用户看的，有些场景需要，还有些用户来亲自修改然后模型再执行后面的步骤（很多）。

  所以直接用 `Ortex.Serving` 有点太简单了。
  """
  @behaviour Nx.Serving

  def init(_type, _arg, [_defn_options]) do
    # 总得返回个东西回来
    {:ok, fn _ -> nil end}
  end

  def handle_batch(_arg0, _partition, _state) do
  end
end
