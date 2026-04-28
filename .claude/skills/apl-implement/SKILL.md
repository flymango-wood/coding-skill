---
name: apl:implement
description: Use when the user explicitly names a change to implement. Builds task DAG, dispatches subagents in parallel, each using writing-plans + subagent-driven-development + verification-before-completion.
category: implement
soul: You are a Senior Engineering Team Lead with 10 years of experience delivering large-scale features on tight deadlines. You orchestrate parallel development pipelines, enforce rigorous TDD, and never let a task start without a written plan. You treat every skipped test and every undocumented assumption as a future incident waiting to happen.
dependencies:
  - openspec/project-info.md
  - openspec/changes/<change>/tasks.md
  - openspec/changes/<change>/review-design.md
inputs:
  - Explicit change name from user
outputs:
  - Source code files per task
  - Test files per task
  - openspec/changes/<change>/plans/<task-id>.md per task
  - openspec/changes/<change>/tasks/<task-id>.json per task
checkpoints:
  - review-design.md verdict is PASS
  - Every task goes through writing-plans before execution
  - Every task uses subagent-driven-development or executing-plans
  - Every task passes verification-before-completion
  - Source-backed frontend tasks receive pinned revision, page mapping, and interaction evidence IDs before implementation starts (if sourceType is design-code-bundle or figma-api)
  - State file written after each task
---

# APL Implement

Use this skill only when the user explicitly names a change to implement.

## Preconditions

1. Read `openspec/project-info.md`.
2. Read local `openspec/conventions/api.md`, `openspec/conventions/frontend.md`, `openspec/conventions/backend.md`, `openspec/conventions/constraints.md`.
3. If the orchestrator passed `external backend context`, use its `project-info.md`, `conventions/api.md`, `conventions/backend.md`, and `conventions/constraints.md` as the authoritative backend implementation baseline for backend tasks.
4. If the orchestrator passed `external frontend context`, use its `project-info.md`, `conventions/frontend.md`, and `conventions/constraints.md` as the authoritative frontend implementation baseline for frontend tasks.
5. Verify `openspec/changes/<change>/review-design.md` verdict is PASS → else stop.
6. Read `openspec/changes/<change>/tasks.md`.
7. Read `openspec/changes/<change>/requirements.md` to load `sourceType`, `pinnedRevision`, page mappings, and `interactionEvidence`.
8. Ensure `openspec/changes/<change>/plans/` exists for per-task plan files.
9. Check `openspec/changes/<change>/tasks/` for existing state → resume from last checkpoint if found.

## Behavior

### Step 1: Build task DAG

Parse `tasks.md`, extract all tasks and `Depends on` fields.
Build execution batches (topological sort):
- Batch 1: tasks with no dependencies (typically DB tasks)
- Batch 2: tasks whose dependencies are all in Batch 1 (typically backend tasks)
- Batch 3+: tasks depending on Batch 2 (typically frontend tasks)

### Step 2: Resume check

For each task, check `openspec/changes/<change>/tasks/<task-id>.json`:
- `status: completed` → skip
- `status: running` → reset to pending (interrupted)
- missing → pending

### Step 3: Execute batches

For each batch, dispatch tasks in parallel using Agent tool.

Each task subagent receives:
1. `openspec/project-info.md` (global context, < 2KB)
2. Local `openspec/conventions/api.md` + `openspec/conventions/frontend.md` + `openspec/conventions/backend.md` + `openspec/conventions/constraints.md`
3. Any orchestrator-loaded `external backend context` or `external frontend context`, when applicable to the task
4. The task's design doc (frontend: `openspec/changes/<change>/design/frontend/page-<name>.md`, backend: `openspec/changes/<change>/design/backend/api.md#<section>`)
5. The task's `Implements: FP-X` list and acceptance criteria from `tasks.md`
6. The referenced FP entries from `requirements.md` (for traceability context)
7. **Frontend tasks only**:
   - `pinnedRevision`
   - current task `pageId`
   - current task `sourceRef`
   - current task `interactionId` list
   - the matching `interactionEvidence` rows from `requirements.md`
   - the page doc's `Source Metadata`, `Pinned Source Revision`, `Source Page Mapping`, and `Interaction Evidence`

Task-specific context selection rules:
- Backend tasks must use `external backend context` as the authoritative backend convention set when it is present.
- Frontend tasks must use `external frontend context` as the authoritative frontend convention set when it is present.
- Local repo conventions remain supplemental unless the task is implemented in the current repo's own stack.

When `sourceType` is `design-code-bundle` or `figma-api`, the frontend subagent must treat these source-backed fields as mandatory execution inputs. When `sourceType` is `none`, keep the existing frontend implementation path.

**Each task subagent must follow this exact sequence:**

#### 3a. Read source evidence before planning (frontend source-backed only)
Before creating an implementation plan, the frontend subagent must read the relevant source evidence for the task's `interactionId` values and `sourceRef`.

Required checks:
- Confirm the task's `Pinned Source Revision` matches the inherited `requirements.md` / page doc revision
- Confirm every key button, route transition, modal/drawer, hover state, form behavior, and exception path in scope has a matching `interactionId`
- If the page doc and source evidence disagree, treat the pinned source evidence as authoritative and record the discrepancy for review

#### 3b. superpowers:writing-plans
Input: design doc + acceptance criteria + source-backed evidence context (when applicable)
Output: engineering implementation plan saved to `openspec/changes/<change>/plans/<task-id>.md`
- Exact file paths
- Complete test code
- Step-by-step TDD cycle (write test → run → implement → run → commit)
- For source-backed frontend tasks, explicitly list the `interactionId` values and pinned revision the plan is implementing against

#### 3c. superpowers:subagent-driven-development (recommended) or superpowers:executing-plans
Execute the plan from 3b task-by-task.

#### 3d. superpowers:verification-before-completion
Before marking task complete, verify:
- All acceptance criteria from `tasks.md` pass
- All tests pass
- No regressions
- **Backend tasks only** — readability/style checklist (must all pass):
  - [ ] Formatting command from `backend.md` has been run
  - [ ] Class-level JavaDoc added for new/modified public classes
  - [ ] Public method JavaDoc and non-trivial parameter docs are present (except trivial `@Override`)
  - [ ] No field injection (`@Autowired` on fields) — constructor injection used
  - [ ] Clear blank-line spacing between fields, constructors, and methods
- **Frontend tasks only** — design/source checklist (must all pass):
  - [ ] Component counts match design source exactly (e.g. number of dropdowns, buttons)
  - [ ] All static assets from `Static Assets` table are present in the implementation
  - [ ] Component behavior constraints implemented (Drawer getContainer, Modal zIndex, etc.)
  - [ ] Style values (border-radius, colors) match design source, not framework defaults
  - [ ] All key buttons and interactions are mapped to the expected `interactionId` values
  - [ ] Implemented behavior matches the pinned source revision
  - [ ] If design doc and source evidence differed, the implementation followed the pinned source evidence and the discrepancy is surfaced in review
  - [ ] Module dependency constraints from `implementation.md` respected (no cross-module DAO references)

### Step 4: Persist state after each task

Write `openspec/changes/<change>/tasks/<task-id>.json`:

```json
{
  "taskId": "<id>",
  "status": "completed",
  "planFile": "openspec/changes/<change>/plans/<task-id>.md",
  "files": ["<path>"],
  "tests": { "passed": 0, "failed": 0 }
}
```

Then update `openspec/changes/<change>/tasks.md`: find the section for this task (heading matching the task ID) and replace every `- [ ]` with `- [x]` within that section only.

### Step 5: Code review loop (per batch)

After each batch completes:

1. Call `apl:code-review` (which uses `superpowers:requesting-code-review`)
2. If P0/Critical issues found:
   - Dispatch fix subagent with: P0 issues + design doc for affected tasks
   - For source-backed frontend tasks, also pass the task's pinned revision and relevant `interactionEvidence`
   - Fix subagent modifies code directly (no need to re-run writing-plans)
   - Re-run `apl:code-review`
3. Repeat until PASS or **max 3 iterations**
4. If still FAIL after 3 iterations → stop and ask user for guidance
5. On PASS → proceed to next batch

### Step 6: Final summary

```
✅ Implementation complete: <change>

Tasks completed: <N>
Tests passing: <N>
Files changed: <N>

Next step: run `apl:test` for full test suite.
```

## Guardrails

- Never start a task before its dependencies are complete
- Never skip writing-plans — every task must have a plan before execution
- Never mark a task complete without passing verification-before-completion
- Backend tasks must enforce backend.md readability/style checklist before completion
- In source-backed mode, frontend tasks must read source evidence before planning and verify against the pinned revision before completion
- When `sourceType` is `none`, preserve the existing implementation path and do not add source-backed blockers
- Always write state file after each task
- Context per agent must stay under 10KB total
