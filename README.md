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
- `diff_singer` Elixir 端调用 DiffSinger 的应用

暂时不活跃的：

- `scripts` 与现成的项目进行对接，不活跃是因为 DiffSinger 目前正在重构应用，很多内容并没有确定
- `web_ui` 网络应用端，需要模型整体可行以及大量的前置知识

调用顺序：

> 用户通过网络（或其他形式）发出请求，经过 `qy_core` 更新输入的状态，调用 `diff_singer` 生成新音频再返回。

其中 `qy_core` 和 `diff_singer` 没有依赖关系。

其联系在原型阶段由手写代码实现，后续 DiffSinger 的 dspx 稳定后将其在 `scipts` 予以实现并且实现桥接的功能。

### Elixir 上运行 DiffSinger 的可行性分析

#### 梳理 DiffSinger 模型的推理流程

主要指的是 OpenVPI 维护的版本。

大致分成方差模型（Variance Model）、声学模型（Acoustic Model）以及声码器（Vocoder）三个部分。

以 Qixuan 为例，其目录为下：

```tree
~\CODE\QYEDITOR\PRIV\QIXUAN_V2.5.0_DIFFSINGER_OPENUTAU
├─dsdur
├─dspitch
├─dsvariance
└─dsvocoder
```

在项目的根目录也存在着一系列的模型，其主要是 acoustic model。

#### Ort 使用 DiffSinger 的可行性

*如果这个也不行的话，那就放弃吧。*

### 声库模型的自动查找与尝试组织

主要有三种使用场景：

1. 解压了的 OpenUTAU 声库
2. 单纯的一堆 onnx 文件
3. onnx 文件以及确定了的配置

后者只需设计好相对应的规范，按照设置来确定模型的步骤即可。

### 贝塞尔曲线的相关工具与网页端参数编辑

### 网页的钢琴卷帘窗
