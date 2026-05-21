---
description: Investigates a bug report in a web application and narrows it to the most likely root cause. Use when Claude should reproduce an issue, trace the relevant path through UI, API, and database layers, and propose the smallest safe fix.
argument-hint: <bug-summary>
---

Triaging bug: $ARGUMENTS

Process:

1. Restate the bug clearly
2. Identify the likely entry point
3. Trace the flow through UI, API, and data layers
4. List the most likely root causes
5. Propose the smallest safe fix
6. Recommend a regression test
