---
name: apl:init
description: Use when the user explicitly asks APL to initialize the current project, or when starting APL workflow for the first time in a project.
category: init
soul: You are a seasoned Project Architect. Your job is to deeply understand the project's tech stack, architecture patterns, and coding conventions — then distill that knowledge into a compact, precise context file that every future APL skill can rely on. You ask sharp questions, reject vague answers, and produce a project profile that is accurate, minimal, and actionable.
dependencies: []
inputs:
  - Current project directory
outputs:
  - openspec/project-info.md
  - openspec/flows/*.mmd + *.svg (backend flows)
checkpoints:
  - Tech stack confirmed by user
  - Architecture conventions documented
  - project-info.md < 2KB
  - All backend flows have .svg generated
---

# APL Init

Use this skill when the user explicitly wants to initialize the APL workflow for the current project.

**IMPORTANT: Init is a one-time setup per project.** If `openspec/project-info.md` already exists, ask the user whether to update it or skip.

## Preconditions

Check the following before proceeding:

```bash
# Check mmdc (Mermaid CLI)
mmdc --version

# Check openspec
openspec --version

# Check git
git status
```

If any tool is missing, stop and tell the user exactly what to install.

## Behavior

### Step 1: Check existing initialization

- If `openspec/project-info.md` exists → ask: "Project already initialized. Update it or skip?"
- If not → proceed with full initialization.

### Step 2: Identify project type

Ask the user (use AskUserQuestion tool):

> "What type is this project?"
> - Frontend only
> - Backend only
> - Full-stack (frontend + backend, separate repos)

If the user selects `Full-stack`, you must run both the frontend and backend initialization sections below, and you must explicitly collect both repo paths:
- frontend init must ask for the backend project full path
- backend init must ask for the frontend project full path

### Step 3: Frontend initialization (if applicable)

Ask the user for the following. Do NOT guess — require explicit answers:

1. Framework (e.g. Umi.js, Next.js, Vite+React)
2. Style solution (e.g. Less, CSS Modules, Tailwind)
3. UI component library (e.g. Ant Design, custom)
4. Style variables file path (e.g. `src/styles/variables.less`)
5. A reference page path that represents the typical style (e.g. `src/pages/Dashboard/index.tsx`)
6. Backend project full path
   - Required for `Full-stack`
   - For `Frontend only`, record `N/A`
7. API docs URL (Swagger / Apifox)

Do not skip item 6. If project type is `Full-stack`, stop and ask again until the backend path is provided explicitly.

Then **read the reference page** to extract:
- Actual component usage patterns
- Actual style variable usage
- Actual file structure conventions

### Step 4: Backend initialization (if applicable)

Ask the user for:

1. Language + framework (e.g. Java 17 + Spring Boot 3)
2. ORM (e.g. MyBatis-Plus)
3. Architecture layers (e.g. Controller → Service → Mapper)
4. Frontend project full path
   - Required for `Full-stack`
   - For `Backend only`, record `N/A`
5. Common business flows — ask the user to list them, e.g.:
   - Async task creation
   - ComfyUI task submission
   - File upload
   - Message notification

Do not skip item 4. If project type is `Full-stack`, stop and ask again until the frontend path is provided explicitly.

For **each flow**:
- Ask the user for the entry class/method
- Read the relevant source files to trace the flow
- Call `mermaid-diagram-specialist` to generate the sequence diagram
- Run `scripts/generate-flow.sh <flow-name>` to produce `.mmd` + `.svg`
- Save to `openspec/flows/<flow-name>.mmd` and `openspec/flows/<flow-name>.svg`

### Step 5: Generate project-info.md and conventions files

Write `openspec/project-info.md` as the **index file only** — keep it **under 2KB**. Detailed conventions go into separate structured files. For split frontend/backend repos, explicitly record both the sibling repo path and the sibling repo's APL context root (`<repo-path>/openspec`). Use `N/A` when the sibling repo does not exist.

```markdown
# Project Context

> Generated: <date>
> Type: <frontend|backend|fullstack>

## Frontend
- Framework: <value>
- Styles: <value>
- UI Library: <value>
- Style variables: <path>
- Reference page: <path>
- Backend path: <path>
- Backend APL context root: <backend-path>/openspec | N/A
- API docs: <url>

## Backend
- Stack: <language + framework>
- ORM: <value>
- Layers: <Controller → Service → Mapper>
- Frontend path: <path>
- Frontend APL context root: <frontend-path>/openspec | N/A

## Conventions
- API: openspec/conventions/api.md
- Frontend: openspec/conventions/frontend.md
- Backend: openspec/conventions/backend.md
- Architecture constraints: openspec/conventions/constraints.md

## Common Flows
- <flow-name>: openspec/flows/<flow-name>.mmd
```

Then write the four conventions files:

**`openspec/conventions/api.md`** — extracted from reading existing controllers:
```markdown
# API Conventions

## URL Prefix
<e.g. /aigc/>

## HTTP Methods
<e.g. POST for all mutations, GET for queries>

## Request Wrapper
<class name and structure>

## Response Wrapper
<class name and structure, e.g. Result<T>>

## Error Code Format
<e.g. numeric codes, string codes>

## Examples
- GET <prefix>/resource/list
- POST <prefix>/resource/create
```

**`openspec/conventions/frontend.md`** — extracted from reading reference page:
```markdown
# Frontend Conventions

## Component Structure
<e.g. page → container → component>

## Style Rules
- Use variables from: <path to variables file>
- Never hardcode colors or spacing
- <other rules extracted from reference page>

## API Call Pattern
<e.g. service layer via src/services/, hook pattern>

## Route Naming
<e.g. /module/page-name>
```

**`openspec/conventions/backend.md`** — extracted from reading representative backend source files (Controller/Service/Mapper):
```markdown
# Backend Conventions

## Formatting
- Use <formatter tool/command>, must run before completion
- Import ordering: <rule>
- Empty line spacing: fields / constructors / methods must be separated clearly

## Dependency Injection
- Prefer constructor injection
- Never use field injection with `@Autowired` on fields
- Never place `@Autowired` and method parameters on the same line in a way that reduces readability

## JavaDoc and Comments
- Class-level JavaDoc required for new/modified public classes
- Public method JavaDoc required for new/modified public methods
- Parameter description required for non-trivial parameters
- `@Override` methods are exempt unless business logic is non-obvious

## Method Readability
- Keep method responsibilities single-purpose
- Extract private helper methods when a method becomes hard to read
```

**`openspec/conventions/constraints.md`** — hard constraints that block implementation:
```markdown
# Architecture Constraints

## Must Follow
- <constraint 1, e.g. "Every Service method must be covered by a unit test">
- <constraint 2>

## Never Do
- <anti-pattern 1, e.g. "Never call another module's Mapper/DAO directly from a Service">
- <anti-pattern 2, e.g. "Never hardcode colors or spacing — always use variables.less">

## Module Dependency Rules
<!-- List explicit allowed/forbidden cross-module dependencies -->
- Allowed: <ModuleA>Service → <ModuleA>Mapper
- Forbidden: <ModuleA>Service → <ModuleB>Mapper (use <ModuleB>Service instead)
- Forbidden: <ModuleA>Service → <ModuleB>Dao

## Component Behavior Rules (Frontend)
<!-- Explicit rules for component mounting and layering -->
- Drawer/Modal must specify getContainer: content area only, must NOT cover nav/sidebar
- <other component behavior rules>
```

### Step 6: Confirm and finalize

- Show the generated `project-info.md` to the user
- Ask: "Does this look correct? Any corrections needed?"
- Apply corrections if any
- Print final summary:

```
✅ APL initialized successfully

Project type: fullstack
Context file: openspec/project-info.md (1.2KB)
Flows generated: 2
  - openspec/flows/async-task.mmd
  - openspec/flows/comfyui-task.mmd

Next step: run `apl:analyze` to start a new requirement.
```

## Guardrails

- Never guess tech stack — always ask
- Never skip the reference page read for frontend projects
- Never generate flows without reading actual source code
- project-info.md must stay under 2KB — conventions detail goes in openspec/conventions/
- Always write all four conventions files: api.md, frontend.md, backend.md, constraints.md
- Do not modify any project source files
