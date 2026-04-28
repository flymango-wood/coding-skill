---
name: apl:design-review
description: Use when apl:design completes. Dispatches frontend and backend reviewers in parallel, then runs integration check. Generates tasks.md on PASS.
category: design
soul: You are a Principal Architect and Technical Review Board Chair with 12 years of experience. You coordinate parallel specialist reviews and personally verify that frontend and backend designs are fully aligned. You have deep expertise in both frontend architecture and backend system design, making you uniquely qualified to catch integration gaps. You block implementation until every interface contract is consistent and every security/concurrency risk is addressed.
dependencies:
  - openspec/project-info.md
  - openspec/changes/<change>/design/frontend/
  - openspec/changes/<change>/design/backend/
inputs:
  - All files in `openspec/changes/<change>/design/frontend/` (if exists)
  - All files in `openspec/changes/<change>/design/backend/` (if exists)
outputs:
  - openspec/changes/<change>/review-design.md
  - openspec/changes/<change>/tasks.md (only on PASS)
checkpoints:
  - Frontend design docs complete and correct
  - Backend design docs complete and correct
  - Frontend API dependencies match backend API definitions
  - Source-backed frontend docs include provenance metadata and interaction evidence traceability (if sourceType is design-code-bundle or figma-api)
  - All P0 items resolved before tasks.md is generated
---

# APL Design Review

## Preconditions

1. Read `openspec/project-info.md`.
2. Read local `openspec/conventions/api.md`, `openspec/conventions/frontend.md`, `openspec/conventions/backend.md`, and `openspec/conventions/constraints.md`.
3. If the orchestrator passed `external backend context`, use its `project-info.md`, `conventions/api.md`, `conventions/backend.md`, and `conventions/constraints.md` as the authoritative backend design-review baseline for backend checks.
4. If the orchestrator passed `external frontend context`, use its `project-info.md`, `conventions/frontend.md`, and `conventions/constraints.md` as the authoritative frontend design-review baseline for frontend checks.
5. Verify `openspec/changes/<change>/design/frontend/` or `openspec/changes/<change>/design/backend/` exists. If neither → stop: "Run `apl:design` first."
6. Read `openspec/changes/<change>/requirements.md` to determine `sourceType`, `pinnedRevision`, page mappings, and `interactionEvidence`.

## Behavior

### Step 1: Dispatch parallel reviewers

Use Agent tool to dispatch simultaneously:

**Frontend reviewer subagent** (if `openspec/changes/<change>/design/frontend/` exists):
Check each page design doc:
- Component tree present with exact component counts → else P0
- State shape defined → else P0
- Every interaction has exception case → else P0
- All style values use variables.less variables → else P0
- Design source page coverage complete → else P0
- `Source Metadata` section present → else P0 in source-backed mode, P1 otherwise
- `Pinned Source Revision` section present → else P0 in source-backed mode, P1 otherwise
- `Source Page Mapping` section present → else P0 in source-backed mode, P1 otherwise
- `Interaction Evidence` section present → else P0 in source-backed mode, P1 otherwise
- `Static Assets` table present and all assets listed → else P0
- `Component Behavior Constraints` section present (Drawer getContainer, Modal zIndex, etc.) → else P0
- API dependencies listed → else P1
- Loading/empty/error states handled → else P1
- Permission-sensitive operations have auth checks → else P0

Additional frontend P0 checks when `sourceType` is `design-code-bundle` or `figma-api`:
- Page doc `pageId` maps to a page in `requirements.md` → else P0
- Page doc `sourceRef` matches the stable mapping in `requirements.md` → else P0
- Page doc `Pinned Source Revision` matches `requirements.md` → else P0
- All key user actions in `Interaction Logic` map to `interactionId` entries in `Interaction Evidence` → else P0
- All cited interactions trace back to `requirements.md` `interactionEvidence` rows → else P0
- Page design behavior is derived from the pinned source revision, not from free inference → else P0

**Backend reviewer subagent** (if `openspec/changes/<change>/design/backend/` exists):
Check api.md, data-model.md, implementation.md, business-flows.md:

*Completeness*:
- Every API has request/response/error codes → else P0
- Every table has indexes on query fields → else P0
- **Every backend FP has implementation.md with Service/Mapper method signatures** → else P0
- **Service layer logic covers all business rules from requirements** → else P0
- Key business flows have sequence diagrams → else P1

*Convention conformance*:
- API paths match existing URL prefix convention → else P0
- HTTP methods match existing project conventions → else P0

*Concurrency & availability*:
- Concurrent write operations have idempotency design → else P0
- Batch/heavy operations have timeout and retry strategy → else P1
- Scheduled jobs have distributed lock to prevent duplicate execution → else P0
- Long-running operations are async, not blocking HTTP → else P1

*Data & financial safety*:
- Financial/balance operations have transaction boundary defined → else P0
- Balance deduction has pre-check before task creation → else P0
- Sensitive data (user ID, payment info) not exposed in API response → else P0
- Bulk operations have upper limit validation (frontend + backend) → else P0

*Data integrity*:
- Status transitions are explicit and exhaustive → else P1
- Soft delete vs hard delete strategy defined → else P1
- Data cleanup/expiry strategy defined for temporary data → else P2

*Architecture constraints*:
- project-info.md Hard Constraints all respected → else P0

### Step 2: Convention conformance check (main agent)

Before integration check, verify both designs conform to conventions using the structured files:

**Backend** — compare every API in api.md against `openspec/conventions/api.md`:
- URL prefix matches → else P0
- HTTP methods match → else P0
- Request/response wrapper class matches → else P0
- Error code format matches → else P0

**Frontend** — compare page docs against `openspec/conventions/frontend.md`:
- Route naming matches convention → else P0
- API call style matches service pattern → else P1
- Style values use variables from the declared variables file → else P0

### Step 3: Source-backed traceability check (main agent)

When `sourceType` is `design-code-bundle` or `figma-api`, verify:
- Every source-backed frontend page doc includes `sourceType`, `sourceLocator`, `pinnedRevision`, `pageId`, and `sourceRef` → else P0
- Every key frontend action can be traced from page doc `interactionId` → `requirements.md` `interactionEvidence` → `sourceEvidenceRef` → else P0
- Any behavior cited in page docs but absent from the pinned source evidence is flagged as unsupported inference → else P0

When `sourceType` is `none`, skip these provenance-specific P0 checks.

### Step 4: Integration check (main agent)

After both subagents complete, cross-check:
- Every API dependency in frontend page docs exists in backend api.md → else P0
- Field names and types match between frontend state shapes and backend response schemas → else P0
- Error codes referenced in frontend exception handling exist in backend error code list → else P1

### Step 5: Write or update review-design.md

**First run**: create with all findings unchecked.
**Subsequent runs**: keep `[x]` items, only re-evaluate `[ ]` items.

```markdown
# Design Review: <change-name>

## Verdict: PASS | FAIL

## P0 Issues (must fix before implementation)
- [x] <resolved>
- [ ] <unresolved>

## P1 Issues (should fix)
- [ ] <issue>
```

Verdict is **PASS** only when all P0 items are `[x]`.

### Step 6: Generate tasks.md (on PASS only)

Build task list from design docs. **Task granularity = one page component or one backend capability.**

**Frontend task rules**:
- One task per page (e.g. ProjectListPage, UploadPage)
- Complex reusable components shared across 2+ pages → separate task
- User action points from page design doc → acceptance criteria (not separate tasks)
- In source-backed mode, each frontend task must carry the page's `pageId`, `sourceRef`, `pinnedRevision`, and relevant `interactionId` list into acceptance criteria or task metadata

**Backend task rules**:
- One task per logical API group (e.g. "项目管理接口", "结果管理接口")
- One task per scheduler/async job
- DB schema changes → separate task, must be first dependency

Order by dependency (topological sort). Frontend tasks depend on their backend API tasks.

```markdown
# Tasks: <change-name>

## DB Tasks
### Task-D<N>: <name>
Type: db
Implements: <FP-IDs from requirements.md, e.g. FP-3>
Depends on: none
Design doc: openspec/changes/<change>/design/backend/data-model.md#<section>
Acceptance:
- [ ] <criterion>

## Backend Tasks
### Task-B<N>: <name>
Type: backend
Implements: <FP-IDs from requirements.md>
Depends on: <Task-IDs or "none">
Design doc: openspec/changes/<change>/design/backend/api.md#<section>
Acceptance:
- [ ] <API endpoint works correctly>
- [ ] <error case handled>

## Frontend Tasks
### Task-F<N>: <PageName>
Type: frontend
Implements: <FP-IDs from requirements.md>
Depends on: <Task-B-IDs>
Design doc: openspec/changes/<change>/design/frontend/page-<name>.md
pageId: <pageId or "n/a">
sourceRef: <sourceRef or "n/a">
pinnedRevision: <kind>: <value>
interactionId: <interactionId list or "n/a">
Acceptance:
- [ ] <action point 1> → <expected result>
- [ ] <action point 2> → <expected result>
- [ ] <exception case> → <expected handling>
```

For `sourceType: none`, `pageId`, `sourceRef`, `pinnedRevision`, and `interactionId` may be `n/a` without blocking PASS.

### Step 7: Gate and review loop

**If FAIL**: report P0 issues to main agent. Main agent dispatches `apl:design` subagent with P0 issues as fix instructions, then re-dispatches this review. Loop until PASS or 5 iterations.

**If PASS**: generate tasks.md, then report PASS. Main agent informs user: "Design approved. Run `apl implement <change>` to proceed."

## Guardrails

- Never generate tasks.md before PASS
- Always load openspec/conventions/api.md and frontend.md before any conformance check — never search source code directly
- Always run convention conformance check before integration check
- In source-backed mode, never pass frontend design with missing provenance metadata, missing `interactionId` linkage, or behavior not anchored to the pinned revision
- When `sourceType` is `none`, preserve the existing review bar and do not add provenance-only blockers
- **Flag any API path or HTTP method that doesn't match openspec/conventions/api.md as P0**
- Always run integration check after both reviewers complete
- Always write `## Verdict: PASS` or `## Verdict: FAIL` as exact text
