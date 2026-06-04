---
name: paperclip-init
description: 向导式创建 PaperClip 公司。交互式引导用户输入公司名和预算，自动生成 company.json 和 .paperclip/ 运行时目录。
---

# PaperClip 公司初始化向导

引导用户创建一个新的 PaperClip 公司。

## 执行步骤

1. 如果用户已通过 `userConfig` 配置公司名和预算，直接使用
2. 否则询问：公司名称（kebab-case）、每日 token 预算（默认 500000）
3. 从 `${CLAUDE_PLUGIN_ROOT}/assets/company_template/company.json` 读取模板
4. 替换模板中的公司名和预算
5. 写入 `./<公司名>/company.json`
6. 创建 `.paperclip/` 运行时目录结构（company.json、budget.json、agents/*.json、tasks/、design/、audits.jsonl）
7. 输出创建摘要，提示下一步"启动心跳"
