# 项目约定

## 常用命令
- 构建：`npm run build`
- 测试：`npm test`
- 校验：`npm run lint`

## 技术栈
- TypeScript，开启 strict mode
- React 19，只使用函数式组件

## 开发规则
- 统一使用 named exports
- 测试文件与源文件同目录放置：`foo.ts` -> `foo.test.ts`
- 所有 API 路由统一返回 `{ data, error }` 结构
