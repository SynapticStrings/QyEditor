# 【施工中】QyEditor

轻量网页端歌曲编辑器平台。

[English](README.en.md)

## 特点

* 贝塞尔曲线/手绘的参数调节
* 声库的自查找与组织

## 路线规划

### 包结构与整体的调用顺序

目前活跃的：

- `qy_core` 应用本体

暂时不活跃的：

- `diff_singer` Elixir 端调用 DiffSinger 的应用，装载 ONNX 报错且跨语言较难 debug
- `scripts` 与现成的项目进行对接，不活跃是因为 DiffSinger 目前正在重构应用，很多内容并没有确定
- `web_ui` 网络应用端，需要模型整体可行以及大量的前置知识

调用顺序：

> 用户通过网络（或其他形式）发出请求，经过 `qy_core` 更新输入的状态，调用 `diff_singer` 生成新音频再返回。

其中 `qy_core` 和 `diff_singer` 没有依赖关系。

其联系在原型阶段由手写代码实现，后续 DiffSinger 的 dspx 稳定后将其在 `scipts` 予以实现并且实现桥接的功能。

### Elixir 上运行 DiffSinger 的可行性分析

请参考 [ROADMAP](/apps/diff_singer/ROADMAP.md) 。

### 贝塞尔曲线的相关工具与网页端参数编辑

### 网页的钢琴卷帘窗
