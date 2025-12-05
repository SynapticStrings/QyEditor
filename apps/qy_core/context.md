## **AI 助手交接文件：QyCore 项目与用户深度上下文**

**项目代号**：QyCore
**交接时间**：2025年12月
**当前阶段**：核心调度层 (Kernel) 已定型，准备迈向 应用层/生态层。

---

### **1. 用户画像与协作模式 (The User Persona)**

*   **角色定位**：**“双总师” (The Dual Chief)**。
    *   用户不仅是架构师（关注愿景、解耦、纯粹性），也是工程师（关注测试、落地成本、开发体验）。
    *   **协作原则**：拒绝只会复读的 AI。你需要遵循 **“守破离”** —— 理解他的意图，指出设计的弱点，提出更优的方案。
*   **技术偏好**：
    *   **Elixir/OTP**：这是核心栈。熟悉 GenServer、Supervisor 理念。
    *   **风格**：极度厌恶“黑魔法”和过度复杂的 DSL，但接受为了减少样板代码而引入的适度宏（如 `use QyCore.Recipe.Step`）。
    *   **设计哲学**：推崇 **“数据流驱动”**、**“分层架构”**（纯逻辑 vs 副作用）、**“分形结构”**（无限嵌套）。
    *   **当前痛点**：ML 环境配置复杂（暂时跳过，使用 Mocking 策略）。

---

### **2. 项目愿景 (The Vision)**

*   **短期目标**：构建一个歌声合成/音频处理流水线（类似于 Vocaloid/UTAU 的后端）。
*   **长期愿景**：**Elixir 版的 ComfyUI**。
    *   Python 负责“算”（无情的 Tensor 机器）。
    *   Elixir 负责“管”（DAG 调度、并发、WebSocket 推流、状态管理）。

---

### **3. 当前架构快照 (Architecture Snapshot)**

我们已经完成了一次重大的架构重构，现在的设计非常稳固。

#### **A. 数据层**
*   **`QyCore.Param`**：
    *   核心载体。区分了 **Name** (在流程中的语义，如 `:vocal_track`) 和 **Type** (数据类型，如 `:audio`).
    *   **Payload**：可以是内存数据 (List/Binary)，也可以是 **`QyCore.Repo.Ref`** (大文件的引用)。
*   **`QyCore.Repo`**：
    *   数据仓库抽象。解决了“如何在 Step 间传递 100MB 音频”的问题。目前实现了 `Repo.Local` (ETS)。

#### **B. 定义层**
*   **`QyCore.Recipe`**：
    *   DAG 定义。**核心原则：Recipe 是上帝**。Step 产出的数据名称必须被 Recipe 定义的 `output_keys` 强制重命名，以保证上下游连接。
    *   **`Recipe.walk/2`**：实现了类似 AST 的树遍历，用于全局配置注入 (`assign_options`)。
*   **`QyCore.Recipe.Step`**：
    *   计算单元。通过 `use QyCore.Recipe.Step` 定义。
    *   包含 `prepare/1` (编译期/构建期) 和 `run/2` (运行期)。

#### **C. 调度与执行层 (核心引擎)**
*   **`QyCore.Scheduler` (The Brain)**：
    *   **纯函数式状态机**。只负责维护 `Context`（Pending Steps, Available Keys）。
    *   **动态调度**：不依赖静态排序列表，而是基于 **Data Availability** (谁的原料齐了谁就 Ready)。
*   **`QyCore.Executor` (The Interface)**：
    *   定义执行器的行为。
*   **`QyCore.Executor.Serial` (The Implementation)**：
    *   当前的单线程执行器。负责驱动 Scheduler 循环。
*   **`QyCore.Executor.StepRunner` (The Worker)**：
    *   **原子操作封装**。负责 Input 准备、Telemetry 触发、Output 重命名。**这是为了未来实现 Parallel Executor 而抽离的公共逻辑。**

#### **D. 组合与扩展**
*   **`NestedStep`**：
    *   **分形架构**的体现。一个 Recipe 可以被封装成一个 Step。
    *   实现了 `input_map` / `output_map` 适配器，解决参数命名不一致问题。
*   **Telemetry / Hooks**：
    *   放弃了回调函数列表，全面拥抱 **`:telemetry`**。
    *   Step 内部通过 `report(opts, 50, "msg")` 广播进度，解耦了 UI 更新逻辑。
*   **Resource Injection**：
    *   外部重资源（如 DB 连接、模型 PID）通过 `opts` 注入，Step 内部按需获取。

---

### **4. 关键设计决策记录 (Decision Log)**

1.  **Graph 排序 vs 动态调度**：
    *   我们放弃了在运行前生成静态执行列表。改用 `Scheduler.next_ready_steps`。这天然支持并行和分支逻辑。
    *   `Graph` 模块保留，但仅用于 **静态校验** (Validate) 和 **死锁检测**。

2.  **Telemetry 同步机制**：
    *   明确了 `:telemetry.execute` 是同步调用。Handler 运行在计算进程中。
    *   因此，Web 层（LiveView）更新必须在 Handler 里做跨进程消息投递 (`Phoenix.PubSub`)，以免阻塞计算。

3.  **StepRunner 独立**：
    *   为了避免在 `Serial` 和未来的 `Parallel` 执行器中重复写 Hook 触发、错误处理逻辑，我们将“运行一个 Step”的逻辑独立为 `StepRunner`。

---

### **5. 待办事项与下一步 (The Roadmap)**

我们正处于从“后端内核”向“全栈系统”跨越的边缘。

*   **当前阻塞点**：无。
*   **下一阶段优先级**：**Direction B - 序列化与元数据 (Serialization & Manifest)**。
    *   **目标**：让前端能知道有哪些 Step 可用，并能将 JSON 保存的图转换为 `Recipe` 结构体。这是实现 No-Code Editor 的前提。
*   **后续计划**：
    *   **qy_flow / Parallel Executor**：利用 `Task` 或 `GenStage` 实现真正的并行执行。
    *   **Python/ONNX Interop**：替换目前的 Mock Agent ，实现虚拟歌姬。

---

### **6. 给继任者的留言**

亲爱的继任者：

你接手的代码库（测试覆盖率极高）已经具备了极其优雅的 **“逻辑(Scheduler) 与 副作用(Executor) 分离”** 特性。

在接下来的对话中，请务必注意：
1.  **保持命名的严谨**：Scheduler vs Executor，Param vs Payload。
2.  **不要破坏分形结构**：任何新功能（如 Error Handling, Retry）都必须确保能正确处理 Nested Recipe。
3.  **关注开发体验 (DX)**：用户非常看重开发者的心智负担，保持 API 的简洁。

现在，请你接过接力棒，在这个坚实的地基上，帮用户搭建起那座通往 ComfyUI 的桥梁。祝你好运。
