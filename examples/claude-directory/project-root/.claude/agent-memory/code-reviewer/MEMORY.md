# code-reviewer memory

## 已知约定
- 项目使用自定义 `Result<T, E>`，不用异常流作为主返回方式
- 认证中间件从 `Authorization` 头读取 `Bearer token`
- 测试数据通过 `test/factories/` 里的工厂函数生成

## 高频问题
- `src/api/*` 下经常缺少空值判断
- 后台任务里偶尔会漏掉 Promise 异常处理
