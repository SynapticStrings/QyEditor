# DiffSinger

DiffSinger 的 Elixir 包装。

## 特点

- 根据声库[^singer]模型的名字目录以及输入输出的信息构建推理的依赖图
  - 类似于 ComfyUI 或 Simulink ，但是无需从头手动搭建
- 基于增量计算的音频生成
- 根据设备性能的差异执行不同策略
  - 实时快速的，带来与原生设备相似的体验
  - 轻便低耗的，可以在低配设备上运行

[^singer]:目前只支持 OpenUTAU for DiffSinger 的声库

## 为何选择 Elixir ？

一言以蔽之：路径依赖加上 BEAM 系语言在高并发高容错的优势

### 可行性

- 基于 Ort 的 Ortex 可以执行 ONNX 模型的推理任务

### 优越性

等想到再编。

- Elixir 变量不可变的特性便于实现增量计算
