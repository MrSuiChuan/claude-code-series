# App Router 规则

- 默认优先使用 server component。
- 只有在确实需要 state、effect、浏览器 API 或交互事件时才加 `"use client"`。
- route segment 要保持小而清晰，可复用逻辑移到 `src/lib`。
- 面向用户的页面要明确处理 loading、empty 和 error state。
- server action 要保持轻量，并在修改数据前先完成输入校验。
