# 安徽工程大学教务系统 & 开源参考调研

> 调研日期：2026-09-23 / 2026-09-24
> 调研方式：匿名 HTTP 探针（curl）+ GitHub API（`gh api`）+ pub.dev API。
> **未做任何登录、未提交任何表单、未使用真实学号密码。**
>
> **方法学限制（重要）**：
> - 本环境 `WebSearch` 工具全程返回空结果（工具异常，非「无结果」），因此本报告**没有使用任何搜索引擎结果**，
>   全部证据来自**直接 HTTP 抓取**、**GitHub API/源码**、**pub.dev API**。
> - `WebFetch` 对 `github.com`、`pub.dev`、`beangle.github.io` 均被安全策略拦截（"Unable to verify if domain is safe"），
>   改用 `gh api` 与 `curl` 直连。
> - curl 直连 `bing.com` / `lite.duckduckgo.com` 均失败（302/000），无法用搜索引擎交叉验证。
>
> 标注约定：**【证实】**= 有可复现来源；**【推测】**= 附线索；**【未找到】**= 明确未找到公开来源。

---

## 结论速览

| 问题 | 结论 | 置信度 |
|---|---|---|
| 教务系统厂商 | **EAMS 谱系**（开源源码 `openurp/edu-eams-webapp`，商业化厂商为**上海树维 Supwisdom**）；登录页由 **Beangle** 框架渲染；统一身份认证疑似**金智教育 Wisedu authserver** | 【证实】为主 |
| 是否强智/正方/青果/超星 | **都不是** | 【证实】 |
| 登录加密 | 客户端 `CryptoJS.SHA1('<每部署不同的UUID盐>-' + password)`，无 RSA | 【证实】 |
| 验证码 | 登录页初始无验证码 | 【证实】 |
| 公网可达性 | 登录页公网匿名可达（HTTP 200）；登录后功能未知 | 【证实】/【未找到】 |
| 后端课表接口 | 同款系统已知：`courseTableForStd.action` + `dataQuery.action` + `courseTableForStd!courseTable.action` | 【证实】（同款系统源码）/【推测】（AHPU 路径） |
| 导出 Excel 结构 | **未找到**任何公开来源 | 【未找到】 |
| 打印页 | 同款系统源码有 `print` 分支 → `courseTableLessonForPrint` 模板 | 【证实】（源码层） |
| AHPU 专属开源项目 | 只有 1 个（⭐1，Qt/C++，仅配登录页）；无成熟的 AHPU 适配层 | 【证实】 |
| Flutter 生态 | 有网格/日历组件；**无**成型「教务导入/周次解析」库；`.xls` 解析只有小仓库 | 【证实】 |

---

## A. 教务系统的技术形态

### A1. 厂商判断

**【证实】登录页由 Beangle 框架渲染**

匿名抓取 `http://xjwxt.ahpu.edu.cn/ahpu/localLogin.action` → HTTP 200，页面头部：

```html
<script type="text/javascript" src="/ahpu/static/scripts/jquery/jquery,/scripts/beangle/beangle.js"></script>
<link id="beangle_theme_link" rel="stylesheet" href="/ahpu/static/themes/default/beangle-ui.css" />
```

进一步抓 `/ahpu/static/scripts/beangle/beangle.js`，文件头版权注释原文：

```
Beangle, Agile Java/Scala Development Scaffold and Toolkit
Copyright (c) 2005-2013, Beangle Software.
... GNU Lesser General Public License ...
Version 3.3.4
```

- Beangle 官网/GitHub org：<https://github.com/beangle>（org 建於 2011-02-11）
- `beangle/beangle3` ⭐23、LGPL-3.0、最后 push 2026-07-23："Agile Java Development Scaffold and Toolkit"
- 来源（实测，可复现）：
  - `curl -s http://xjwxt.ahpu.edu.cn/ahpu/localLogin.action`
  - `curl -s http://xjwxt.ahpu.edu.cn/ahpu/static/scripts/beangle/beangle.js`

**【证实】课表 action 名 = `courseTableForStd`，而该 action 属于开源项目 OpenURP 的 EAMS**

- 第三方项目 `CrimsonSeraph/Schedule` 代码注释记录（称「实测」）：
  > 「课表页实测为 `/ahpu/courseTableForStd!courseTable.action`，但其中带有与会话绑定的 ids 参数」
  - 来源：<https://github.com/CrimsonSeraph/Schedule/blob/main/src/app/main.cpp>（第 113–132 行）
  - 注意：同一注释把该校系统标为「**正方教务 V9**」，这个**厂商标注是错的**（`courseTableForStd` 不是正方命名）；但其记录的 URL 本身与下文 EAMS 源码完全对上。
- 开源实现 `openurp/edu-eams-webapp` ⭐2、Scala、GPL-3.0、最后 push 2015-04-13：
  - `schedule/src/main/scala/org/openurp/edu/eams/teach/schedule/web/action/CourseTableForStdAction.scala`
  - `schedule/src/main/scala/org/openurp/edu/eams/teach/schedule/web/action/CourseTableAction.scala`
  - 包名 `org.openurp.edu.eams`，历史包名 `com.ekingstar.eams`（见 `core/src/test/java/com/ekingstar/eams/...`）
  - 来源：<https://github.com/openurp/edu-eams-webapp>
- → **`courseTableForStd.action` 是 EAMS（Educational Administrative Management System）的学生课表入口**，AHPU 用的就是这个谱系的系统。

**【证实】商业化厂商 = 上海树维（Supwisdom）**

- GitHub org `supwisdom`：`name = "上海树维"`，`blog = http://www.supwisdom.com`，创建于 2015-07-27
  - 来源：`gh api orgs/supwisdom`；<https://github.com/orgs/supwisdom/repositories>（如 `supwisdom/spreadsheet-mapper` ⭐28）
- 多校第三方适配脚本把 `courseTableForStd.action` 系列明确称为「树维教务 / 树维 EAMS」（互相独立的多个来源）：
  - `ShiGuangSchedule/shiguang_warehouse` → `resources/ZUA/adapters.yaml`（郑州航空工业管理学院）：
    `import_url: "http://jwglxt.zua.edu.cn/eams/loginExt.action"`，描述「郑州航空工业管理学院**树维 EAMS** 教务课表导入」
  - 同仓库 `resources/NEUQ/adapters.yaml`（东北大学秦皇岛分校）：adapter_name「东北大学秦皇岛分校**树维**教务」
  - 同仓库 `resources/XATU/adapters.yaml`（西安工业大学）：描述「**树维**教务系统适配」
  - 同仓库 `resources/YANGTZEU/adapters.yaml`（长江大学）：描述「适配长江大学教务系统（**树维**）导入」
  - `Ares-Gao/WeCourseService` ⭐17、Go、MIT：「微课表服务端（**树维**教务系统接口封装）」，内含 `SupwisdomClient.php`
  - `whoisnian/getMyCourses` ⭐37、Go、MIT：「从 NEU 新版**树维**教务系统获取自己的课程表」
  - 来源：<https://github.com/ShiGuangSchedule/shiguang_warehouse>、<https://github.com/Ares-Gao/WeCourseService>、<https://github.com/whoisnian/getMyCourses>

**【推测】统一身份认证为金智教育（Wisedu）authserver**

- 实测：`/ahpu/login.action` → **HTTP 302** → `http://ids.ahpu.edu.cn/authserver/login?service=http%3A%2F%2Fxjwxt.ahpu.edu.cn%2Fahpu%2Flogin.action`
- `ids.<学校>.edu.cn/authserver/login?service=...` 是金智教育统一身份认证的典型路径形态。
- 强线索：**长安大学同款系统**（见 A4，与 AHPU 完全同构）的记录：
  `https://ids.chd.edu.cn/authserver/login?service=http%3A%2F%2Fbkjw.chd.edu.cn%2Feams%2Fhome.action`
  - 来源：<https://github.com/code-cycler/course_schedule_for_CHD/blob/master/docs/eams-urls.txt>
- 另线索：`lingion/sleepy` 的协议注释把该族称为「经典**金智**/树维 EAMS」：
  > 「经典金智/树维 EAMS (`courseTableForStd!courseTable.action` 系列) 课表解析器。」
  - 来源：<https://github.com/lingion/sleepy/blob/main/app/src/main/java/com/lingion/sleepy/data/jw/JwClassicEamsParser.kt>
- 独立项目 `CompleX-maker/lixin-schedule`（上海立信会计金融学院，同为 `timetable!courseTable.action` 族）README 直接写「**Beangle EAMS**」：
  > 「统一身份认证直登：学号 + 密码登录，CAS 验证通过后自动抓取本学期课表（**Beangle EAMS**）」
  - 来源：<https://github.com/CompleX-maker/lixin-schedule>

**关于 `localLogin.action` 的排除项**

`localLogin.action` + `/eams/` 或自定义 context path（如 `/ahpu/`）+ Beangle 不是 AHPU 独有。实测**安徽科技学院** `http://jwxt.ahstu.edu.cn/eams/localLogin.action` 与 AHPU 登录页**结构完全一致**（同样引用 `beangle.js`、`beangle-ui.css`、同样有 `encodedPassword` 隐藏域、同样有 `localLogin.action` + `login.action` 双入口）。→ 这是**同一厂商同一产品**的两处部署。

- 实测：`curl -s http://jwxt.ahstu.edu.cn/eams/localLogin.action`

### A2. 登录流程

**【证实】表单字段（实测登录页 HTML 原文）**

| 字段 | 类型 | 说明 |
|---|---|---|
| `username` | text, maxlength=40 | 用户名 |
| `password` | password, maxlength=40 | 明文密码（仅存在于 DOM，提交前被覆写） |
| `encodedPassword` | hidden | 实际提交的哈希值 |
| `session_locale` | radio, `zh_CN` / `en_US` | 语言，默认 `zh_CN` |
| `submitBtn` | submit, value="登录" | |

- **没有** `j_username` / `j_password`（那是另一支 URP/Spring Security 风格，如 `bkjw.hnist.cn`、`jwxt.imu.edu.cn`）。
- `form action = /ahpu/localLogin.action`, `method = post`。
- 另有入口：`<a href="/ahpu/login.action">从统一身份认证登录</a>`（走 CAS）；`/ahpu/resetPassword.action`（忘记密码）。

**【证实】提交加密：SHA1(salt + password)，非 RSA**

实测登录页内联脚本原文：

```js
function checkLogin(form){
    if(!form['username'].value){ alert("用户名称不能为空");return false; }
    if(!form['password'].value){ alert("密码不能为空");return false; }
    form['password'].value = CryptoJS.SHA1('ef894aaf-3bfc-4e4d-abea-36bf29514a08-' + form['password'].value);
    return true;
}
```

- `CryptoJS` 来自 `/ahpu/static/scripts/sha1.js`（文件头：`CryptoJS v3.1.2, code.google.com/p/crypto-js, (c) 2009-2013 by Jeff Mott`）。
- 盐值 `ef894aaf-3bfc-4e4d-abea-36bf29514a08` 是 **AHPU 这个部署的字面量**，硬编码在页面里；同款系统的安徽科技学院是另一个 UUID（`cb11b68f-d18b-4969-b13c-a87f14dc21ec`）。→ 盐值**随部署而变，不是固定全局常量**，写适配层时必须从登录页动态提取。
- 结果是**裸 SHA1 十六进制**，没有 nonce/时间戳参与；`encodedPassword` 才是实际 POST 的字段（`password` 已被覆写为同一哈希值）。
- **无 RSA**，无验证码，无时间戳。

**【证实】无验证码（就初始登录页而言）**

登录页 HTML 里没有任何验证码图片 / 输入框 / kaptcha 引用。

**【未找到】** 连续失败 N 次后是否强制出现验证码。注意：同族系统西北政法大学的 EAMS 部署**有验证码**，其接口文档明确记录了验证码流程（`dream2333/NWUPL-Pure-EMS` 的「接口.md」：「使用 cookies 获取验证码图片 / 从图片构建真实登录表单」）。AHPU 是否为条件触发验证码，未找到来源。

### A3. 公网 / 校园网限制

- **【证实】登录页从公网匿名可达**：从本机（中国大陆，非校园网）`curl http://xjwxt.ahpu.edu.cn/ahpu/localLogin.action` 返回 **HTTP 200**，完整拿到登录页 HTML。
- **【证实】存在 WebVPN 服务**：`https://webvpn.ahpu.edu.cn/` 返回 302（指向自身，需具体路径）；`vpn.ahpu.edu.cn` 无响应（HTTP 000）。
- **【未找到】** 登录后使用课表/导出功能是否需要校园网或 WebVPN。无法在不登录的前提下判断。
- **【证实】全局登录拦截**：以下路径全部 302 → `/ahpu/localLogin.action`：
  - `/ahpu/courseTableForStd.action`、`/ahpu/courseTableForStd!courseTable.action`
  - `/ahpu/homeExt.action`、`/ahpu/home.action`、`/ahpu/dataQuery.action`、`/ahpu/stdDetail.action`
  - `/ahpu/xskbcx.action`
  - **连不存在的 action 也一样 302**（`/ahpu/nonexistent_garbage_xyz.action` → 302）
  - → 无法用「404 vs 302」区分接口是否存在，匿名枚举接口不可行。

### A4. 课表相关后端接口

**【证实】同款系统（OpenURP EAMS）的接口契约**

来自 `dream2333/NWUPL-Pure-EMS` 的「接口.md」（西北政法大学，同族 EAMS 实测整理）：

| 接口 | 方法 | 参数 | 说明 |
|---|---|---|---|
| `/eams/courseTableForStd.action` | GET | — | 课表初始化；从响应正则取 `semesterBar\d+Semester` → `tagId`；从 cookies 取 `semester.id`；正则 `(?<=form,"ids",")\d+(?="\))` → `ids`（两个值：个人课表 id、班级课表 id） |
| `/eams/dataQuery.action` | POST | `dataType=projectId` | 返回计划 id（本科/研究生区分，一般 1） |
| `/eams/dataQuery.action` | POST | `tagId`、`dataType=semesterCalendar`、`value=<semesterId>`、`empty=false` | 返回所有学期 id 与名称 |
| `/eams/courseTableForStd!courseTable.action` | POST | `ignoreHead=1`、`setting.kind`（`std` 个人/`class` 班级）、`startWeek`（周次，空=全部周）、`project.id`、`semester.id`、`ids` | **返回课表；课表内容在最下方的 javascript 里** |
| `/eams/homeExt.action` | GET | — | 主页 |

- 来源：<https://github.com/dream2333/NWUPL-Pure-EMS/blob/main/接口.md>
- 源码佐证（`CourseTableForStdAction.scala` 的 `courseTable()` 方法确实读取 `setting`、`ids`，并做 `stdCourseTablePermissionChecker.check(...)`）：
  <https://github.com/openurp/edu-eams-webapp/blob/master/schedule/src/main/scala/org/openurp/edu/eams/teach/schedule/web/action/CourseTableForStdAction.scala>
- 长安大学的同款 URL 记录：`http://bkjw.chd.edu.cn/eams/courseTableForStd!courseTable.action 学生课表页面`
  <https://github.com/code-cycler/course_schedule_for_CHD/blob/master/docs/eams-urls.txt>

**【推测】AHPU 的对应路径 = `/ahpu/` 前缀**

把上表的 `/eams/` 换成 `/ahpu/`。依据：
- AHPU 登录页里所有静态资源、action 都在 `/ahpu/` 下（context path = `/ahpu`）；
- `CrimsonSeraph/Schedule` 记录 AHPU 课表页为 `/ahpu/courseTableForStd!courseTable.action`；
- 用户名密码登录后，`/ahpu/courseTableForStd.action` 等路径确实存在（有登录拦截，302 而非 404 无法区分，但结合同款系统源码与第三方记录，前缀替换是合理推断）。

**【证实】「不存在的 action 也 302」** → 因此无法匿名核实每个接口是否真的部署了。

**【未找到】** AHPU 使用 `xskbcx` / `kbxx` / `jxhjkcx` 这类路径名的任何证据。实测 `/ahpu/xskbcx.action` 也是 302 回登录页（无区分度）。这些路径名属于 URP 旧版/其他支系，**不要按此假设 AHPU**。

---

## B. 导出 Excel 的结构

### B5. Excel 长什么样

**【未找到】** 没有任何公开来源记录 AHPU（或同款系统）课表导出的表头、行语义、周次/教室编码、是否合并单元格、是 `.xls` 还是 `.xlsx`、是否需要 `.xls` 解析库。**这一项必须由用户自己导出一次样本文件后确认，不能靠外部资料。**

以下是可用的**线索**（均为【推测】，只说明"数据源头长什么样"，不代表导出文件形态）：

1. **课表页 DOM 里没有表格数据**（【证实】）
   - 同族系统的课表由 JSP/模板里的内联 JS 渲染，HTML 表格是空壳：
     > 「课表数据在页面内嵌 JS 块 — `var table0 = new CourseTable(2019,84); var unitCount = 12; activity = new TaskActivity(教师ID, 教师名, 课号, 课名, roomId, 教室, 周次位图, ...); index = D*unitCount+P; table0.marshalTable(2,1,21);`」
     > 「HTML 表格 `#manualArrangeCourseTable` 是空壳（JS 端 fillTable 渲染），DOM 无数据。」
   - 来源：`lingion/sleepy` → `JwClassicEamsParser.kt` 类注释
     <https://github.com/lingion/sleepy/blob/main/app/src/main/java/com/lingion/sleepy/data/jw/JwClassicEamsParser.kt>
   - 另一独立来源（长安大学，同款系统）：
     > 「课表编码诡异 | 时间用「53 位周数位图」表示，还有 +1 偏移」
     > 「1. **TaskActivity JS 数据**（主）：正则切 `var teachers[…]…var courseName="…"…new TaskActivity(…)` 块，提取教师/教室/53 位周位图/`index=day*unitCount+node`。」
     - 来源：<https://github.com/code-cycler/course_schedule_for_CHD/blob/master/docs/DESIGN.md>

2. **周次在系统内部是位图串**（【证实】，同族系统实测）
   > 「学校系统位图 **bitmap[0] = 第 0 周（预备周）**，不是第 1 周。所以解析时 `week = index + 1` 后还要 `-1` 修正」
   > 「`remark` 里塞 `weeksBitmap:0101…`（53 位）」「教务系统原始数据就是 53 位周位图（`000000001111111111000…`，每位代表一周）」
   - 来源：<https://github.com/code-cycler/course_schedule_for_CHD/blob/master/docs/DESIGN.md>
   - 另一个位图形态（同一族但不同校）：`01` 串位图，「下标 0 是占位符，下标 i=1 即第 i 周（勿 +1）」（sleepy 注释）；以及 `SKZC` 位图 `"000000000000000000100"`（金智 jwapp 模块，`shiguang_warehouse/resources/AEPU/aepu.js`）。
   - → **位图偏移没有跨校统一答案**，必须用真实样本对齐。

3. **AHPU 的 `unitCount`（每天节次数）= 12**（【证实】：代码注释点名，但属第三方观察）
   > 「unitCount 从页面抠 (禁写死: 电子科大/天大/**安工程** 12, 湖南师大 13, 河南理工 11)」
   - 来源：<https://github.com/lingion/sleepy/blob/main/app/src/main/java/com/lingion/sleepy/data/jw/JwClassicEamsParser.kt>
   - 这是**唯一**在我找到的所有公开资料里明确点名"安工程"的技术参数。注意 sleepy 的 `schools.json` 里**并没有**安徽工程大学条目，所以这是作者（或上游）在别处见过 AHPU 课表后写下的备注。

4. **教室编码**：同族系统里教室是「教学楼 + 教室」拼接（sleepy `JwUrpParser` 的 `building + room`），长表头形态为「课程名/教师/星期/节次/周次/教学楼/教室/节数」。**但这是 URP 老版 HTML 网格的形态，不是 AHPU 的 classic_eams 形态**，仅作参考。

5. **如果导出的是 `.xls`（BIFF 旧二进制格式）**，Dart 生态的可用库见 C9 末段——主流库都**不支持** `.xls`。

### B6. 打印页

**【证实】（源码层）同款系统存在打印渲染分支**

`CourseTableAction.scala` 末尾：

```scala
if (getBool("print")) {
  forward("courseTableLessonForPrint")
} else {
  forward("courseTableLesson")
}
```

- 来源：<https://github.com/openurp/edu-eams-webapp/blob/master/schedule/src/main/scala/org/openurp/edu/eams/teach/schedule/web/action/CourseTableAction.scala>（第 715 行附近）
- → 同族系统的课表页支持一个 `print` 布尔参数，切到 `courseTableLessonForPrint` 模板（打印友好视图）。

**【未找到】** AHPU 部署里该打印页的具体 URL 与它是否是可解析的纯 HTML 表格。
**【证实】但可以确定：不要指望直接抓课表页的 HTML 表格** —— 课表页表格是空壳，数据只在 JS 里（见 B5 第 1 条）。所以「打印页」对半自动导入的价值取决于该模板是否服务端渲染出真实表格；**需登录后实测**。

**关于日历（ICS）导出**：【证实】同族系统有个 `CalendarDownloadAction`，但它是下载**教学日历 `.doc` 文件**，不是 ICS：
<https://github.com/openurp/edu-eams-webapp/blob/master/schedule/src/main/scala/org/openurp/edu/eams/teach/schedule/web/action/CalendarDownloadAction.scala>

---

## C. GitHub 开源项目

### C7a. 直接提到「安徽工程大学」的项目

| 仓库 | star | 语言 | 最后 push | License | 与 AHPU 的关系 |
|---|---|---|---|---|---|
| [CrimsonSeraph/Schedule](https://github.com/CrimsonSeraph/Schedule) | ⭐1 | C++ / Qt | 2026-09-17 | LGPL-2.1 | **最直接**。内置 `ahpu-jwxt` 适配器 id，`login_url = http://xjwxt.ahpu.edu.cn/ahpu/localLogin.action`，`schedule_url` 留空（走内嵌浏览器抓当前页）。注释记录课表页 URL 与 `ids` 会话参数。**注意其厂商标注「正方 V9」是错的。** |
| [LonelyMarch/OpenWakeUp](https://github.com/LonelyMarch/OpenWakeUp) | ⭐3 | Kotlin | 2026-09-21 | AGPL-3.0 | `app/src/main/assets/schools.json` 有「安徽工程大学 / `http://xjwxt.ahpu.edu.cn/ahpu/localLogin.action`」，type 标为 `xatu_shuwei`（**该 type 标注可疑**，与 Sleepy 的命名体系对不上） |
| [lingion/sleepy](https://github.com/lingion/sleepy) | ⭐58 | Kotlin | 2026-09-22 | GPL-3.0 | `schools.json` **无** AHPU 条目；但 `JwClassicEamsParser.kt` 注释点名「安工程 12 节」 |
| [newer-zhu/AHPU_Library_Auto_Booking](https://github.com/newer-zhu/AHPU_Library_Auto_Booking) | ⭐2 | Python | 2021-07-24 | 无 | AHPU **图书馆**座位预约爬虫，**不是教务** |
| [Tthih-Yu/Web-devise](https://github.com/Tthih-Yu/Web-devise) / [bkfish/Src-Toolset](https://github.com/bkfish/Src-Toolset) | — | — | — | — | 仅在 URL 清单里出现 `xjwxt.ahpu.edu.cn`，无可用代码 |
| [shixiuhai/universityInformation](https://github.com/shixiuhai/universityInformation) | — | — | — | — | 高校域名清单，含 ahpu.edu.cn |

- **【证实】没有**针对安徽工程大学教务系统的成熟开源适配层/爬虫/SDK。

### C7b. 拾光 / WakeUp / 小爱课程表 系：均无 AHPU

- [ShiGuangSchedule/shiguang_warehouse](https://github.com/ShiGuangSchedule/shiguang_warehouse) ⭐59、JavaScript、push 2026-09-23 — 拾光课程表官方适配仓库。`resources/` 下 **222 所学校**，**没有安徽工程大学**（唯一的「安徽」系是 `AEPU` = 安徽电气工程职业技术学院、`AHSZU`、`AHZYYGZ`）。
- [XingHeYuZhuan/shiguangschedule](https://github.com/XingHeYuZhuan/shiguangschedule) ⭐912、Kotlin、Apache-2.0、push 2026-09-22 — 拾光课程表 App 本体。
- [dIT8Zv/WakeupSchedule_BUPT](https://github.com/dIT8Zv/WakeupSchedule_BUPT) ⭐0、Apache-2.0 — WakeUp 课程表 BUPT 版，**含 17 类教务协议全集**（`schedule_import/Common.kt`），是 sleepy 的上游。star 低但协议覆盖最全。
- [YZune/WakeUpSchedule](https://github.com/YZune/WakeUpSchedule) ⭐29、Java、**最后 push 2018-04-07**（停滞）、无 License。

### C7c. 其他厂商 / 其他系统（相关但不同族）

| 仓库 | star | 语言 | 最后 push | License | 备注 |
|---|---|---|---|---|---|
| [FarmerChillax/new-school-sdk](https://github.com/FarmerChillax/new-school-sdk) | ⭐125 | Python | 2026-08-26 | MIT | **新正方**教务 SDK，含两种验证码处理 |
| [lndj/Lcrawl](https://github.com/lndj/Lcrawl) | ⭐119 | PHP | 2025-06-07 | MIT | 正方教务爬虫 |
| [zaigie/zfnew_webApi](https://github.com/zaigie/zfnew_webApi) | ⭐59 | Python | 2022-07-06 | MIT | 新正方 WebAPI |
| [JamesZBL/URP_Spider](https://github.com/JamesZBL/URP_Spider) | ⭐24 | Python | 2018-04-12 | 无 | URP 教务信息收集（**另一支 URP**，非 AHPU 同款） |
| [sinyu1012/YCITSpider](https://github.com/sinyu1012/YCITSpider) | ⭐8 | Java | 2019-01-22 | 无 | 盐城工学院 URP 登录爬虫 |
| [Reversedeer/urp-academic-affairs-tools](https://github.com/Reversedeer/urp-academic-affairs-tools) | ⭐0 | Python | 2026-08-16 | Apache-2.0 | 「URP 教务系统的抢课脚本」，**特性含 "Timetable export to Excel"**；目标站点 `jws.qgxy.cn`，非 AHPU |

> 提醒：`ahpu` / `安徽工程大学` 的仓库搜索里混入大量无关结果（书籍列表、语料库），已人工剔除。

### C8. 通用可复用的适配层 / 参考实现

**最有价值的两个（AHPU 同款系统）**

| 仓库 | star | 语言 | 最后 push | License | 为什么重要 |
|---|---|---|---|---|---|
| [openurp/edu-eams-webapp](https://github.com/openurp/edu-eams-webapp) | ⭐2 | Scala | 2015-04-13（**不活跃**） | GPL-3.0 | **AHPU 同款系统的开源源码本身**。有 `CourseTableForStdAction` / `CourseTableAction` / `CourseTable.scala` / `CourseTableSetting.scala`，是推断接口与字段的**最强依据**（虽老，但 action 名与参数形态仍对得上） |
| [code-cycler/course_schedule_for_CHD](https://github.com/code-cycler/course_schedule_for_CHD) | ⭐23 | Kotlin | 2026-09-11 | NOASSERTION（有 LICENSE 文件） | **长安大学**，与 AHPU 完全同构（`bkjw.chd.edu.cn/eams/` + `ids.chd.edu.cn/authserver` + `courseTableForStd!courseTable.action`）。有 `docs/DESIGN.md`（53 位周位图、TaskActivity 正则切分、`index=day*unitCount+node`、坑位清单）。**是最完整的实战案例** |

**其他可参考的适配层**

| 仓库 | star | 语言 | 最后 push | License | 备注 |
|---|---|---|---|---|---|
| [lingion/sleepy](https://github.com/lingion/sleepy) | ⭐58 | Kotlin | 2026-09-22（**活跃**） | GPL-3.0 | 340 校 / 31 类协议；`JwClassicEamsParser.kt`（EAMS）、`JwUrpParser.kt`（URP）、`JwNewUrpParser.kt`；`docs/schools-list.md` 是很好的协议分类参照 |
| [ShiGuangSchedule/shiguang_warehouse](https://github.com/ShiGuangSchedule/shiguang_warehouse) | ⭐59 | JavaScript | 2026-09-23（**活跃**） | MIT | 222 校适配脚本；`resources/*/adapters.yaml` 写清了系统族（「树维 EAMS」/「金智老版」/「强智」…），是**厂商归类的最佳索引** |
| [CompleX-maker/lixin-schedule](https://github.com/CompleX-maker/lixin-schedule) | ⭐2 | TypeScript | 2026-09-22 | 无 | 立信 EAMS；README 明确写「Beangle EAMS」，佐证登录页 = Beangle |
| [whoisnian/getMyCourses](https://github.com/whoisnian/getMyCourses) | ⭐37 | Go | 2020-09-15 | MIT | 树维教务 → `.ics`（日历导出思路） |
| [Ares-Gao/WeCourseService](https://github.com/Ares-Gao/WeCourseService) | ⭐17 | Go | 2026-06-06 | MIT | 树维教务接口封装（服务端） |
| [Illustar0/ZZU.Py](https://github.com/Illustar0/ZZU.Py) | ⭐29 | Python | 2026-09-21 | MIT | 郑州大学校园 API 封装（PyPI 包） |
| [ClassIsland/ClassIsland](https://github.com/ClassIsland/ClassIsland) | ⭐2813 | C# | 2026-09-20（**活跃**） | GPL-3.0 | 班级多媒体屏课表显示工具。**没有教务适配层**，但 `ClassIslandProfileExcelExporter` 是一个「课表 ↔ Excel」的成熟实现，可参考 |
| [supwisdom/spreadsheet-mapper](https://github.com/supwisdom/spreadsheet-mapper) | ⭐28 | Java | 2019-09-11 | NOASSERTION | 树维官方出的「Excel ↔ POJO 映射」库（厂商自己在用 Excel 做导入导出，侧面说明导出产物是标准电子表格） |

### C9. Flutter / Dart 生态

#### 课表网格 / 日历组件 —— 有现成轮子

| 包 / 仓库 | 版本 / star | 语言 | 最后更新 | License | 说明 |
|---|---|---|---|---|---|
| [JonasWanke/timetable](https://github.com/JonasWanke/timetable) | ⭐308 | Dart | 2025-08-21 | Apache-2.0 | 「Customizable flutter calendar widget including day and week views」——周/日视图组件，最成熟的候选 |
| [yamarkz/flutter_timetable_view](https://github.com/yamarkz/flutter_timetable_view) | ⭐15 | Dart | 2023-10-24 | MIT | 「Timetable Widget Package for Flutter」——专门的课表 Widget 包，**近 3 年未更新** |

#### 开源课表 App（参考数据模型 / 交互）

| 仓库 | star | 语言 | 最后 push | License | 值不值得看 |
|---|---|---|---|---|---|
| [BenderBlog/traintime_pda](https://github.com/BenderBlog/traintime_pda) | ⭐321 | Dart | 2026-09-22 | MPL-2.0 | 西电 XDYou。体量最大、最活跃的 Flutter 校园 App，工程结构可参考 |
| [gnahz77/SchedU](https://github.com/gnahz77/SchedU) | ⭐83 | Dart | 2026-04-11 | MIT | 「支持 JSON、AI 导入课程」——**导入格式设计**可参考 |
| [Mutx163/mikcb](https://github.com/Mutx163/mikcb)（轻屿课表） | ⭐50 | Dart | 2026-09-23 | GPL-3.0 | 「教务导入、云同步」，与目标形态最接近 |
| [wyvern1723/sachet](https://github.com/wyvern1723/sachet) | ⭐26 | Dart | 2026-09-06 | MIT | 湘潭大学；教务 + 空教室 + 成绩，单校深度整合的样板 |
| [Mashiro0619/Sked](https://github.com/Mashiro0619/Sked) | ⭐19 | Dart | 2026-09-23 | AGPL-3.0 | 「日程、课程表管理应用」 |
| [JS-CAUTION/csust-course-schedule](https://github.com/JS-CAUTION/csust-course-schedule)（千纸课） | ⭐4 | Dart | 2026-09-19 | MIT | 「支持教务 **CSV**/在线导入」——**CSV 导入路线**的直接参考 |
| [XiaoNaoWeiSuo/Grade2](https://github.com/XiaoNaoWeiSuo/Grade2) | ⭐6 | Dart | 2026-09-23 | AGPL-3.0 | 「核心采用 dart 爬虫实现数据获取」，`lib/core/crawler/` 下有会话/配置模型 |
| [Potato-DiGua/LightTimetable-Flutter](https://github.com/Potato-DiGua/LightTimetable-Flutter) | ⭐7 | Dart | 2022-02-18 | 无 | 轻课程表 Flutter 版（已停更） |

**【证实】结论：Flutter/Dart 生态里没有成型的「教务导入 / 周次解析」库。** 上面所有带"教务导入"的项目都是**各校自己写死**的，没有可复用的通用适配层（对比 Android/Kotlin 侧有 sleepy 的 31 类协议、JS 侧有 shiguang_warehouse 的 222 校）。

#### Excel 解析（**关键**：.xls vs .xlsx）

| 包 | 最新版本 | 发布日期 | 仓库 star | License | `.xls` 支持 |
|---|---|---|---|---|---|
| [`excel`](https://pub.dev/packages/excel)（[justkawal/excel](https://github.com/justkawal/excel)） | 4.0.6 | 2024-08-20 | ⭐485 | MIT | ❌ **仅 `.xlsx`**（README 原文：library for reading, creating and updating excel-sheets for **XLSX** files） |
| [`spreadsheet_decoder`](https://pub.dev/packages/spreadsheet_decoder)（[sestegra/spreadsheet](https://github.com/sestegra/spreadsheet)） | 2.3.0 | 2024-09-09 | ⭐56 | MIT | ❌ **仅 ODS + XLSX**（README 原文：decoding and updating spreadsheets for **ODS and XLSX** files） |
| [`excel2003`](https://pub.dev/packages/excel2003)（[ubuntu2204/excel2003](https://github.com/ubuntu2204/excel2003)） | 1.0.0 | 2026-03-06 | ⭐2 | MIT | ✅ 「A simple Dart library/plugin for **reading legacy .xls** Excel files」——**但只读、star 极低、无社区验证** |
| [`excel_plus`](https://pub.dev/packages/excel_plus)（[almasumdev/excel_plus](https://github.com/almasumdev/excel_plus)） | 2.22.0 | 2026-09-18 | ⭐9 | MIT | ✅ 声称「read, create, edit and style **.xlsx** spreadsheets (and **read legacy .xls**)」，号称 `excel` 的 drop-in 替代；**是目前最活跃的选项** |
| [`syncfusion_flutter_xlsio`](https://pub.dev/packages/syncfusion_flutter_xlsio) | 34.2.9 | 2026-09-22 | （Syncfusion 官方 monorepo） | 商业授权（有社区版） | 只**写**不读 |

- **【证实】主流 Dart Excel 库都不支持 `.xls`。** 若教务系统导出的是旧版 `.xls`，需要在 `excel2003`（⭐2，小众）与 `excel_plus`（⭐9，较新）之间选，或让用户先另存为 `.xlsx` / CSV 再导入。
- **【未找到】** AHPU 导出文件究竟是 `.xls` 还是 `.xlsx`。**这是立项前必须先确认的一件事。**

---

## D. 网络与方法学备注（供后续复现）

1. **`WebSearch` 工具本环境全程失效**：每次调用都只返回 `REMINDER: You MUST include the sources above...` 而无任何结果条目，换个问法、换中英文都一样。→ 无法用搜索引擎，本报告全部依赖直接抓取 + API。
2. **`WebFetch` 被安全策略拦截**：`github.com`、`pub.dev`、`beangle.github.io` 全部报 "Unable to verify if domain is safe to fetch"。
3. **curl 直连搜索引擎失败**：`www.bing.com`（302）、`lite.duckduckgo.com`（HTTP 000）、第三方搜索代理（000）。
4. **可用的取证通道**（后续沿用）：
   - 直连学校站点：`curl -s -i http://xjwxt.ahpu.edu.cn/ahpu/localLogin.action`（**匿名可访问，无需登录**）
   - GitHub：`gh api repos/<owner>/<repo>`、`gh api repos/<owner>/<repo>/contents/<path> --jq .content | base64 -d`、`gh api search/repositories?q=...`、`gh api search/code?q=...`（`gh` 已登录 `dearKJ`，`repo` scope）
   - pub.dev：`curl -s https://pub.dev/api/packages/<name>`、`curl -s 'https://pub.dev/api/search?q=<kw>'`
5. **本机 Python 是 Windows Store 占位程序**（`/c/Users/.../WindowsApps/python3` 只返回 exit 49，静默无输出）；真正的解释器在 `/d/Python/PY_interpreter/python`；`node` 在 `/d/IDA/node_js/node`。**脚本解析请用 node**（注意 node 把 `/tmp` 解析为 `C:\tmp`，需用 Windows 绝对路径）。

---

## 附：仍待确认的问题（无法匿名解决）

1. 课表导出 Excel 的**真实文件名、扩展名（`.xls` / `.xlsx`）、表头、行语义、合并单元格情况**。
2. 课表页是否存在**服务端渲染的打印页**（`print=true` 分支在 AHPU 部署里是否可用、URL 是什么）。
3. 登录页在**连续失败后是否触发验证码**。
4. 登录后使用是否需要**校园网 / WebVPN**。
5. AHPU 的 **`unitCount` 是否确为 12**（来源是第三方注释，需实测确认）。
6. AHPU 与同族系统之间的**周次位图偏移约定**是否一致（第三方记录里 0 基与 1 基都有出现）。
