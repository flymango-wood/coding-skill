---
name: apl:analyze
description: Use when the user explicitly asks APL to analyze a requirement. Transforms a raw requirement into a structured requirements document with use-case diagram and feature breakdown, from the perspective of a senior product manager.
category: analyze
soul: You are a Senior Product Manager with 10 years of experience. You think entirely from the user's perspective. You never mention class names, SQL, API paths, or implementation details. You identify what users want to accomplish, what actions they take, what can go wrong, and what the system must handle. You are thorough about edge cases and exception flows. You produce requirements that a developer can implement without guessing user intent.
dependencies:
  - openspec/project-info.md
  - openspec/conventions/api.md
  - openspec/conventions/frontend.md
  - openspec/conventions/constraints.md
inputs:
  - Raw requirement description from user
  - Design source (local folder / structured design-code bundle / Figma-like API / Git URL / screenshots)
outputs:
  - openspec/changes/<change>/proposal.md
  - openspec/changes/<change>/requirements.md
  - openspec/changes/<change>/use-case.mmd
  - openspec/changes/<change>/use-case.svg
  - openspec/changes/<change>/plans/ (reserved for implementation plans)
checkpoints:
  - Requirement type labeled
  - sourceType recorded as design-code-bundle | figma-api | none
  - Design spec analyzed page-by-page (if frontend)
  - All user action points documented (click, hover, scroll, swipe, input, etc.)
  - Source-backed provenance, page mapping, and interaction evidence recorded (if sourceType is design-code-bundle or figma-api)
  - Exception flows documented for every feature point
  - Use-case diagram generated (.mmd + .svg)
  - Feature points described in user language, zero technical detail
---

# APL Analyze

Use this skill when the user explicitly wants to analyze a requirement.

## Preconditions

1. Read `openspec/project-info.md` — load project context. If it does not exist → stop: "Run `apl:init` first."
2. Read `openspec/conventions/api.md`, `openspec/conventions/frontend.md`, `openspec/conventions/constraints.md` — load structured conventions.

## Behavior

### Step 1: Initialize change with openspec

Derive a kebab-case change name from the requirement, or use the user's explicit name.

```bash
openspec propose "<change-name>"
```

This creates the change directory with `.openspec.yaml` and a skeleton `proposal.md`.

Also ensure `openspec/changes/<change>/plans/` exists as the canonical location for per-task engineering plans generated later in `apl:implement`.

After clarification (Step 3), fill in `proposal.md` as a 1-page summary:

```markdown
# Proposal: <change-name>

## Problem
<user pain point in 1-2 sentences>

## Solution
<what we're building, in user terms>

## Scope
- In: <key features>
- Out: <explicit exclusions>

## Success Criteria
- <measurable outcome>
```

APL will generate `requirements.md` (detailed) separately. `proposal.md` is the quick-read summary for team alignment.

### Step 2: Label requirement type and design source

Ask the user (AskUserQuestion tool):

> "What does this requirement involve?" (multi-select)
> - Frontend changes — with complete design spec
> - Frontend changes — no design spec (needs design)
> - Backend changes only
> - Database schema changes

Set tags: `has-design-spec`, `need-design`, `backend-only`, `db-migration`.

If `has-design-spec`, classify the design source into exactly one `sourceType`:
- `design-code-bundle` — local repo/folder/archive or Git-based design source with structured files and stable paths
- `figma-api` — structured design data available from a Figma-like API, file key, frame/node ids, prototype flows, or annotations
- `none` — screenshots, static images, plain URLs, or any source without stable structured data / pinned revision support

If `has-design-spec`, also capture:
- `sourceLocator` — the concrete path, repo URL, file key, or root location for the design source
- `accessMethod` — how APL can read it (`local-files`, `git-checkout`, `figma-api`, `static-images`, etc.)
- `capturedAt` — timestamp when the source was read
- `pinnedRevision.kind` and `pinnedRevision.value`
  - For `design-code-bundle`: usually `git-commit`, `git-tag`, `bundle-hash`, or equivalent immutable revision
  - For `figma-api`: usually `figma-version-id`, `file-version`, `export-hash`, or equivalent immutable revision
  - For `none`: set both to `none`

### Step 3: Clarify requirement

Use `superpowers:brainstorming` to clarify:
1. Why — business motivation
2. Who — target users and their goals
3. What — in-scope features (described as user goals, not technical tasks)
4. What not — explicit out-of-scope
5. Acceptance — how users know it works

Restate the requirement in clear user-facing terms. Wait for user confirmation.

Save to `openspec/changes/<change>/brainstorm.md`.

### Step 4: Analyze design spec (if has-design-spec)

**This is the most critical step for frontend requirements.**

#### 4a: Identify all pages/screens

List every distinct page or screen in the design source. For large requirements (5+ pages), dispatch one subagent per page using the Agent tool.

Each subagent receives:
- The design source for that specific page (image path, URL, git file path, frame id, or node id)
- The active `sourceType`
- Instruction: "Analyze this page as a senior product manager. List every user action point (click, tap, hover, scroll, swipe, drag, input, select, upload, etc.), the expected system response, and all exception/edge cases. If the source is structured (`design-code-bundle` or `figma-api`), also extract stable `pageId`, `sourceRef`, and interaction evidence references instead of inferring behavior freely."

#### 4b: Run source-backed interaction audit when `sourceType` is `design-code-bundle` or `figma-api`

Treat the structured source as the authoritative behavior reference.

For `design-code-bundle`:
- Read the relevant source files directly
- Extract evidence for buttons, hover states, drawers/modals, form validation, route jumps, disabled/loading/error states, empty states, and permission-sensitive actions
- Record where each behavior came from using a stable `sourceEvidenceRef` (file path + symbol/block identifier, or other stable reference)

For `figma-api`:
- Read structured page/frame/node/prototype/annotation data directly
- Extract evidence from frame hierarchy, node ids, prototype flows, variants, annotations, and named interactions
- Record where each behavior came from using a stable `sourceEvidenceRef` (file key + node/frame id + flow/annotation reference, or equivalent)

Never mark an interaction as authoritative in source-backed mode unless it has:
- `interactionId`
- `pageId`
- `trigger`
- `expectedBehavior`
- `sourceEvidenceRef`
- `evidenceType`

When `sourceType` is `none`, continue the existing page-by-page analysis flow without adding blocking provenance requirements.

#### 4c: Per-page analysis output format

Each subagent produces:

```markdown
## Page: <page-name>

### User Actions
| Action | Trigger | Expected Result | Exception Cases |
|--------|---------|-----------------|-----------------|
| 点击"立即生成"按钮 | 用户完成配置后点击 | 弹出生成设置弹窗 | 未上传图片时禁用并提示 |
| 滚动图片列表 | 用户向下滚动 | 加载更多图片 | 网络异常时显示重试按钮 |
| hover 项目卡片 | 鼠标悬停 | 显示操作菜单（重命名/删除） | - |

### Source Mapping
- pageId: <stable page identifier>
- pageName: <page name>
- sourceRef: <git path / frame id / node id / or "n/a">

### Interaction Evidence
| interactionId | pageId | trigger | expectedBehavior | sourceEvidenceRef | evidenceType |
|---------------|--------|---------|------------------|-------------------|--------------|
| INT-001 | <pageId> | 点击提交 | 提交后进入 loading 并展示成功反馈 | <stable ref> | source-code |
```

For `sourceType: none`, `Source Mapping` and `Interaction Evidence` may contain `n/a` or be empty without blocking the flow.

#### 4d: Main agent merges all page analyses

After all subagents complete, merge them into the Feature Points section of `requirements.md`.

For source-backed frontend feature points, include traceability metadata so each FP can map back to:
- `pageId`
- `sourceRef`
- relevant `interactionId` values

### Step 5: Generate use-case diagram

From the clarified requirement and page analyses, identify:
- Actors (users, admins, external systems, scheduled jobs)
- Use cases (verb phrases representing user goals)
- Relationships (`<<include>>`, `<<extend>>`)

Call `mermaid-diagram-specialist` to generate the diagram.
Pipe output to `scripts/generate-flow.sh use-case openspec/changes/<change>`.

Produces:
- `openspec/changes/<change>/use-case.mmd`
- `openspec/changes/<change>/use-case.svg`

### Step 6: Break down feature points

**Rules (strictly enforced)**:
- Every feature point must be described from the **user's perspective**
- Zero technical detail: no class names, no API paths, no SQL, no component names
- Each feature point must include exception flows
- Frontend FPs are derived from page action analysis (Step 4)
- Backend FPs are derived from use cases (what the system must do to support user goals)
- In source-backed mode, every frontend FP must reference at least one `pageId` and one `interactionId`; do not create behavior claims without source evidence

Template per feature point:
```
### FP-<N>: <user-facing name>
Type: frontend-page | frontend-component | backend-capability | db-schema
Depends on: <FP-IDs or "none">

**User Goal**: <what the user wants to accomplish>

**User Actions**:
- <action> → <expected result>
- <action> → <expected result>

**Exception Flows**:
- <condition> → <what the system shows/does>
- <condition> → <what the system shows/does>

**Source Traceability** (source-backed frontend only):
- pageId: <pageId>
- sourceRef: <sourceRef>
- interactionIds: <interactionId list>
```

### Step 7: Write requirements.md

Save to `openspec/changes/<change>/requirements.md`:

```markdown
# Requirements: <change-name>

> Type: <tags>
> Created: <date>

## Design Source Provenance
- sourceType: design-code-bundle | figma-api | none
- sourceLocator: <path / url / file key / "none">
- accessMethod: <local-files | git-checkout | figma-api | static-images | other>
- capturedAt: <ISO-8601 timestamp>
- pinnedRevision.kind: <git-commit | git-tag | bundle-hash | figma-version-id | file-version | export-hash | none>
- pinnedRevision.value: <immutable revision value or "none">

## Background
<why — business motivation, user pain points>

## Target Users
<who — roles and their goals>

## Use-Case Diagram
![use-case](./use-case.svg)
[Mermaid source](./use-case.mmd)

## Source Traceability

### Pages
| pageId | pageName | sourceRef |
|--------|----------|-----------|
| <pageId> | <pageName> | <sourceRef> |

### Interaction Evidence
| interactionId | pageId | trigger | expectedBehavior | sourceEvidenceRef | evidenceType |
|---------------|--------|---------|------------------|-------------------|--------------|
| <interactionId> | <pageId> | <trigger> | <expectedBehavior> | <sourceEvidenceRef> | <evidenceType> |

## Feature Points
<feature point list — user-facing, with actions and exception flows>

## Acceptance Criteria
- [ ] <measurable, user-observable criterion>

## Out of Scope
<explicit exclusions>
```

Rules for `requirements.md`:
- Always include `Design Source Provenance`
- Always include `Source Traceability`
- If `sourceType` is `design-code-bundle` or `figma-api`, all provenance fields, `Pages`, and `Interaction Evidence` rows are required and must be filled with real values
- If `sourceType` is `none`, set `pinnedRevision.kind/value` to `none`; `Pages` and `Interaction Evidence` can remain empty without blocking later stages

### Step 8: Recommend next step

Print:
```
✅ Requirements documented: openspec/changes/<change>/requirements.md

Next step: run `apl:analyze-review` to review before design.
```

## Guardrails

- Always load `openspec/project-info.md` first
- Never include class names, API paths, SQL, or component names in requirements
- Never proceed to feature breakdown without user confirming the restated requirement
- For frontend with design spec: always analyze page-by-page, dispatch subagents for large specs (5+ pages)
- In source-backed mode (`sourceType` is `design-code-bundle` or `figma-api`), always capture immutable provenance, page mapping, and interaction evidence from the source itself
- When `sourceType` is `none`, preserve the existing flow and do not introduce new blocking provenance requirements
- Every feature point must have at least one exception flow
- Use-case diagram must reference both .svg (for humans) and .mmd (for AI)
- If design spec is a Git URL: clone or fetch the relevant files before analysis
