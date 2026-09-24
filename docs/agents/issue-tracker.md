# Issue tracker：GitHub

本仓库的 issue 和 spec 都存在 GitHub Issues 里。所有操作使用 `gh` CLI。

## 约定

- **创建 issue**：`gh issue create --title "..." --body "..."`。多行正文用 heredoc。
- **读取 issue**：`gh issue view <number> --comments`，配合 `jq` 过滤评论，并一并取出标签。
- **列出 issue**：`gh issue list --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'`，按需加 `--label` 和 `--state` 过滤。
- **评论 issue**：`gh issue comment <number> --body "..."`
- **加 / 去标签**：`gh issue edit <number> --add-label "..."` / `--remove-label "..."`
- **关闭**：`gh issue close <number> --comment "..."`
- **正文里的 `## Blocked by` 只写一行指针**，指向 issue 页面右侧的 Dependencies 面板；**不要抄一份阻塞票列表**——列表的唯一出处是原生依赖边（见下文「阻塞关系」）。正文抄的那份是副本，票号一变动就漂：2026-09-24 就漂过一次，十张票里九张的编号全错、标题全对，照号读会读到别的票。原生 dependencies 不可用时，才回退到正文那行 `Blocked by: #<n>, #<n>`。

仓库从 `git remote -v` 推断；在 clone 目录里运行时 `gh` 会自动处理。

## PR 作为 triage 入口

**PR 作为请求入口：否。** _（如果本仓库把外部 PR 当成功能请求，改成 `是`；`/triage` 会读这个开关。）_

设为 `是` 时，PR 走与 issue 相同的标签和状态，用对应的 `gh pr` 命令：

- **读取 PR**：`gh pr view <number> --comments`，diff 用 `gh pr diff <number>`。
- **列出待 triage 的外部 PR**：`gh pr list --state open --json number,title,body,labels,author,authorAssociation,comments`，然后只保留 `authorAssociation` 为 `CONTRIBUTOR`、`FIRST_TIME_CONTRIBUTOR`、`NONE` 的（丢掉 `OWNER`/`MEMBER`/`COLLABORATOR`）。
- **评论 / 打标签 / 关闭**：`gh pr comment`、`gh pr edit --add-label`/`--remove-label`、`gh pr close`。

GitHub 的 issue 和 PR 共用一套编号，所以光看 `#42` 分不清是哪种：先用 `gh pr view 42` 解析，失败再回退到 `gh issue view 42`。

## 当技能说「publish to the issue tracker」

创建一个 GitHub issue。

## 当技能说「fetch the relevant ticket」

执行 `gh issue view <number> --comments`。

## Wayfinding 操作

供 `/wayfinder` 使用。**地图（map）** 是一个 issue，**子工单（child ticket）** 是它下面的 issue。

- **地图**：一个打了 `wayfinder:map` 标签的 issue，正文承载 Notes / Decisions-so-far / Fog。用 `gh issue create --label wayfinder:map`。
- **子工单**：作为 GitHub sub-issue 关联到地图（走 `gh api` 的 sub-issues 端点）。子 issue 功能不可用时，把子工单加进地图正文的任务列表，并在子工单正文开头写 `Part of #<map>`。标签用 `wayfinder:<type>`（`research`/`prototype`/`grilling`/`task`）。被认领后，工单分配给推进的开发者。
- **阻塞关系**：用 GitHub 原生的 issue dependencies，这是标准且 UI 可见的表示方式。加边用 `gh api --method POST repos/<owner>/<repo>/issues/<child>/dependencies/blocked_by -F issue_id=<blocker-db-id>`，其中 `<blocker-db-id>` 是阻塞方的**数字数据库 id**（`gh api repos/<owner>/<repo>/issues/<n> --jq .id`，**不是** `#number` 也不是 `node_id`）。GitHub 通过 `issue_dependencies_summary.blocked_by` 报告（只含仍打开的阻塞方，即实时闸门）。dependencies 不可用时，回退到子工单正文开头的 `Blocked by: #<n>, #<n>` 一行。所有阻塞方都关闭时，工单才算解锁。
- **前沿查询（frontier query）**：列出地图下仍打开的子工单（`gh issue list --state open`，限定在地图的 sub-issues / 任务列表内），剔除有未关闭阻塞方的（`issue_dependencies_summary.blocked_by > 0`，或 `Blocked by` 行里还有打开的 issue）以及已有 assignee 的；按地图顺序取第一个。
- **认领**：`gh issue edit <n> --add-assignee @me`，这是本 session 的第一次写入。
- **解决**：先 `gh issue comment <n> --body "<answer>"`，再 `gh issue close <n>`，最后把上下文指针（要点 + 链接）追加到地图的 Decisions-so-far。
