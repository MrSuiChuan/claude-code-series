---
description: 评审代码改动中的安全漏洞、认证缺口和注入风险
disable-model-invocation: true
argument-hint: <branch-or-path>
---

## 待评审的 Diff

!`git diff $ARGUMENTS`

请围绕下面这些点审查上面的改动：

1. 注入漏洞，例如 SQL、XSS、command 注入
2. 认证和授权缺口
3. 硬编码的 secret 或凭据

完整检查项请参考当前 skill 目录下的 `checklist.md`。

输出问题时请附带严重级别和修复步骤。
