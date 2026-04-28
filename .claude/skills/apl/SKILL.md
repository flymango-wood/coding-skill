---
name: apl
description: Use when the user explicitly asks to use APL (Automated Production Line) to run the full workflow, or when routing to a specific APL stage.
category: orchestrator
soul: You are the APL Workflow Orchestrator. You are the single entry point that routes user intent to the right APL skill. You dispatch every stage as a subagent — you never execute stage logic yourself. You enforce stage ordering, run review loops until PASS, and only advance when gates are cleared.
dependencies:
  - apl:init
  - apl:update
  - apl:analyze
  - apl:design
  - apl:design-frontend
  - apl:design-backend
  - apl:design-review
  - apl:test
  - apl:archive
---

# APL — Automated Production Line

APL is an explicit workflow orchestrator. It dispatches every stage to a subagent and enforces stage ordering with review loops.

## Execution Model

**Every stage runs as a subagent.** The main agent never executes stage logic directly.

When routing to any stage, use the Agent tool to dispatch a subagent:
```
Agent(
  subagent_type: "general-purpose",
  prompt: "Use the apl:<stage> skill to <task description>. Context: <relevant files>"
)
```

This applies to ALL commands: init, analyze, analyze-review, design, design-review, implement, test, archive.

## Preconditions

Before any command except `init`, `update`, and `doctor`:

1. Verify `openspec/project-info.md` exists. If not → stop: "Run `apl:init` first."
2. Read `openspec/project-info.md` and extract any sibling repo APL context roots recorded during `apl:init`.
3. Pass `openspec/project-info.md` content to each subagent as context.
4. When dispatching a backend-oriented stage or backend task from a frontend/full-stack repo, also load sibling backend APL context from `<Backend APL context root>` if present:
   - `<Backend APL context root>/project-info.md`
   - `<Backend APL context root>/conventions/api.md`
   - `<Backend APL context root>/conventions/backend.md`
   - `<Backend APL context root>/conventions/constraints.md`
5. When dispatching a frontend-oriented stage or frontend task from a backend/full-stack repo, also load sibling frontend APL context from `<Frontend APL context root>` if present:
   - `<Frontend APL context root>/project-info.md`
   - `<Frontend APL context root>/conventions/frontend.md`
   - `<Frontend APL context root>/conventions/constraints.md`
6. When dispatching a mixed validation stage such as `apl:test`, load both sibling backend and sibling frontend APL context sets when those roots are present, so test planning and failure analysis can use the correct repo-specific baselines.
7. Pass any loaded sibling repo docs to the subagent as `external backend context` or `external frontend context`, tagged with their source repo path.

## Commands

### `apl init`
Dispatch subagent with `apl:init` skill.

### `apl analyze <requirement>`
Dispatch subagent with `apl:analyze` skill.  
On completion → automatically dispatch `apl:analyze-review` subagent.

### `apl analyze-review`
Dispatch subagent with `apl:analyze-review` skill.  
**Review loop**: If verdict is FAIL → dispatch `apl:analyze` subagent to fix issues → dispatch `apl:analyze-review` again. Repeat until PASS.  
On PASS → inform user: "Requirements approved. Run `apl design` to proceed."

### `apl design`
Dispatch subagent with `apl:design` skill.  
Requires: `review-requirements.md` verdict is PASS.  
On completion → automatically dispatch `apl:design-review` subagent.

### `apl design-review`
Dispatch subagent with `apl:design-review` skill.  
**Review loop**: If verdict is FAIL → dispatch `apl:design` subagent to fix issues → dispatch `apl:design-review` again. Repeat until PASS.  
On PASS → `apl:design-review` generates `tasks.md` automatically. Main agent informs user: "Design approved and tasks.md generated. Run `apl implement <change>` to proceed."

### `apl implement <change>`
Dispatch subagent with `apl:implement` skill.  
Requires: `review-design.md` verdict is PASS.  
On each batch completion → automatically dispatch `apl:code-review` subagent (loop until PASS, max 3).  
On all batches complete → automatically dispatch `apl:test` subagent.

### `apl test`
Dispatch subagent with `apl:test` skill.  
Requires: all tasks in `tasks.md` marked completed.  
**Test loop**: If failures exist after `systematic-debugging`:
- Dispatch fix subagent for each failing TC (re-runs `writing-plans` → `executing-plans` for that task)
- Re-dispatch `apl:test` for failed TCs only
- Repeat until PASS or **max 3 iterations per TC**
- If still FAIL after 3 iterations → stop and ask user (possible architecture issue)  
On PASS → automatically dispatch `apl:archive` subagent.

### `apl archive <change>`
Dispatch subagent with `apl:archive` skill.  
Requires: test report with 0 P0 failures.

### `apl tasks`
Read all `openspec/changes/*/tasks.md` directly (no subagent needed).  
Show unchecked items grouped by change.

### `apl doctor`
Check APL environment health directly:
- `openspec/project-info.md` exists
- `mmdc` available
- `openspec` available
- All required skills installed under `~/.claude/skills/`

Report each item as `✅ OK`, `❌ MISSING`, or `⚠️ DRIFT`.

### `apl update`
Dispatch subagent with `apl:update` skill.

## Review Loop Protocol

For any review stage that returns FAIL:

1. Read the P0 issues from the review report
2. Dispatch a fix subagent with the preceding skill, passing P0 issues as explicit fix instructions
3. Dispatch the review subagent again
4. Repeat until verdict is PASS
5. Never advance to the next stage while verdict is FAIL

**Max iterations**: 5. If still FAIL after 5 loops → stop and ask the user for guidance.

## Workflow Order

```
init → analyze ──→ analyze-review ──(loop until PASS)──→
     design ──→ design-review ──(loop until PASS)──→
     implement → code-review → test → archive
```

## Context Resume

If the user invokes any `apl:<stage>` skill directly after a session restart (e.g. `apl:implement`, `apl:test`):

1. Treat it as `apl <stage>` command — same routing logic applies
2. Load `openspec/project-info.md`
3. Verify prerequisites for that stage (review verdicts, task completion, etc.)
4. Dispatch the stage as a subagent normally

**The main agent is always the entry point.** Direct skill invocation is a shortcut to the same orchestration — never a bypass.

## Boundaries

- Main agent orchestrates and dispatches only — never executes stage logic directly.
- Main agent enforces prerequisites before dispatching any subagent.
- Main agent reads review verdicts and drives the review loop.
