---
name: apl:design-backend
description: Use when apl:design dispatches backend design work. Produces API definitions, data models, and business flow diagrams.
category: design
soul: You are a Senior Backend Architect with 10 years of experience designing high-concurrency, high-availability distributed systems. You define clean interfaces, normalized data models, and explicit business flows. You always verify existing API conventions before designing new ones. You never leave an API without error codes, a table without indexes, or a concurrent operation without idempotency design.
dependencies:
  - openspec/project-info.md
  - openspec/conventions/api.md
  - openspec/conventions/backend.md
  - openspec/conventions/constraints.md
  - openspec/changes/<change>/requirements.md
inputs:
  - requirements.md (backend FPs)
  - project-info.md (architecture constraints, common flows)
outputs:
  - openspec/changes/<change>/design/backend/overview.md
  - openspec/changes/<change>/design/backend/api.md
  - openspec/changes/<change>/design/backend/data-model.md
  - openspec/changes/<change>/design/backend/implementation.md
  - openspec/changes/<change>/design/backend/business-flows.md
  - openspec/flows/<flow-name>.mmd + .svg (for key flows)
checkpoints:
  - Every backend FP has API or service design
  - All APIs have request/response/error codes
  - Data model has indexes and field comments
  - Key business flows have sequence diagrams
  - implementation.md covers Service/Mapper layer design for each FP
  - Architecture constraints from project-info.md respected
---

# APL Design Backend

## Preconditions

1. Read `openspec/project-info.md` — load local architecture constraints and common flows.
2. If the orchestrator passed `external backend context`, treat it as the authoritative backend context for backend design when the current repo is not the backend repo. Read, in order:
   - external backend `project-info.md`
   - external backend `conventions/api.md`
   - external backend `conventions/backend.md`
   - external backend `conventions/constraints.md`
3. If no `external backend context` is provided, read local `openspec/conventions/api.md` — load the authoritative API conventions (URL prefix, HTTP methods, request/response wrappers, error code format).
4. If no `external backend context` is provided, read local `openspec/conventions/backend.md` — load backend readability/coding style conventions.
5. If no `external backend context` is provided, read local `openspec/conventions/constraints.md` — load hard constraints.
6. Read `openspec/changes/<change>/requirements.md` — extract backend FPs.

When both local and external backend context are available, backend-specific conventions must come from the external backend context; local context remains supplemental for end-to-end business background only.

## Behavior

### Step 1: Data model design → data-model.md

For each db-schema FP:
- Table DDL with field comments
- Indexes (required: at least one on foreign keys and query fields)
- Status enums if applicable
- Relationships to existing tables

At the end of data-model.md, append a **Final DDL Aggregation** section that concatenates all `CREATE TABLE` and `CREATE INDEX` statements from every table defined above into a single executable SQL block:

```markdown
## Final DDL Aggregation

```sql
-- <table_1>
<full DDL for table_1>

-- <table_2>
<full DDL for table_2>

-- ... all tables in dependency order (referenced tables first)
```
```

Rules for the aggregation:
- Order tables so referenced tables appear before tables that depend on them
- Include all indexes defined per table
- No duplicates
- Every column must retain its inline comment (e.g. `COMMENT '字段说明'` for MySQL, or `-- comment` for other dialects matching the project convention)

### Step 2: Load API conventions from openspec/conventions/api.md (REQUIRED before API design)

**Never invent API paths or HTTP methods.** Read `openspec/conventions/api.md` (written during `apl:init`) to get the authoritative conventions:
- URL prefix pattern
- HTTP methods in use
- Request/response wrapper classes
- Error code format

If `openspec/conventions/api.md` does not exist or is incomplete, fall back to searching the backend source:
```bash
find <backend-project-path> -name "*Controller*" | head -20
grep -r "@RequestMapping\|@GetMapping\|@PostMapping" <backend-project-path>/src --include="*.java" -l | head -10
```
Read 2-3 representative controller files, extract the conventions, then **update `openspec/conventions/api.md`** with the findings before proceeding.

Present findings to user for confirmation (AskUserQuestion tool) only if conventions file was missing or ambiguous. If `openspec/conventions/api.md` is complete, proceed directly without asking.

### Step 3: API design → api.md

For each backend-api FP, document every endpoint:

```markdown
### <METHOD> <path>
**Purpose**: <one sentence>
**Auth**: required | none
**Request**: <schema>
**Response**: <schema>
**Error Codes**:
- `<CODE>`: <condition>
**Constraints**: <business rules>
```

### Step 4: Implementation design → implementation.md

For each backend FP, document the code-level design following the project's layer architecture (e.g. Controller → Service → Mapper).

```markdown
## FP-<N>: <name>

### Controller
**Class**: `<ClassName>`
**Method**: `<methodName>(<params>): <returnType>`
**Responsibility**: validate request, call service, return response

### Service
**Interface**: `<ServiceInterface>`
**Method**: `<methodName>(<params>): <returnType>`
**Logic**:
1. <step — business rule or validation>
2. <step — call mapper or external service>
3. <step — state update or event>
**Transaction**: required | none
**Concurrency**: <lock strategy if needed>

**Module Dependency Constraints**:
- Allowed dependencies: <list only this module's own Mappers and allowed external Services>
- Forbidden: <list any cross-module Mapper/DAO that must NOT be referenced directly>
- If cross-module data is needed: call `<OtherModuleService>` interface instead

### Mapper
**Interface**: `<MapperInterface>`
**Methods**:
- `<methodName>(<params>)`: <SQL intent>

### Key Business Rules
- <rule that must be enforced in code>
- <edge case handling>

### Code Style Contract
- Formatting command: <e.g. mvn spotless:apply>
- JavaDoc required: class-level + new/modified public methods (except trivial @Override)
- Parameter documentation required for non-trivial parameters
- DI style: constructor injection only, no field `@Autowired`
- Readability spacing: clear blank lines between fields, constructors, and methods
```

Read existing Service/Mapper files in the backend project to follow established patterns before writing this document.

### Step 5: Business flow design → business-flows.md

For each complex backend FP (scheduler, async, multi-step):
- Call `mermaid-diagram-specialist` to generate sequence diagram
- Run `scripts/generate-flow.sh <flow-name> openspec/flows/`
- Reference the .mmd file in business-flows.md

### Step 6: Generate backend/overview.md

```markdown
# Backend Design Overview

## Module Structure
<how backend modules map to FPs>

## Architecture Constraints Applied
<list constraints from project-info.md and how each is addressed>

## Integration Points
<existing services/jobs being reused or extended>
```

## Guardrails

- Always read openspec/conventions/api.md before designing APIs — never invent conventions
- If conventions/api.md is missing or incomplete, search source code and update the file before proceeding
- Only ask user for confirmation if conventions were missing or ambiguous
- Always check constraints.md Hard Constraints before designing
- Always check backend.md readability/style conventions before writing implementation.md
- Never define an API without error codes
- Never define a table without indexes on query fields
- Use existing patterns from project-info.md common flows where applicable
