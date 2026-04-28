# Automated Production Line (APL)

> AI Coding 自动化生产线 — 让 AI 编码更准确、更高效、更可靠

---

## 为什么需要 APL？

### APL 的核心能力

| 能力 | 说明 |
|------|------|
| **主 Agent 编排，子 Agent 执行** | 每个阶段由专属子 agent 执行，主 agent 只做调度，上下文干净不污染 |
| **前后端并行设计** | 前端架构师和后端架构师子 agent 同时工作，效率翻倍 |
| **设计稿逐页分析** | 大型设计稿自动派发子 agent 逐页分析行动点，不遗漏任何交互细节 |
| **Source-backed 模式** | 当设计来源是源码包或可通过 Figma 类 API 获取结构化数据时，自动记录 `sourceType`、固定版本、页面映射与交互证据，并贯穿 analyze → design → implement → review → test |
| **Review Loop 自动化** | 评审不通过自动触发修复，循环直到 PASS，无需人工干预 |
| **断点续传** | 任务状态持久化到文件，网络中断或退出后从断点继续，已完成任务不重复执行 |
| **上下文分片** | 每个子 agent 上下文 < 10KB，大型项目不再 token 爆炸 |
| **工程计划驱动** | 每个编码任务先用 writing-plans 生成精确工程计划，再执行，不随意编码 |
| **质量门禁** | 每个阶段有 P0/P1/P2 问题分级，P0 未解决不能进入下一阶段 |

### 解决的核心痛点

| 痛点 | APL 的解法 |
|------|-----------|
| AI 不了解项目架构，代码风格不一致 | `apl:init` 强制建立项目上下文，每个子 agent 必读 |
| 实现与设计稿偏差大 | 设计阶段逐页分析设计稿，review 阶段强制对比；source-backed 场景下进一步要求对齐固定来源版本 |
| 设计来源不可追溯，交互结论容易靠猜 | source-backed 模式把 `pageId`、`sourceRef`、`interactionEvidence`、`pinnedRevision` 变成一等信息 |
| 大型项目 token 超限 | 上下文分片，每个子 agent 只加载当前任务相关文档 |
| 网络中断后重新开始 | 任务级状态持久化，断点续传 |
| 单 agent 串行效率低 | 无依赖任务并行执行，前后端设计同时进行 |
| 编码随意，缺乏计划 | writing-plans → executing-plans 强制先计划后执行 |

---

## 安装

### 前置依赖

- [Claude Code](https://claude.ai/code)
- [Node.js](https://nodejs.org) 18+
- superpowers 插件（见下方步骤）
- `openspec` CLI：`npm install -g @fission-ai/openspec@latest`
- `mmdc`（Mermaid CLI）：`npm install -g @mermaid-js/mermaid-cli`

> 方式一（自动安装）会自动安装 openspec 和 mmdc。方式二（手动）需要先手动安装上述依赖。

### 方式一：Claude Code 自动安装（推荐）

在 Claude Code 中直接输入：

```
帮我安装 APL，交互过程请使用中文：Fetch and follow instructions from https://github.com/flymango-wood/automated-production-line/INSTALL.md
```

### 方式二：手动安装

**Step 1：安装 superpowers 插件**

```
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
```

**Step 2：克隆并安装 APL**

```bash
git clone https://github.com/flymango-wood/automated-production-line.git
cd automated-production-line
bash scripts/install.sh
```

---

## 工作流概览

```
apl:init（一次性）
   ↓
apl:analyze ──→ apl:analyze-review ──(loop until PASS)──→
apl:design（前后端并行）──→ apl:design-review ──(loop until PASS)──→
apl:implement（Agent Teams 并行 + writing-plans + TDD）
   ↓ 每批次自动触发
apl:code-review ──(loop until PASS, max 3)──→
   ↓ 全部批次完成后自动触发
apl:test ──(systematic-debugging loop, max 3/TC)──→
   ↓ PASS 后自动触发
apl:archive
```

用户只需手动触发：`apl analyze`、`apl design`、`apl implement`。  
后续 review、test、archive 全部自动串联，P0 问题自动 loop 修复。

---

## 各阶段说明

### `apl:init` — 项目初始化（一次性）

**做什么**：建立项目架构认知，生成 `openspec/project-info.md`（< 2KB）和结构化约定文件。

- 交互确认技术栈、组件库、样式规范、参考页面
- 读取真实代码提取架构约定，写入独立的结构化文件（而非堆入 project-info.md）
- 后端常用链路自动生成时序图（.mmd + .svg）

**产物**：
- `openspec/project-info.md`（轻量索引，< 2KB）
- `openspec/conventions/api.md`（URL 前缀、HTTP 方法、请求/响应包装类、错误码格式）
- `openspec/conventions/frontend.md`（组件结构、样式变量规则、API 调用模式、路由命名）
- `openspec/conventions/backend.md`（后端格式化、注释规范、依赖注入规范、可读性规则）
- `openspec/conventions/constraints.md`（架构硬约束）
- `openspec/flows/*.mmd`

---

### `apl:analyze` — 需求分析

**人设**：10年资深产品经理，只输出用户视角，零技术细节。

- 调用 `openspec propose` 初始化 change，生成 `proposal.md`（1页纸摘要）
- 调用 `superpowers:brainstorming` 澄清需求
- 有设计稿时逐页派发子 agent 分析行动点（click/hover/scroll 等）
- 对设计来源做分类：`design-code-bundle` / `figma-api` / `none`
- source-backed 场景下额外记录 `sourceType`、`sourceLocator`、`pinnedRevision`、`pageId`、`sourceRef`、`interactionEvidence`
- 生成用例图（.mmd + .svg）

**产物**：`proposal.md`、`requirements.md`、`use-case.mmd/.svg`

> 普通截图、普通 URL、无法获取结构化设计数据的场景会落到 `sourceType: none`，保持现有流程，不新增阻塞要求。

---

### `apl:analyze-review` — 需求评审

**人设**：15年资深产品总监，检查是否真正服务用户。

- 检查 proposal.md 完整性
- 检查需求是否有技术细节泄漏（P0）
- 大型设计稿逐页派发子 agent 核查覆盖率
- source-backed 场景下额外检查：是否存在固定版本、每个 frontend FP 是否能映射到 `pageId` 与 `interactionEvidence`、每条交互结论是否带 `sourceEvidenceRef`
- `sourceType: none` 时不新增 provenance 类 P0
- FAIL 自动触发 apl:analyze 修复，loop 直到 PASS

**产物**：`review-requirements.md`（checkbox 持久化，loop 时只重新检查未解决项）

---

### `apl:design` — 设计（前后端并行）

**人设**：Principal Engineering Manager（10年全栈交付经验），调度前后端专家并行工作。

**前端**（`apl:design-frontend`，Senior Frontend Architect，10年）：
- 先探查现有路由、组件模式、API 调用方式，人工确认后再设计
- 5+ 页面时逐页派发子 agent
- 每页产出：组件树、状态定义、交互逻辑、API 依赖、样式变量映射
- source-backed 场景下页面设计文档还会显式继承 `Source Metadata`、`pinnedRevision`、`pageId`、`sourceRef`、`interactionEvidence`
- `Interaction Logic` 与 `interactionEvidence` 建立明确映射，避免只描述交互、不说明证据来源

**后端**（`apl:design-backend`，Senior Backend Architect，10年高并发分布式系统）：
- 直接读取 `openspec/conventions/api.md` 获取 URL 前缀、HTTP 方法等约定，无需每次搜索源码
- 直接读取 `openspec/conventions/backend.md` 获取后端编码规范（格式化、JavaDoc、参数注释、构造器注入、空行可读性）
- 仅当 conventions 文件缺失时才 fallback 到源码搜索，并自动更新文件
- implementation 设计文档包含 `Code Style Contract`，将代码风格约束显式下发到实现阶段
- 产出：接口定义、数据模型 DDL、业务流程时序图

**产物**：`design/frontend/`、`design/backend/`

---

### `apl:design-review` — 设计评审

**人设**：Principal Architect & Tech Review Board Chair（12年，前后端双专长）。

- 前端检查：组件树、样式变量、设计稿覆盖、权限校验
- source-backed 页面额外检查：来源元数据是否完整、关键动作是否都能回链到 `interactionEvidence`、页面行为是否来自固定版本而不是自由推断
- 后端检查：接口完整性、索引、并发安全、资金安全、数据安全
- 约定合规检查：对照 `openspec/conventions/api.md` 和 `conventions/frontend.md` 精确比对，不符合即 P0
- 集成检查：前端 API 依赖与后端接口定义完全匹配
- PASS 后生成 `tasks.md`（每个 task 含 `Implements: FP-X` 追溯字段；source-backed frontend task 还会带 `pageId`、`sourceRef`、`pinnedRevision`、`interactionId`）

**产物**：`review-design.md`、`tasks.md`

---

### `apl:implement <change>` — 编码

**人设**：Senior Engineering Team Lead（10年，大规模功能交付）。

每个任务子 agent 执行：
1. source-backed frontend task 会先读取来源证据，确认 `pinnedRevision`、`pageId`、`sourceRef`、`interactionId` 与设计文档一致
2. `superpowers:writing-plans` → 生成精确工程计划（文件路径/测试代码/步骤），存储到 `openspec/changes/<change>/plans/<task-id>.md`
3. `superpowers:subagent-driven-development` → 执行计划
4. `superpowers:verification-before-completion` → 验证所有行动点通过

source-backed frontend task 额外要求：
- 关键按钮与交互必须映射到对应 `interactionId`
- 实现行为必须对齐 `pinnedRevision`
- 若设计文档与来源证据冲突，以固定来源证据为准，并在 review 中暴露差异

**后端任务新增强制检查**：
- 必须执行 backend.md 中定义的格式化命令
- 新增/修改的 public class 与 public method 必须满足 JavaDoc 规范（trivial `@Override` 可例外）
- 非平凡参数需有参数说明
- 禁止字段注入（`@Autowired` on field），统一构造器注入
- 字段/构造器/方法间必须有清晰空行间隔

**自动触发链**：
- 每批次完成 → 自动触发 `apl:code-review`（loop until PASS，max 3次）
- 全部批次完成 → 自动触发 `apl:test`

**断点续传**：任务完成后写入 `openspec/changes/<change>/tasks/<task-id>.json`，重启后自动跳过已完成任务。

**产物**：源码、测试文件、`openspec/changes/<change>/tasks/`

---

### `apl:code-review` — 编码评审（自动触发，每批次）

**人设**：Senior Staff Engineer（10年，前后端代码评审）。
- 检查：设计对齐、约定合规（对照 `conventions/api.md` + `conventions/frontend.md` + `conventions/backend.md`）、架构约束、安全性
- source-backed 前端评审不仅检查“像不像设计稿”，还检查“是否对齐到 `pinnedRevision`”；关键交互若无法追溯到 `interactionEvidence` / `sourceEvidenceRef` 视为 P0
- 后端可读性与风格检查：格式化、注释完整性、依赖注入方式、空行可读性（格式化/注入违规按 P0 阻断）
- 新增 FP 追溯检查：`tasks.md` 中每个 `Implements: FP-X` 必须有对应代码覆盖
- FAIL → fix subagent 修复 → 重新 review，最多 3 次
- 3 次仍 FAIL → 停止，人工介入

**产物**：`.apl/reviews/<change>/<task-id>-review.md`

---

### `apl:test` — 测试（自动触发，implement 完成后）

**人设**：Senior QA Engineer（10年，测试策略与自动化）。
- 从 use-case.mmd 派生 E2E 测试（Playwright）
- source-backed 场景下，从 `interactionEvidence` 派生关键交互测试；每个关键 `interactionId` 至少有一个验证用例
- `test-report.md` 增加 `Source Verification Summary`，列出已验证的 `interactionId` 与对应 `pinnedRevision`
- 失败时调用 `superpowers:systematic-debugging` 自动排查
- FAIL → fix subagent 重走 writing-plans → 只重跑失败 TC，最多 3 次/TC
- 全部 PASS → 自动触发 `apl:archive`

**产物**：`test-plan.md`、`test-report.md`

---

### `apl:archive <change>` — 归档（自动触发，test PASS 后）

- 验证 0 P0 测试失败
- `openspec archive change` 归档
- 生成 summary.md（< 1KB，只记录非显而易见的经验）

---

## 断点续传

退出 Claude 后重新进入，直接运行：

```
apl implement <change>
```

APL 读取 `openspec/changes/<change>/tasks/` 状态文件，跳过已完成任务，从断点继续。

> 如果在多台机器上工作，建议将 `openspec/changes/<change>/tasks/` 提交到 git。

---

## 目录结构

```
project-root/
├── openspec/
│   ├── project-info.md              # 项目上下文索引（< 2KB）
│   ├── conventions/
│   │   ├── api.md                   # API 约定（URL 前缀、HTTP 方法、包装类、错误码）
│   │   ├── frontend.md              # 前端约定（组件结构、样式变量、路由命名）
│   │   ├── backend.md               # 后端约定（格式化、注释、依赖注入、可读性）
│   │   └── constraints.md           # 架构硬约束
│   ├── flows/                       # 后端链路时序图
│   ├── changes/<change>/
│   │   ├── proposal.md              # 变更摘要（1页纸）
│   │   ├── requirements.md          # 详细需求文档（含 FP-N 编号、Design Source Provenance、Source Traceability）
│   │   ├── use-case.mmd / .svg      # 用例图
│   │   ├── review-requirements.md   # 需求评审报告
│   │   ├── design/
│   │   │   ├── frontend/            # 前端设计文档（source-backed 页面含 Source Metadata / pinnedRevision / interactionEvidence）
│   │   │   └── backend/             # 后端设计文档
│   │   ├── tasks.md                 # 任务列表（含 Implements: FP-X；source-backed frontend task 额外带 pageId/sourceRef/pinnedRevision/interactionId）
│   │   ├── tasks/                   # 任务状态（断点续传）
│   │   │   └── <task-id>.json
│   │   ├── plans/                   # 每个任务的工程实现计划
│   │   │   └── <task-id>.md
│   │   ├── review-design.md         # 设计评审报告
│   │   ├── test-plan.md
│   │   └── test-report.md
│   └── archived/<change>/summary.md
```

---

## 快速开始

```bash
# 1. 安装
bash scripts/install.sh

# 2. 项目初始化（一次性）
apl init

# 3. 开始新需求
apl analyze "添加商品列表功能"

# 4. 按流程推进（review loop 自动处理）
apl design
apl implement add-product-list
apl test
apl archive add-product-list
```

---

## License

MIT
