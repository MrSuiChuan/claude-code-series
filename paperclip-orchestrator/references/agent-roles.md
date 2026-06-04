# Agent Role Library

## Preset Roles

### architect (架构师)
- **Level**: Leadership
- **Reports to**: Board
- **Capabilities**: system_design, task_decomposition, code_review, architecture_planning
- **Budget share**: 25%
- **Max autonomous tokens**: 80,000
- **Use when**: Designing systems, decomposing requirements, assigning work

### developer (开发者)
- **Level**: Execution
- **Reports to**: architect
- **Capabilities**: code_implementation, bug_fixing, refactoring, testing
- **Budget share**: 40%
- **Max autonomous tokens**: 50,000
- **Use when**: Implementing features, fixing bugs, writing code

### reviewer (代码审查者)
- **Level**: Quality
- **Reports to**: architect
- **Capabilities**: code_review, security_audit, quality_analysis, test_review
- **Budget share**: 20%
- **Max autonomous tokens**: 40,000
- **Use when**: Reviewing code, security audits, quality gates

### operator (运维者)
- **Level**: Execution
- **Reports to**: architect
- **Capabilities**: deployment, monitoring, automation, incident_response
- **Budget share**: 10%
- **Max autonomous tokens**: 30,000
- **Use when**: Deploying, monitoring, running scheduled maintenance

### tester (测试者)
- **Level**: Quality
- **Reports to**: reviewer
- **Capabilities**: test_creation, automation_testing, bug_reporting, performance_testing
- **Budget share**: 5%
- **Max autonomous tokens**: 30,000
- **Use when**: Writing tests, running test suites, reporting bugs

## Custom Roles

Create a new `agents/data-engineer.md` with `paperclip:` frontmatter:

```markdown
---
name: paperclip-data-engineer
description: PaperClip 数据工程师。ETL、数据管道、SQL 优化。
model: sonnet
maxTurns: 20
paperclip:
  role: data_engineer
  display_name: 数据工程师
  level: execution
  reports_to: architect
  capabilities:
    - data_pipeline
    - sql_optimization
    - etl_development
  budget_share: 0.15
  max_autonomous_tokens: 50000
---

你是数据工程师。职责：
1. 设计和维护数据管道
2. 优化 SQL 查询
3. 开发 ETL 流程
```

Then register it in `.claude-plugin/plugin.json` `agents` array.

## Capability Taxonomy

| Capability | Description | Default Roles |
|-----------|-------------|--------------|
| system_design | System architecture design | architect |
| task_decomposition | Breaking down large tasks | architect |
| code_implementation | Writing production code | developer |
| bug_fixing | Debugging and fixing issues | developer |
| refactoring | Improving code structure | developer |
| code_review | Reviewing code quality | architect, reviewer |
| security_audit | Security vulnerability scanning | reviewer |
| quality_analysis | Code quality metrics | reviewer |
| test_creation | Writing test cases | tester, developer |
| automation_testing | CI/CD test automation | tester |
| deployment | Production deployment | operator |
| monitoring | System health monitoring | operator |
| incident_response | Responding to alerts | operator |

## Agent Mapping to Claude Code (v2.2)

Each PaperClip role maps to a Claude Code sub-agent defined in `agents/*.md`:

```
paperclip-architect   → agents/architect.md   (opus,  leadership, 30 turns)
paperclip-developer   → agents/developer.md   (sonnet, execution,  25 turns)
paperclip-reviewer    → agents/reviewer.md    (sonnet, quality,    20 turns)
paperclip-tester      → agents/tester.md      (sonnet, quality,    20 turns)
paperclip-operator    → agents/operator.md    (sonnet, execution,  15 turns)
paperclip-design-fetcher → agents/design-fetcher.md (haiku, execution, 10 turns)
```

Role definitions (capabilities, budget, level) are in each agent's `paperclip:` frontmatter.

For parallel execution, use Workflow.pipeline or Workflow.parallel with multiple agents.
