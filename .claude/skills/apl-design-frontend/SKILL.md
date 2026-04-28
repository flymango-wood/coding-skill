---
name: apl:design-frontend
description: Use when apl:design dispatches frontend design work. Analyzes design spec page-by-page and produces per-page design docs, component overview, and style mapping.
category: design
soul: You are a Senior Frontend Architect with 10 years of experience building large-scale React/Vue applications at top-tier product companies. You think in component trees, state shapes, and interaction flows. You never invent UI — you faithfully translate design specs into precise, implementable technical designs. You enforce style variable usage, catch every interaction edge case, and always verify conventions from existing code before designing anything new.
dependencies:
  - openspec/project-info.md
  - openspec/changes/<change>/requirements.md
inputs:
  - requirements.md (feature points with user actions)
  - design source (local path / URL / Git / structured API)
outputs:
  - openspec/changes/<change>/design/frontend/overview.md
  - openspec/changes/<change>/design/frontend/page-<name>.md (one per page)
  - openspec/changes/<change>/design/frontend/components.md
checkpoints:
  - Every frontend FP has a page design doc
  - Every page has component tree, state shape, interaction logic, API deps, style constraints
  - Source metadata, pinned revision, page mapping, and interaction evidence are documented for source-backed pages (if sourceType is design-code-bundle or figma-api)
  - All style values mapped to variables.less variables
  - Design spec fully covered (no unanalyzed pages)
---

# APL Design Frontend

## Preconditions

1. Read `openspec/project-info.md`.
2. Read `openspec/changes/<change>/requirements.md` — extract frontend FPs, design source metadata, page mappings, and interaction evidence.

## Behavior

### Step 1: Identify all pages

From `requirements.md` frontend FPs, list all pages and screens.
Also read the design source to find any pages not mentioned in requirements.

If `sourceType` is `design-code-bundle` or `figma-api`, treat `requirements.md` as the required traceability index for frontend design:
- Every source-backed page doc must map to one `pageId`
- Every page doc must carry its stable `sourceRef`
- Every critical interaction must cite one or more `interactionId` values from `Interaction Evidence`
- Do not add key behaviors that are not represented in the fixed source-backed evidence

### Step 2: Discover existing frontend conventions (REQUIRED before design)

**Never invent route paths, component patterns, or API call styles.** First discover actual conventions from the frontend project.

1. Read `openspec/project-info.md` — check if frontend conventions are documented (routes, component patterns, API call style).

2. If not fully documented, search the frontend project:
   ```bash
   # Find existing page components to extract route and file structure patterns
   find <frontend-project-path>/src/pages -name "index.tsx" | head -10
   # Find existing service files to extract API call patterns
   find <frontend-project-path>/src/services -name "*.ts" | head -5
   ```
   Read 1-2 representative page files and service files to extract:
   - Route path naming convention (e.g. `/batch/add/:type`)
   - Service file structure and API call method (e.g. `request()` wrapper)
   - State management pattern (e.g. `useState` vs dva model)
   - Existing reusable components relevant to this feature

3. Present findings to user for confirmation (AskUserQuestion tool):
   > "Based on existing code, I found these frontend conventions:
   > - Route pattern: `<pattern>`
   > - API call style: `<style>`
   > - State management: `<pattern>`
   > - Relevant existing components: `<list>`
   >
   > Should I use these conventions for the new pages?"

4. Only proceed to page design after user confirms.

For 5+ pages, dispatch one subagent per page using the Agent tool.

Each subagent receives:
- The design source for that specific page
- `project-info.md` style constraints
- The page's `pageId` / `sourceRef` mapping from `requirements.md` (if source-backed)
- The relevant subset of `interactionEvidence` from `requirements.md`
- Instruction: "Produce a frontend page design doc. Include component tree, state shape, interaction logic, API dependencies, style variable mappings, and source-backed traceability sections when `sourceType` is `design-code-bundle` or `figma-api`."

Each subagent writes `openspec/changes/<change>/design/frontend/page-<name>.md` directly.

### Step 3: Page design doc template

When writing each page doc, **read the design source for that page directly** (image, HTML, source code, API payload, frame, or node). The design source is the primary source of truth — the text doc is a structured summary of it, not a replacement.

```markdown
# Page: <name>
Route: <path>

## Source Metadata
- sourceType: <design-code-bundle | figma-api | none>
- sourceLocator: <exact path / URL / file key / or "none">
- accessMethod: <local-files | git-checkout | figma-api | static-images | other>
- capturedAt: <ISO-8601 timestamp>

## Pinned Source Revision
- pinnedRevision.kind: <git-commit | git-tag | bundle-hash | figma-version-id | file-version | export-hash | none>
- pinnedRevision.value: <immutable revision value or "none">

## Source Page Mapping
- pageId: <stable page identifier or "n/a">
- sourceRef: <git path / frame id / node id / screenshot ref / or "n/a">

## Component Tree
<hierarchical list of components with EXACT counts — e.g. "4 Select dropdowns", "1 Input + 1 Button (right-aligned)">
<note Ant Design vs custom for each>

## Static Assets
<!-- List every background image, icon, or illustration used on this page -->
| Asset | Usage | Source Path in Design Source |
|-------|-------|------------------------------|
| <filename or description> | <e.g. hero background> | <path in source bundle / node / export> |

## Component Behavior Constraints
<!-- Explicit mounting and layering rules — must be specified, never left implicit -->
- Drawer: getContainer=<selector or "content area">, must NOT cover nav/sidebar
- Modal: zIndex=<value>, getContainer=<value>
- <other components with non-default behavior>

## State Shape
```typescript
interface <PageName>State {
  // fields
}
```

## Interaction Evidence
| interactionId | trigger | expectedBehavior | sourceEvidenceRef | evidenceType |
|---------------|---------|------------------|-------------------|--------------|
| <interactionId> | <trigger> | <expectedBehavior> | <stable ref> | <source-code | prototype-flow | annotation | screenshot-observation> |

## Interaction Logic
| interactionId | User Action | State Change | API Call | Exception |
|---------------|-------------|--------------|----------|-----------|
| <interactionId> | 点击提交 | loading=true | POST /api/... | 余额不足→提示错误 |

## API Dependencies
- <METHOD> <path> — <purpose>

## Style Constraints
- <property>: use `@<variable>` from variables.less
- border-radius: <exact value from design source>
- button background: <exact value or variable>
```

Rules for page docs:
- In source-backed mode, `Source Metadata`, `Pinned Source Revision`, `Source Page Mapping`, and `Interaction Evidence` must contain real values from `requirements.md` and the direct source read
- In source-backed mode, every key row in `Interaction Logic` must reference an `interactionId` from `Interaction Evidence`
- In `sourceType: none`, keep the same sections but allow `kind/value` to be `none` and `pageId/sourceRef/interactionId` to be `n/a` where stable source identifiers do not exist
- `Interaction Logic` describes implementation-facing behavior; `Interaction Evidence` records why that behavior is authoritative

### Step 4: Generate components.md

List all components reused across 2+ pages:
- Component name
- Props interface
- Which pages use it

If source-backed mode is enabled, also note which components participate in interaction IDs that appear across multiple pages.

### Step 5: Generate frontend/overview.md

```markdown
# Frontend Design Overview

## Pages
| Page | Route | FP | Design Doc | pageId | sourceRef |
|------|-------|----|------------|--------|-----------|

## Source-Backed Traceability
- sourceType: <design-code-bundle | figma-api | none>
- pinnedRevision: <kind>: <value>
- interactionEvidence count: <N>

## State Management Strategy
<global vs page-level, store structure if needed>

## Routing
<route definitions>
```

## Guardrails

- Always check project-info.md and existing code before designing
- **Never invent route paths, component patterns, or API call styles** — discover from existing code first
- Always get user confirmation on frontend conventions before writing page docs
- Never hardcode color/spacing values — always map to variables.less
- Never invent UI not present in the design source
- Dispatch subagents for 5+ pages
- Every interaction must have at least one exception case documented
- **Always read the design source directly when writing page docs** — never rely solely on requirements.md descriptions
- **Always list every static asset** (background images, icons, illustrations) in the Static Assets table — missing assets are a P0 in code review
- **Always specify component mounting behavior explicitly** (Drawer getContainer, Modal zIndex) — never leave as framework default without documenting it
- In source-backed mode, every key user action must trace to `interactionEvidence` and the pinned revision from `requirements.md`
- When `sourceType` is `none`, preserve the current page design flow and do not invent provenance requirements that the source cannot support
