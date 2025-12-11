# 【施工中】QyEditor

轻量网页端歌曲编辑器平台。

[English](README.en.md)

## 特点

* 原生的增量计算与任务编排
  * Simulink / ComfyUI
* 可扩展的应用

## 路线规划

### ProtoType

#### 参数编辑器

#### QyFlow

### 包结构与整体的调用顺序

目前活跃的：

- `orchid` （原 `qy_core`）应用核心业务
  - 迁移至 <https://github.com/SynapticStrings/Orchid>
- `qy_flow` 并行运算
- `qy_music` 乐理支持
- `qy_skala` 语音学支持（skala 是逻辑语中的「音节」）

暂时不活跃的：

- `scripts` 与现成的项目进行对接，不活跃是因为 DiffSinger 目前正在重构应用，很多内容并没有确定
  - 可能只是一个 moresampler 或是什么的调包接口
- `web_ui` 网络应用端，需要模型整体可行以及大量的前置知识
  - 钢琴卷帘
  - ~~一个优秀的产品经理~~

调用顺序：

> 用户通过网络（或其他形式）发出请求，经过 `orchid` 更新输入的状态，调用对应的模型生成新音频再返回。

其联系在原型阶段由手写代码实现。
