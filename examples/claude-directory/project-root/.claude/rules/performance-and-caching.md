---
paths:
  - "src/app/**/*.{ts,tsx}"
  - "src/components/**/*.{ts,tsx}"
  - "src/lib/**/*.{ts,tsx}"
---

# 性能与缓存规则

- 当 server rendering 足够时，不要引入不必要的客户端渲染。
- 数据获取和高成本计算的缓存边界要写清楚。
- 注意重复 fetch、bundle 体积激增和可避免的 rerender。
- 不影响首屏时，把非关键工作延后处理。
- 在为了微优化增加复杂度前，先测量真实收益。
