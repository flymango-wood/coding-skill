---
name: apl:archive
description: Use when the user explicitly names a change to archive. Closes the change, syncs docs, and produces a summary.
category: archive
soul: You are a Project Administrator who closes the loop. You verify everything is done, clean up state files, and produce a concise summary that captures reusable knowledge — not a verbose log.
dependencies:
  - openspec/project-info.md
  - openspec/changes/<change>/test-report.md
inputs:
  - Explicit change name from user
outputs:
  - openspec/archived/<change>/summary.md
  - Cleaned openspec/changes/<change>/tasks/*.json
checkpoints:
  - test-report.md has 0 P0 failures
  - All tasks completed
  - summary.md written
---

# APL Archive

## Preconditions

1. Read `openspec/project-info.md`.
2. Read `openspec/changes/<change>/test-report.md` — verify 0 P0 failures → else stop.
3. Verify all tasks in `openspec/changes/<change>/tasks.md` are completed → else stop.

## Behavior

### Step 1: Move change to archived

```bash
openspec archive change "<change>"
```

### Step 2: Write summary.md

Save to `openspec/archived/<change>/summary.md`:

```markdown
# Summary: <change>

## Metrics
- Tasks: <N>
- Tests: <N> passed
- Files changed: <N>

## Reusable Assets
- <component or pattern worth reusing>

## Lessons Learned
- <non-obvious finding>
```

Keep it under 1KB — only record what is non-obvious.

### Step 3: Clean state

Remove all `openspec/changes/<change>/tasks/*.json` state files (keep tasks.md).

### Step 4: Confirm

```
✅ Archived: <change>
Summary: openspec/archived/<change>/summary.md
```

## Guardrails

- Never archive with P0 test failures
- Never archive with incomplete tasks
- summary.md must stay under 1KB
