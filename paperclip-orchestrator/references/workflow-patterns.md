# Multi-Agent Workflow Patterns

## Pattern 1: Pipeline (Sequential)

Architect designs → Developer implements → Reviewer verifies.

```
Workflow pipeline:
  stage 1 (architect): Analyze requirements, decompose into tasks
  stage 2 (developer): Implement each task
  stage 3 (reviewer): Review and approve each completion
```

**Use when**: Clear sequential dependencies, each stage has a distinct role.

## Pattern 2: Parallel Review (Independent Verification)

N reviewers independently check the same code.

```
Workflow parallel:
  reviewer_01: Review for correctness
  reviewer_02: Review for security
  reviewer_03: Review for performance
→ Merge findings → Require 2/3 approvals
```

**Use when**: Quality is critical, multiple perspectives add value.

## Pattern 3: Master-Worker (Hierarchical)

One architect decomposes, many developers execute.

```
architect:
  → Analyze requirements
  → Create Task A (developer_01)
  → Create Task B (developer_02)
  → Create Task C (developer_03)

developers (parallel):
  → Each checks out their task
  → Implements independently
  → Reports completion

architect:
  → Reviews integration
  → Creates review tasks
```

**Use when**: Large projects that can be parallelized.

## Pattern 4: Competitive (Tournament)

Multiple solutions compete, best one wins.

```
parallel:
  agent_A: Solve problem with approach X
  agent_B: Solve problem with approach Y
  agent_C: Solve problem with approach Z

judge (architect):
  → Evaluate all solutions
  → Score: correctness, efficiency, maintainability
  → Select winner
  → Graft best ideas from runners-up
```

**Use when**: Solution space is wide, multiple approaches are valid.

## Pattern 5: Loop-Until-Dry (Exhaustive Discovery)

Keep finding issues until no new ones appear.

```
while new_bugs_found:
  finder agents (parallel):
    → Search for bugs in different dimensions
    → Report findings

  deduplicator:
    → Remove duplicates vs seen set

  if no new findings for 2 rounds:
    → Stop

  verifier agents (parallel):
    → Adversarially verify each finding
    → Require majority confirmation
```

**Use when**: Unknown scope of issues, need comprehensive coverage.

## Pattern 6: Review-Triage-Fix (Issue Resolution)

```
stage 1 - Review: Scan for issues (reviewer)
stage 2 - Triage: Classify by severity and type (architect)
stage 3 - Fix: Dispatch to appropriate developers (parallel)
stage 4 - Verify: Reviewer confirms fixes
```

**Use when**: Processing a batch of issues or PR review.

## Agent Communication

Agents communicate through shared state:
1. **Task descriptions** — Primary work item context
2. **Task comments** — Progress updates and decisions
3. **Audit log** — Immutable record of all actions
4. **Documents** — Shared artifacts (design docs, specs)

## Choosing the Right Pattern

| Situation | Pattern |
|-----------|---------|
| Sequential workflow with clear handoffs | Pipeline |
| High-stakes quality check | Parallel Review |
| Large project with independent pieces | Master-Worker |
| Creative problem with multiple approaches | Competitive |
| Unknown scope, need exhaustive coverage | Loop-Until-Dry |
| Processing a backlog of issues | Review-Triage-Fix |
