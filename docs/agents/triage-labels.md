# Triage 标签

工程技能用五个标准 triage **角色**来思考问题。本文件把角色映射到本仓库 issue tracker 里实际使用的标签字符串。

| mattpocock/skills 里的角色 | 本仓库实际标签 | 含义 |
| -------------------------- | -------------- | ---- |
| `needs-triage`             | `待分诊`       | 维护者需要评估这个 issue |
| `needs-info`               | `待补充信息`   | 等待报告人补充信息 |
| `ready-for-agent`          | `可交给智能体` | 规格已完整，可交给 AFK agent |
| `ready-for-human`          | `待人工处理`   | 需要人来实现 |
| `wontfix`                  | `不予处理`     | 不打算做 |

当技能提到某个角色时（例如「apply the AFK-ready triage label」），使用本表右列对应的标签字符串。

注：类别角色 `bug` 和 `enhancement` 不在本表范围内，它们在 GitHub 上保持英文原名，由 `triage` 技能直接使用。

改动右列时记得同步 GitHub 上的实际标签（`gh label create`），否则打标签会因标签不存在而失败。
