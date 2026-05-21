---
name: 调试模式
description: 这个项目里的 auth token 轮换与数据库连接排查经验
type: reference
---

## Auth Token 问题
- Refresh token 轮换后，旧 token 会立即失效
- 如果 refresh 后仍然返回 401，先检查客户端和服务端是否存在时钟偏移

## 数据库连接中断
- 连接池配置：开发环境上限 10，生产环境上限 50
- 排查时先执行 `docker compose ps`
