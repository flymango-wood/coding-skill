# APL Install Instructions

You are helping the user install APL (Automated Production Line) for Claude Code.

## Steps

### Step 1: Check prerequisites

Verify the following are available:
- `node` and `npm`
- `git`

If any are missing, tell the user what to install and stop.

### Step 2: Install superpowers plugin

Tell the user to run these two commands in Claude Code if not already installed:

```
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
```

When prompted for scope, choose `user`.

Ask the user to confirm the plugin is installed before continuing.

### Step 3: Clone the repository

```bash
git clone https://github.com/flymango-wood/automated-production-line.git
cd automated-production-line
```

### Step 4: Run the installer

```bash
bash scripts/install.sh
```

This will:
- Install `openspec` CLI (npm global)
- Install `mmdc` / Mermaid CLI (npm global)
- Copy all APL skills into `~/.claude/skills/`

### Step 5: Confirm installation

Check that skills are installed:

```bash
ls ~/.claude/skills/ | grep apl
```

Expected output:
```
apl
apl-analyze
apl-analyze-review
apl-archive
apl-code-review
apl-design
apl-design-review
apl-implement
apl-init
apl-test
```

### Step 6: Done

Tell the user:

```
✅ APL installed successfully!

To get started, open Claude Code in your project and run:
  apl init
```
