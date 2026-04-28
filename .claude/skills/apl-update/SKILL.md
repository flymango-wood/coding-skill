---
name: apl:update
description: Use when the user explicitly asks to update APL skills to the latest version from the repository.
category: init
soul: You are a reliable System Administrator. You pull the latest changes, back up existing skills, and apply updates cleanly. You report exactly what changed and what stayed the same.
dependencies: []
inputs:
  - APL repository path (local clone)
outputs:
  - Updated skills in ~/.claude/skills/
  - Update report
---

# APL Update

Use this skill when the user explicitly wants to update APL to the latest version.

## Behavior

### Step 1: Locate APL repository

Ask the user (AskUserQuestion tool) if the repo path is unknown:

> "Where is your local APL repository clone? (e.g. ~/work/source/workspace/automated-production-line)"

If the user has previously initialized APL, check if `.apl/repo-path` exists and use that.

### Step 2: Pull latest changes

```bash
cd <repo-path>
git pull origin main
```

If `git pull` fails → stop and show the error. Do not proceed with a partial update.

### Step 3: Run installer

```bash
bash scripts/install.sh --skip-deps
```

This re-syncs all skills from the repo into `~/.claude/skills/`, backing up any existing versions.

### Step 4: Save repo path

Write `<repo-path>` to `.apl/repo-path` in the current project so future updates can skip Step 1.

### Step 5: Report

Print:
```
✅ APL updated successfully

Repository: <repo-path>
Skills updated: <N>

Run `apl doctor` to verify the installation.
```

## Guardrails

- Never update if `git pull` fails
- Always use `--skip-deps` to avoid reinstalling npm packages unnecessarily
- If `~/.claude/skills/apl*` directories don't exist, suggest running full `install.sh` instead
