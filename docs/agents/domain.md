# Domain 文档

工程技能在探索代码库时，应按本文件的规则消费本仓库的领域文档。

## 探索之前，先读这些

- **`CONTEXT.md`**（仓库根目录），或
- **`CONTEXT-MAP.md`**（仓库根目录，若存在）：它指向每个上下文各自的 `CONTEXT.md`。读取与当前主题相关的那些。
- **`docs/adr/`**：读取与你即将改动的区域相关的 ADR。多上下文仓库还要看 `src/<context>/docs/adr/` 里上下文范围内的决策。

如果这些文件不存在，**静默继续**。不要提示它们缺失，也不要主动建议创建。`/domain-modeling` 技能（经由 `/grill-with-docs` 和 `/improve-codebase-architecture` 到达）会在术语或决策真正被定下来时惰性创建它们。

## 文件结构

单上下文仓库（绝大多数仓库）：

```
/
├── CONTEXT.md
├── docs/adr/
│   ├── 0001-event-sourced-orders.md
│   └── 0002-postgres-for-write-model.md
└── src/
```

多上下文仓库（根目录存在 `CONTEXT-MAP.md`）：

```
/
├── CONTEXT-MAP.md
├── docs/adr/                          ← 系统级决策
└── src/
    ├── ordering/
    │   ├── CONTEXT.md
    │   └── docs/adr/                  ← 上下文专属决策
    └── billing/
        ├── CONTEXT.md
        └── docs/adr/
```

**本仓库目前是单上下文。**

## 使用术语表里的词汇

当你的产出中要提到某个领域概念时（issue 标题、重构提案、假设、测试名），使用 `CONTEXT.md` 里定义的术语。不要漂移到术语表明确避开的同义词。

如果你需要的概念还不在术语表里，这是一个信号：要么你在发明项目不使用的语言（重新考虑），要么确实存在缺口（记下来，留给 `/domain-modeling`）。

## 标记 ADR 冲突

如果你的产出与某个已有 ADR 相矛盾，明确地摆出来，而不是悄悄覆盖：

> _与 ADR-0007（event-sourced orders）冲突，但值得重开讨论，因为……_
