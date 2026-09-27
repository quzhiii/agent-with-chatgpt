---
name: chatgpt-brain
description: >
  用网页版 ChatGPT（Plus/Pro 订阅）做规划与审核大脑，ZCode 保留完整执行权。
  ChatGPT thinks. ZCode works. 当用户说 "使用 chatgpt-brain ..." / "用 ChatGPT 规划" /
  "Set up ChatGPT Brain" / "连接 ChatGPT"，或要求把 ChatGPT 接入当前工作区、
  断开 ChatGPT、或通过 ChatGPT 规划-审核循环跑一个任务时使用。
---

# ChatGPT Brain（ZCode 适配版）

ChatGPT 负责思考，ZCode 负责干活。

你（ZCode）拥有执行权：编辑、shell、git、测试、恢复。
ChatGPT 拥有高层推理：理解、规划、审核、排障策略。
C2C 桥给 ChatGPT 提供对当前工作区的只读 MCP 访问，所以你和 ChatGPT 之间的
控制消息恒小于 1 KB——ChatGPT 自己经 MCP 拉取它需要的任何数据。

协议与上游 codex-with-chatgpt 完全兼容（`docs/protocol.md`）；本文件是 ZCode 端的
操作剧本，浏览器自动化用 ZCode 的 **browser-use**（替代 Codex 内置浏览器 iab）。

## 黄金规则

1. 绝不把文件内容、diff、日志粘贴给 ChatGPT。ChatGPT 经 MCP 自己读。
2. 绝不向用户暴露技术内部（MCP、OAuth、PKCE、隧道、端口、localhost）。
   只说「连接 ChatGPT / 安全连接 / 配对」。唯一例外是下面的**手动教学配置**：
   只报用户必须填的字段名和值，不解释内部原理。
3. 配对码是唯一允许输入浏览器的凭证。绝不碰 OAuth token、cookie、session storage。
4. 出问题先跑 `c2c doctor` 并静默修复。只在登录、验证码、2FA、明确同意页或
   **手动教学配置**时打扰用户——一次只给一个动作。
   首次连接前 `c2c prefs --json`：
   - `setupMode` 缺失：原样转述 `setupChoicePrompt`，等用户回「1」或「2」，再
     `c2c prefs set --setup-mode auto|manual --json`。用户没回答前不开配置，不许猜。
   - `setupMode` 是 `manual`：跳过自动配置，直接走手动教学（是选择，不是失败）。
   - `setupMode` 是 `auto`：自动浏览器配置。同一配置步骤在修复后连续失败两次才降级手动。
     浏览器/js 超时、页面还在加载/生成、等用户登录/2FA 都不算失败。降级时不改已存的
     `setupMode`。
   `developerModeEnabled: true` 是旧版偏好，仅对设置页仍显示开发者模式开关的账号有用。
   **2026-09-27 改版后**：设置页的开发者模式开关已移除，创建 MCP 应用不再需要开发者模式，
   只需勾选风险确认框；`#settings/Security` 页若没有开关就直接跳过，不要找。
   这些偏好是本机的，不按工作区区分。重连或第二个仓库都不要再问。
5. 所有 ChatGPT 步骤一律用 ZCode 内置浏览器（browser-use，后端 `iab`），遵守下面的
   **browser-use 操作规则**。绝不做 Computer Use（截图点击），绝不启动或操控第三方
   浏览器（Chrome/Edge/…），绝不用 `open <url>` 把页面甩给外部浏览器。
   - 唯一例外：Cloudflare 登录——用户明确要用自己浏览器会话时，仅这一步可走用户浏览器。
   - 用户要求在自家浏览器跑 ChatGPT 时，礼貌拒绝并解释：「ZCode 需要持续调用 ChatGPT
     和配置连接，会频繁操作页面，可能影响你浏览器的正常使用。ChatGPT 只能跑在内置浏览器里。」
     仅当用户明确回复「我愿意承担影响」才放行，否则每次都维持内置浏览器。
6. 会话复用只看 `c2c session --json` → `conversation.mode`（见会话管理），不许自创模式。
   - **long-chat**（旧会话文件，或用户明确退出 Project）：每工作区一条 ChatGPT 长对话，
     绝不悄悄开新会话。
   - **project**（新工作区默认）：每工作区一个 ChatGPT Project 合集。同一条 ZCode 会话
     复用本会话里存下的 chat URL；新的 ZCode 会话从合集页开新聊天——绝不 `goto`
     `https://chatgpt.com/` 去新建，也绝仅仅因为 `session.url` 存在就复用别的会话的 URL。
   每个工作区只有一个 ChatGPT 连接器，不为同一工作区建第二个。别的工作区有自己的
   连接器——绝不碰。
7. **browser-use 只能主 agent 用**。绝不把浏览器操作委托给子代理（Explore /
   general-purpose 等）；浏览器工作必须由主 agent 亲自完成。
8. ChatGPT 页面只去**固定 URL 清单**里的地址。绝不从 chatgpt.com 首页开始点菜单。
9. **Doctor 门禁。** `c2c doctor --json` 之后，本地不绿就不得 `goto` ChatGPT、不得发
   `[C2C]`——`chatgptRepair.needed` 为 true 时的重连设置页除外。不绿的情形：
   - `report.bridge.ok` 不是 true
   - `report.mcp.ok` 不是 true（本地未鉴权 `/mcp` 必须是 401）
   - state 目录写入失败（EPERM）
   - 本工作区曾有公网地址而现在隧道断了
   - `chatgptRepair.needed` 为 true（先修连接器，再跑 doctor）
   - `namedRepair.needed` 为 true（用户需登录 Cloudflare，然后重跑 doctor。
     不要删连接器——地址没变）
   - `report.bridge` 说 状态无法确认：本地桥可能还活着。不要 `c2c start`，不要删连接器，
     不要当成 `chatgptRepair`。等一等再跑 doctor。
   doctor 已绿且 `chatgptRepair.needed` 为 false 时，不要 `c2c restart`、不要开第二条
   隧道、不要删连接器。ChatGPT/浏览器侧的报错不是折腾公网地址的理由。
   发出消息之后 ChatGPT 侧 401 是另一回事：那时再修，且不构成下次跳过门禁的理由。

## browser-use 操作规则（ChatGPT 页面）

官方 skill：`browser-use:control-browser`。做任何浏览器工作前按它的规则来；
本节规则覆盖其默认行为（不关标签页、不藏窗口、不在设置页干等）。

1. **每次调用都是新内核。** 每个用浏览器的 `mcp__node_repl__js` 调用开头都要重新
   bootstrap（读 `ZCODE_PLUGIN_ROOT` → `setupBrowserRuntime`），再
   `const browser = await agent.browsers.get("iab")`。首次调用按 control-browser 的要求
   `nodeRepl.write(await browser.documentation())` 读一次完整 API 文档；之后不必重读。
2. **标签页恢复协议。** 新内核里没有旧变量。每个逻辑操作批次开始时，先单独一次 js 调用
   返回完整 `await browser.tabs.list()`，按 URL 匹配 chatgpt.com 的标签页，下一次调用再
   `browser.tabs.get(id)` 拿可操作对象。绝不凭记忆直接用 tab id，绝不按数组位置挑。
   列表为空再 `browser.user.openTabs()`，最后才新建。全流程只用这一个 ChatGPT 标签页，
   换页面用 `tab.goto(...)`，已经在该页就不重复 `goto`。
3. **前台 + 标记。** 打开或认领标签页后让它保持前台可见（用户要能看到首配和聊天）。
   按 control-browser 文档的 `finalize({ keep })` 用法，在每轮开始和结束时把该标签页
   标记为 `handoff`（首配成功或 C2C 聊天已打开后标 `deliverable`）。绝不关闭它；
   等待、超时、任务结束都保持标记（standby），不许默认清理把它关掉。
4. **只去这些 URL**（同一标签页，`goto`——绝不翻菜单）：
   - 插件页（创建/删除 MCP 应用的唯一入口）: `https://chatgpt.com/plugins`
   - 新对话（仅 long-chat 且无存档时）: `https://chatgpt.com/`
   - 已存 C2C 会话: `conversation.chatUrl` / `session.url`
   - 已存 Project 合集: `conversation.projectUrl`（`https://chatgpt.com/g/g-p-…/project`）
   **2026-09-27 改版**：旧直达 URL
   `chatgpt.com/plugins#settings/Connectors?create-connector=true&redirectAfter=%2Fplugins`
   已失效（只会重定向到设置页），创建改走页面内按钮：插件页主区「**添加**」按钮 →
   菜单「**创建 MCP 应用**」。设置页的开发者模式开关已移除，无需先开。
   绝不点已有连接器上的 Reconnect / Refresh。旧地址已死，那页会卡在
   "This site cannot be reached"。地址变化时：只删本工作区 `connectorName` 的 MCP 应用，
   再按上面按钮流程重建（同名、新 Server URL）。Project 指令里绝不写公网地址，只写
   连接器**名**。
5. **不在设置页等 8 个工具**。显示 Connected / 授权成功 / 配对通过就继续；工具确认
   留到会话里用 `workspace_info` 做。
6. **批量操作。** 熟悉的表单尽量在一个 js 调用里填完（Playwright 批量）。每个动作后
   做一次廉价 DOM 检查。绝不截图轮询。
7. **定位一律从快照出发。** `await tab.playwright.domSnapshot()` 是读页面的唯一依据；
   从快照事实构造 `getByRole/getByText/...` 定位器，绝不猜选择器。实测要点：
   - 聊天输入框：新对话页是 textbox「询问 ChatGPT」（会话内同名）。`fill(消息)` 后
     **按 Enter 只会换行、不会发送**——必须点「**发送**」按钮。发送成功的判定标准：
     消息文本出现在会话历史（快照出现「你说：」+ 文本），输入框清空。
   - Chat/Work 模式切换器：composer 上方「撰写器模式」组里的「聊天 / 工作」两个按钮，
     「聊天」带 `[pressed]` 标记即正确。
   - 下拉菜单（如「添加」）渲染在 DOM 末尾的 `menu` 浮层里，不在按钮附近；按
     `menuitem` 角色定位。
   - 自定义勾选框（如风险确认）：`check()` 可能报 did not change state，改用
     `locator('input[type="checkbox"]').evaluate("el=>el.click()")` 底层点击。
8. **一条会话，Chat 模式。** 第一条 ChatGPT 会话就是 C2C 会话。Chat（聊天）和
   Work（工作）是分开的：Work 会话变不成 Chat。每个新会话里，若能看到 Chat/Work
   切换器（常在左上），先确认选的是 **Chat**；是 Work 就换新 Chat 会话（HANDOFF）。
   看不到切换器就不翻菜单，直接继续。Boot prompt 和 workspace_info 检查都发在这条
   Chat 会话里。回复点名当前工作区之后才允许保存会话 URL；校验失败就保留旧 URL。
   合集页或会话页只剩 `Retry / 重试` 是导航错误，不是生成也不是配对失败：同一标签页
   Retry 一次；还不行就 `goto` 本会话最后可用的聊天 URL（或 `session.url`），点页面上的
   `打开…项目` 链接（同站跳转允许）。旧存档 URL/检查点在替换会话通过 workspace_info
   前不丢。不 `session clear`。
9. **等回复（不挂长等待）。** 发出 INIT / EXECUTED / boot / workspace_info 检查后：
   标记 handoff、保持前台、留在本任务里。不许一次 `waitFor` 五分钟，不许截图轮询。
   每 20–30 秒做一次廉价 DOM 快照检查：
   - 还在生成 → 继续等（不输入、不重发）；「生成中」的判定：快照有「停止」按钮或
     「正在生成」状态。
   - `STATE: PLAN` / `DONE` / `BLOCKED` / 校验用的工作区名 → 读到后按协议继续；
   - 可见报错 → 修复，不开新会话。
   浏览器/js 超时不是失败：认领同一标签页、读页面、保持 standby。ChatGPT 还在想就继续
   轮询。绝不开第二个标签页，绝不因为等待超时就重发 INIT/EXECUTED。
10. **弹窗超出视口就调高视口。** 「新建插件」弹窗高约 1000px，默认 720px 视口下「创建」
   按钮在视口外且 `scrollIntoView` 会被重置（click 报 outside-viewport）。先
   `await tab.setViewportSize({ width: 1280, height: 1700 })` 再操作。

## 位置与命令

- 本仓库（ChatGPT Brain checkout）位于：`<ACTUAL_CHECKOUT_PATH>`
  （安装/更新脚本必须把安装副本里的这一行替换为用户实际路径。）
- CLI：`<checkout>` 指上一行的路径；跑 `node "<checkout>/bin/c2c.js" <command>`
  （全局链接过则直接 `c2c <command>`）。所有命令支持 `--json` 解析。
- 仓库里没有 `node_modules` 或 `dist/` 时，先在其中跑
  `corepack pnpm install && corepack pnpm build`。
- 作用于用户项目的命令（`setup`、`doctor`、`session`、`restart`、`start`、`stop`、
  `status`、`pair`、`unpair`、`logs`、`workspace`、`record`、`tunnel status`、
  `tunnel choose`）要传 `-w <workspace root>`（用户正在做的项目，不是本仓库）。
- 机器级命令不加 `-w`：`update-check`、`sandbox-allow`、`prefs`、`tunnel login`。
  它们对多余的 `-w` 会忽略，误传不致失败。
- Windows（Git Bash）下路径含空格时给 `node` 的参数整体加引号。

## 每个工作流开始前

按顺序跑这两条（都便宜/有缓存；有更新才对用户提）：

1. `c2c update-check --json`（不带 `-w`）。本仓库是 fork：没有配 `origin` 远端时它会
   静默跳过（`updateAvailable: false` 或 checked: false），照常继续，不要提。若某天
   提示有新版本，先 `git pull --ff-only`，拉不到新提交说明是上游桥有更新、需要仓库
   维护者同步——对用户说一句「上游工具有新版本，我先继续你的任务」，不阻塞。
2. `c2c sandbox-allow --json`（不带 `-w`）。它把 C2C 状态目录写进
   `%USERPROFILE%\.codex\config.toml` 的白名单（Windows 状态目录
   `%LOCALAPPDATA%\codex-with-chatgpt`）。ZCode 没有 Codex 沙箱，但保留这一步能让
   `doctor` 的 sandbox 检查保持绿；已白名单时是幂等 no-op，不触发提权。

## 工作流：更新

在本仓库目录内：

1. `git pull --ff-only`（有本地改动导致失败时：`git stash && git pull --ff-only`）。
2. `corepack pnpm install && corepack pnpm build`。
3. 重装 Skill：把 `skills/zcode/SKILL.md` 复制到
   `~/.zcode/skills/chatgpt-brain/SKILL.md`，并把副本里「位于：`<ACTUAL_CHECKOUT_PATH>`」
   一行改成实际路径。
4. `c2c sandbox-allow --json`，再 `c2c restart -w <workspace>` 让桥跑上新代码。
5. 告诉用户「✓ 已更新到最新版本」，然后继续触发更新的原任务。
   （更新后的 SKILL.md 从下个 ZCode 会话生效，属预期。）

## 连接选择（每工作区一次）

在公网地址产生之前问（`c2c setup` / 首个会开隧道的 `doctor --fix`）。不提隧道、
wrangler、DNS、域名解析，只说 临时地址 / 固定域名 / 登录 Cloudflare。

1. `c2c tunnel status -w <workspace> --json`
2. `needsChoice` 为 false 就不再问。
3. `needsChoice` 为 true：原样转述 `userPrompt` 并等待。
   - 没有账号 / 没有域名 / 临时 / 不用 → `c2c tunnel choose -w <ws> --mode quick --json`
   - 有域名（如 example.com）→ 先转述 `loginPrompt`，再
     `c2c tunnel choose -w <ws> --mode named --zone <domain> --json`。
     这一步可能开用户自己的浏览器（黄金规则 5 的 Cloudflare 例外）。等命令跑完。
     说是有账号但没给域名：再问一次域名。返回 `need: "zone"` 就再问一次重试。
     `fallback: true` 时：转述 `userMessage`，改用临时地址继续。用户没主动要求不再试 named。
4. 连接凭证绝不放进项目。CLI 存在 C2C 状态目录。

## 工作流：首次配置（「使用 chatgpt-brain 完成首次配置」）

1. 自检前置：`node --version`（≥ 20）、`cloudflared` 是否存在。
   Windows 缺 cloudflared 就跑 `winget install Cloudflare.cloudflared`；macOS 用
   `brew install cloudflared`。自己做，不问。
2. 本仓库没有 `node_modules` 就先 `corepack pnpm install && corepack pnpm build`。
3. 跑 `c2c sandbox-allow --json`，然后**连接选择**，然后
   `c2c setup -w <workspace> --json`
   → 返回 `{ mcpUrl, pairingCode, workspaceName, connectorName, ... }`。
   `connectorName` 是本工作区的连接器标题（新仓库为 `ChatGPT Brain · <名字>`；老装
   置保持其已存名）。配对码约 5 分钟过期。不要提前铸造：等 ChatGPT 授权/配对表单
   上屏再 `c2c pair --json` 并立刻输入。doctor 不会预铸配对码。
4. `c2c prefs --json`（本机级，不分工作区）。
   - `setupMode` 为 null：原样转述 `setupChoicePrompt`，等「1」或「2」，再
     `c2c prefs set --setup-mode auto|manual`。回答前不开 ChatGPT 设置、不开始自动配置，
     不默认 auto。
   - 之后要切换：同一条 `c2c prefs set --setup-mode`。换工作区或重连不重问。
   - `setupMode: "manual"`：跳过第 5 步自动配置，直接走**手动教学配置**（选择的）。
     开场白：`接下来用手动教学配置。一次只需要做一个操作。` 不说「自动配置没有成功」。
   - `setupMode: "auto"`：继续第 5 步，保留两次失败降级。
5. 在唯一一个 iab 标签页上打开 ChatGPT（见 **browser-use 操作规则**）。前台 + 标记
   handoff。登录墙处理：内置浏览器里 **Google OAuth 会被 Google 风控拦截**（报
   「此浏览器或应用可能不安全」）——改走「**继续使用电子邮件地址**」+ 邮箱验证码登录
   （验证码发到用户邮箱，请用户查收并输入）；或请用户给账号设密码后用密码登录。
   登录后：
   - 已有同名 `connectorName`：`https://chatgpt.com/plugins` — 在主区找到它的卡片删掉
     （绝不 Reconnect）。
   - 没有 / 刚删：`https://chatgpt.com/plugins` → 点主区「**添加**」按钮 → 菜单点
     「**创建 MCP 应用**」，弹窗里只操作第 3 步返回的 `connectorName`：
      - 同名已存在：删掉再建。绝不 Reconnect，绝不原地编辑，绝不开旧 Server URL。
      - 不存在：用该准确名字新建。
      - 绝不改名、删除、编辑属于其他工作区的 MCP 应用。
      - 名称：`connectorName`；描述：
        `Securely connect ChatGPT to the current agent workspace for planning and review.`
      - 连接：选「服务器 URL」，填第 3 步的 `mcpUrl`（不要选「隧道」）
      - 身份验证：OAuth（默认已选中；「高级 OAuth 设置」变为可用即说明 ChatGPT 已自动
        发现桥的 OAuth 元数据，不要动它）
      - 勾选「我已了解，并希望继续」风险确认框（自定义勾选框，用底层 click，见 §7）
     弹窗超过视口高度时先调高视口（§10）。点「创建」后表单全部变禁用属正常
     （ChatGPT 正在连接验证），等它换成「连接 …」确认弹窗 → 点「继续连接到 …」→
     跳到桥的授权页（scope 清单 + `XXXX-XXXX` 配对码框）。此时才 `c2c pair --json`
     并填码，点 **Connect**。成功后自动跳回 chatgpt.com——不等 8 个工具。
6. 同标签页按**会话管理**打开第一条 C2C 会话（新工作区走 Project 合集；仅 long-chat
   才 `https://chatgpt.com/`）。按 **browser-use 操作规则** §8 确认 Chat 模式（是 Work
   就换新 Chat 会话）。发送下方 **Boot Prompt**，然后（同一会话）发：
   `Use the "<connectorName>" connector: call workspace_info and read a hello-style top-level file. Reply with the workspace name.`
   按 §9 等回复确认工作区名匹配 `workspaceName`。匹配才 `c2c session set` 存会话 URL
   （见会话管理）。不匹配就不存。标记 deliverable。
7. 按下面格式汇报（不提内部名词）：

```
ChatGPT Brain

✓ 当前项目已识别
✓ 安全桥接已启动
✓ 安全连接已建立
✓ ChatGPT 已连接
✓ 文件读取测试通过

Ready.
```

出现登录墙（ChatGPT、Cloudflare）时停下，告诉用户那**一件**事
（「请登录 ChatGPT，完成后告诉我『好了』」），然后继续。

### 手动教学配置

进入条件：`setupMode` 是 `manual`（一开始选的），或自动配置在 `c2c doctor` / 修复后
在同一明确的设置/重连步骤连败两次。浏览器/js 超时且无可见报错、页面还在加载/生成、
正在等登录 / 2FA / 验证码——这些不算失败，不进此路径。主动选的手动路径不等两次失败。

停止自动操作 ChatGPT 设置。保留当前本地 C2C 状态和当前 `mcpUrl`、`pairingCode`、
`workspaceName`、`connectorName`。不许悄悄降级成 ZCode 单干，也不许永久停用 C2C。
失败降级时改已存的 `setupMode`。

开场白：

- 主动选（`setupMode: "manual"`）：`接下来用手动教学配置。一次只需要做一个操作。`
- 失败降级：`自动配置没有成功，我来带你手动完成。一次只需要做一个操作。`

然后一次只带一个动作，等用户说「好了」再做下一个：

1. `developerModeEnabled` 不是 true：请用户打开 `https://chatgpt.com/#settings/Security`
   开「开发人员模式」。听到「好了」后 `c2c prefs set --developer-mode`。已记住则跳过。
2. 请用户打开 `https://chatgpt.com/plugins`。若有准确的 `connectorName` 的卡片，只删这一个。
   别的工作区的 MCP 应用绝不提。
3. 请用户点主区「添加」→「创建 MCP 应用」，创建准确的 `connectorName`：
   - 描述：`Securely connect ChatGPT to the current agent workspace for planning and review.`
   - 连接：选「服务器 URL」，填当前 `mcpUrl`（不要选「隧道」）
   - 身份验证：OAuth；勾选「我已了解，并希望继续」→ 点「创建」→ 确认弹窗点
     「继续连接到 …」
4. 请用户 Connect / Authorize。然后 `c2c pair --json`，只把配对码给用户。过期就重跑
   `pair` 给新码。
5. 用户报告 Connected / 已授权 / 配对通过后，回到正常设置/重连流程的 ChatGPT 校验步。
   自动浏览器校验若在同一明确步骤再败两次，停下并如实报告失败步骤；不无限循环，
   不在没有 C2C 的情况下继续。

## 会话管理

`c2c session -w <ws> --json` → `{ session, conversation }`。`conversation.mode` 是唯一
开关。缺文件 / 带聊天 URL 无 Project 的旧文件保持 **long-chat**，不劝迁移；用户想用
Project 就跑 **Bind Project**。全新工作区（无 session 文件）默认 **project**。

绝不按显示名匹配 Project 或会话。绝不上传仓库到 Project sources。绝不点 分享 / Share。
不改 ChatGPT 会话名。

### long-chat（不改这条路径）

每工作区一条 ChatGPT 长对话。

- **找它**：`conversation.reuseSavedChat` 且有 `conversation.chatUrl` 时，`goto` 该 URL
  （前台 + handoff）就地继续。
- **存它**：boot + workspace_info 通过且回复点名本工作区后，
  `c2c session set -w <ws> --mode long-chat --url <url> --title "C2C <workspace name>"`。
  名字不匹配就不覆盖旧 URL。
- **更新它**：每轮 EXECUTED/DONE 后
  `c2c session set -w <ws> --task <id> --iteration <n> --state <STATE>`
  加编码工作流的检查点旗标（`--protocol-state`、`--waiting-for`、`--goal`、
  `--next-step`、`--known-issues`，DONE 时 `--clear-checkpoint`）。这些字段不放日志和 diff。
- **换会话**仅当 (a) 用户要求、(b) 当前会话明显卡钝、(c) 当前是 Work 会话：
  1. 同一 iab 标签页 `goto` `https://chatgpt.com/`，确认 Chat 模式，发 boot prompt。
  2. 发 HANDOFF（见 `docs/protocol.md`）——目标、进度、状态、问题、下一步。绝不贴文件。
  3. workspace_info 检查；过了才 `c2c session set --url`。失败就保留旧 URL。
- 存档会话 404：按换会话处理。HANDOFF 从 `session.checkpoint`（goal、progress、issues、
  next step）重建；无检查点就用 `task` / `iteration` / `lastState` 与 `execution_summary`
  的元数据。绝不贴日志或输出正文。

### project（新工作区默认）

每工作区一个 ChatGPT Project。映射：

1. 同一条 ZCode 会话（本线程还有上下文）→ 同一 ChatGPT 聊天 URL，直接 `goto`。
   不先开合集页。
2. 同一工作区、**新的** ZCode 会话 → 从合集页（`conversation.projectUrl`）开新聊天。
   忽略 `session.url`，除非你已在本 ZCode 会话里存过它。
3. 不同工作区 → 不同 Project、不同连接器。

**在本 ZCode 会话里打开聊天**

- 本 ZCode 会话已存过聊天 URL：`goto` 该 URL 继续。不开新聊天，不发 HANDOFF。
- 否则 `conversation.projectReady`：`goto` `conversation.projectUrl`。在合集页用页面上的
  输入框（「{项目名}中的新聊天」 / "New chat in …"）开新聊天。不用侧栏，不 `goto`
  `https://chatgpt.com/`。确认 Chat 模式。发 boot prompt，再用**准确的**
  `connectorName` 做 workspace_info。回复点名本工作区后
  `c2c session set -w <ws> --mode project --project-url <collection> --url <chat> --connector-name "<connectorName>" --title "C2C <workspace name>"`。
  本 ZCode 会话若在续做之前的 C2C 任务，boot prompt 之后立刻发 HANDOFF。
- 否则先 **Bind Project**。

**更新它**：同 long-chat 的 `c2c session set --task / --iteration / --state`。

**合集不对**：不猜别的 Project。告诉用户期望的工作区名，请他打开正确合集后说「已找到」；
同时提供「继续用长对话」选项，选了就 `c2c session set -w <ws> --mode long-chat` 走
long-chat 路径。合集 404 或新聊天不在 Project 里：同样二选一。

**存档聊天 404**（本会话）：`goto` 合集页，在 Project 里开新聊天，boot + 从
`session.checkpoint` 重建的 HANDOFF（无日志）+ workspace_info，名字匹配后存新 URL。
保留 `--project-url`。

### Bind Project（用户建一次合集）

新工作区首次配置时做；老用户想换 Project 时也做。**不**点 ChatGPT 侧栏建 Project
（禁 Computer Use；iab 不翻菜单）。

1. 原样告诉用户（填入工作区名）：

```
请在 ChatGPT 里新建一个项目，名字用「<workspaceName>」，记忆请选「仅限项目记忆」。

如果侧栏里看不到「项目」：把鼠标放在「聊天」上，点右边出现的三个点，选择「按项目整理」。

建好后会打开合集页面。看到页面后跟我说「好了」。
```

2. 等「好了」/合集页出现。同一 iab 标签页读地址栏：必须是
   `https://chatgpt.com/g/g-p-…/project` 形态；不是就让用户开到形态对为止。然后：
   `c2c session set -w <ws> --mode project --project-url <url> --connector-name "<connectorName>"`。
3. 还在合集页：右上角 **… → 项目设置**。不点 分享，不加 来源 / 文件。
   - 记忆：仅限项目记忆。库访问权限保持关闭。
   - 指令：粘贴下方 **Project 指令**（`{{…}}` 从 `workspace_info` / setup 取值；
     连接器名用 setup 返回的准确 `connectorName`）。绝不把公网/临时地址写进指令。
   保存并关闭设置。
4. 还在合集页，用页面输入框开第一条聊天，然后按 setup 第 6 步做 boot + workspace_info，
   存聊天 URL。

### Project 指令（粘贴到 项目设置 → 指令）

```
You are the planning and review layer for one local workspace. ZCode executes.

This Project is bound only to:
- Workspace name: {{workspace_name}}
- Kind: {{project_type}} ({{languages}} / {{frameworks}})
- Connector (use this one only): {{connector_name}}

When you call tools, use ONLY that connector. Do not use any other
ChatGPT Brain connector. If workspace_info names a different
workspace, stop. Do not plan. Do not use this Project's memory.

Read code, git, diffs, and any released command output through that
connector. Never ask anyone to paste file bodies, diffs, or logs. After
EXECUTED, call execution_output (list, then read) when a readable item
exists; if status is restricted, review from git instead. Never upload
the repo into this Project's files or sources.

When facts conflict, trust this order:
1. Current code from the connector
2. A HANDOFF in this chat (this task's goal, progress, next step)
3. These instructions
4. This Project's memory (durable architecture only; stale memory loses)

This Project's memory is only for this workspace. On HANDOFF, trust the
brief, re-read code through the connector, and resume at NEXT_EXPECTED_STEP.

Be substantive: why, which file, what to test. No empty one-liners and
no 40-step epics. Use C2C control messages.
```

## 工作流：编码任务（「使用 chatgpt-brain 完成 XXX」）

发给 ChatGPT 的协议状态：INIT → PLAN → EXECUTING → EXECUTED → REVIEW → (PLAN | DONE | BLOCKED)。
本地检查点状态（只在 session，绝不作为 ChatGPT 的 `STATE:` 行）：
`INIT`、`PLAN_RECEIVED`、`EXECUTING`、`EXECUTED_LOCAL`、`EXECUTED_SENT`、`DONE`、`BLOCKED`。
没有 `STATE: RESUME`。原会话丢了就发 HANDOFF。
所有控制消息以 `[C2C]` 开头。ZCode→ChatGPT 消息保持 1 KB 以内。ChatGPT 的回复应当有
实质内容（见第 3 步）。协议文档：`docs/protocol.md`。

0. `c2c tunnel status -w <workspace> --json`。`needsChoice` 就先走**连接选择**（老装置
   问一次然后记住）。然后 `c2c doctor -w <workspace> --json`（自动修复）。**Doctor 门禁：**
   本地不绿不开 ChatGPT、不发 INIT。`namedRepair.needed`：转述 `namedRepair.userMessage`，
   `c2c tunnel login --json`（用户浏览器；Cloudflare 例外），再 doctor。
   `chatgptRepair.needed`：转述 `chatgptRepair.userMessage`（一段话，无内部名词），走
   **重连工作流**，doctor 复绿才继续。
   生成任务号：`c2c_` + 4 位随机 hex——除非检查点已有任务号（复用，不许另铸）。
1. `c2c session -w <workspace> --json`。按**会话管理**的 `conversation.mode` 在同一 iab
   标签页打开 ChatGPT（前台 + handoff）。long-chat：存档会话，没有就 `https://chatgpt.com/`。
   project：本会话的聊天 URL；没有就从合集页开新聊天；`projectReady` 为 false 先
   **Bind Project**。新会话先确认 Chat 模式，再发 **Boot Prompt** 和 workspace_info
   检查（点名准确 `connectorName`）。回复点名当前工作区后才存会话 URL。不用浏览器去
   读 MCP 已能提供的数据。控制消息发出后按 §9 等回复。

   **发 INIT 之前先看 `session.checkpoint` 恢复。** 无检查点（旧 session）就按正常新/
   续循环走。浏览器/js 超时不是丢任务——认领原标签页；不许因为等待超时就 INIT、重跑、
   重发 EXECUTED。
   - `EXECUTED_SENT` + `waitingFor=GPT_REVIEW`：不许 INIT、不许重跑、不许重发
     EXECUTED。留在存档会话等审核。该会话 404：从检查点字段（无日志）发 HANDOFF，然后等。
   - `EXECUTED_LOCAL`：本地已完成；只发 EXECUTED（本轮没记录就先 record）。不许重跑。
   - `EXECUTING`：未完成。还留着 PLAN 就继续执行当前 PLAN；没有就 HANDOFF 并请
     ChatGPT 重述上一份 PLAN。不许当已完成，不许 INIT 新任务。
   - `PLAN_RECEIVED`：执行那份 PLAN。不许 INIT。
   - `INIT` / `waitingFor=GPT_PLAN`：认领标签页等待。不许重发 INIT。
   - `DONE`：需要就向用户总结；`c2c session set --clear-checkpoint`。
   - `BLOCKED`：如实转述 ChatGPT 的原因；不许 INIT。
   绝不为恢复而重新配对、重建连接器、重写 Project 指令。
2. 发 INIT（带用户目标；检查点说不发就跳过）：

```
[C2C]
STATE: INIT
TASK_ID: c2c_f81a
ITERATION: 0

GOAL:
<user's goal, one paragraph>

INSTRUCTION:
Inspect the connected workspace through the ChatGPT Brain MCP connector.
Produce a C2C PLAN message.
```

   一次廉价 DOM 检查确认 INIT 已可见地出现在该 ChatGPT 会话里。页面只剩 Retry 就先按
   §8 恢复。消息可见前不写等待检查点、不等 PLAN。然后：
   `c2c session set -w <ws> --task <id> --iteration 0 --state INIT --protocol-state INIT --waiting-for GPT_PLAN --goal "<short goal>" --next-step "wait for PLAN"`
3. 等 ChatGPT 的 `STATE: PLAN` 回复（§9——同标签页短快照检查；5 分钟浏览器超时不算失败）。
   读 GOAL/ACTIONS/TESTS/SUCCESS_CRITERIA。好的 PLAN 还应带 RATIONALE 和具体的自然语言
   改法建议（哪个文件、改什么、为什么）。只有一句空话没有理由和文件级指引时，追问一次：
   "Please expand the plan with rationale and concrete per-file suggestions."
   然后：`c2c session set -w <ws> --protocol-state PLAN_RECEIVED --waiting-for none --next-step "execute PLAN"`
4. 你自己用自己的工具执行 PLAN（你的判断；ChatGPT 不微管理工具调用）。
   开工前：
   `c2c session set -w <ws> --protocol-state EXECUTING --waiting-for none --next-step "finish PLAN then record"`
5. 记录执行，供 ChatGPT 经 MCP 读。元数据必有：
   `c2c record -w <ws> --task c2c_f81a --iteration 1 --changed-files "src/a.ts,src/b.ts" --tests "27 passed" --exit-status ok`
   本轮跑过**测试 / 构建 / lint / 类型检查**命令时，把该命令输出也带上。stdout/stderr
   先写本地临时文件，然后：
   `c2c record … --command "pnpm test" --output-file <temp> --exit-code <n>`
   成功失败都记。绝不记 shell 历史、`.env`、密钥或无关转储。绝不把该文件（或任何日志）
   粘给 ChatGPT。CLI 说输出未放行也照发 EXECUTED；ChatGPT 会从 git 审。然后：
   `c2c session set -w <ws> --iteration 1 --state EXECUTED --protocol-state EXECUTED_LOCAL --waiting-for none --next-step "send EXECUTED"`
6. 发 EXECUTED（无 diff、无日志）。让 ChatGPT 用 MCP，包括有可读项时的 `execution_output`：

```
[C2C]
STATE: EXECUTED
TASK_ID: c2c_f81a
ITERATION: 1

RESULT:
Execution finished.

CHANGED_FILES:
4

TESTS:
27 passed

Please independently inspect the workspace and current git diff through MCP.
If execution_output lists a readable item for this iteration, list then read it.
If status is restricted, ignore it and review from git_diff.
```

   然后：
   `c2c session set -w <ws> --protocol-state EXECUTED_SENT --waiting-for GPT_REVIEW --next-step "wait for PLAN or DONE"`
7. ChatGPT 经 MCP（`git_diff`、`read_file`、`test_status`、`execution_output`）审核，
   回 DONE / PLAN（下一轮）/ BLOCKED。
8. 循环。尊重 maxIterations（`.c2c.json`，默认 12）。到顶暂停问用户：
   「已完成 12 轮协作，仍有未解决问题，是否继续？」
9. DONE：用大白话向用户总结结果。
   `c2c session set -w <ws> --state DONE --clear-checkpoint`
10. BLOCKED：读 ChatGPT 的原因，能修就修，否则把用户必须拍板的那**一个**决定端上来。
    `c2c session set -w <ws> --protocol-state BLOCKED --waiting-for USER --known-issues "<short reason>"`

## Boot Prompt（每条新 C2C 会话开头发一次）

```
You are the planning and review layer of a local coding/working session.

ZCode owns execution.
You own high-level reasoning, planning and review.

You have access to the current local workspace through the
"ChatGPT Brain" MCP connector.

Rules:

1. Do not ask ZCode to paste files that are available through MCP.
2. Inspect only the files needed for the task.
3. Use MCP to inspect current code, git status and diff.
4. Produce concise executable plans.
5. ZCode will execute your plan using its own harness.
6. After ZCode reports EXECUTED, independently inspect the diff.
   If execution_output lists a readable item for this iteration, list
   then read it. If status is restricted, ignore the body and review
   from git.
7. Do not assume an implementation succeeded just because ZCode says so.
8. Continue until the implementation satisfies the success criteria.
9. Avoid unnecessary rewrites.
10. Return C2C structured control messages.
11. Be substantive. PLAN and review replies must carry enough signal for
    ZCode to act on: rationale, per-file natural-language suggestions
    (which file, what to change and why), risks worth checking, and test
    advice. Never reply with a bare one-liner. Substance over length —
    but do not generate 40-step epics either.
12. If you receive a HANDOFF message, this conversation continues an
    existing task. Trust the handoff brief for history, re-read any code
    you need through MCP, and resume from NEXT_EXPECTED_STEP.
13. If this chat sits in a ChatGPT Project, use only the connector named
    in that Project's instructions. Do not use another workspace's connector.
```

## 工作流：断开（「断开 ChatGPT」）

1. `c2c unpair -w <workspace>`（立即吊销全部 token）。
2. 可选：同一 iab 标签页经 `https://chatgpt.com/plugins` 删连接器（前台 + handoff）。
   只动本工作区的 `connectorName`。
3. 告诉用户：「已断开 ChatGPT 对该项目的访问。」

## 工作流：地址失效后重连（全关掉以后）

用户退出 ZCode / 终端 / 关机后的常态：旧公网地址没了。doctor 已开了新地址。
`connectorAction: "update"` 的意思是删了重建——不是 Reconnect。

`c2c doctor --json` 会形如：
`{ "chatgptRepair": { "needed": true, "connectorAction": "update", "connectorName": "...", "userMessage": "...", "mcpUrl": "...", "pages": { ... } } }`

1. 原样转述 `chatgptRepair.userMessage`。然后你来修。除非出现登录墙，不要让用户点
   ChatGPT。修复完成且复查 doctor 绿之前，不开 C2C 会话、不发 `[C2C]`。绝不「先发条
   消息试试」。复用 `c2c prefs --json`，不重问 setup mode。`setupMode` 是 `manual` 就走
   **手动教学配置**（主动选）而不是自动操作。
2. 与 setup 同一个 iab 标签页（前台 + handoff）。Connected 之前只去插件页——不翻菜单：
   - 插件页（创建/删除入口）: `https://chatgpt.com/plugins`
3. 只操作 `chatgptRepair.connectorName`。绝不碰别的 MCP 应用。
   - 插件页里同名卡片还在：**删除**。ChatGPT 要确认就确认。旧卡片上绝不点 Reconnect、
     Refresh、Connect、Edit——旧 Server URL 已死，页面会卡在 "This site cannot be reached"。
   - 然后「**添加**」→「**创建 MCP 应用**」，用**同一个** `connectorName` 重建
     （不许造第二个名字）：
      - 描述：`Securely connect ChatGPT to the current agent workspace for planning and review.`
      - 连接：选「服务器 URL」，填 `chatgptRepair.mcpUrl`（不要选「隧道」）
      - 身份验证：OAuth；勾风险确认框 → 「创建」→「继续连接到 …」
     跳到桥的授权页后 `c2c pair --json` 并填码，点 Connect。成功跳回即继续，
     不在设置页等 8 个工具。
   - 名字已不在：跳过删除直接建。
4. 再跑 `c2c doctor --json`。门禁绿了才在同一标签页重开本 ZCode 会话已在用的聊天
   （`session.url` / 本会话早先存的 URL）。不重写 Project 指令——里面存的是连接器
   **名**，没变。同一会话发 setup 第 6 步的 workspace_info 检查（准确 `connectorName`）。
   doctor 绿不够：旧会话可能还绑着被删的连接器。
   - 回复点名本工作区：就地继续。需要就存 URL。
   - workspace_info 失败/超时/读不到名：不反复重试旧 URL。project → 合集页在 Project
     里开新聊天，boot + 从 `session.checkpoint` 重建的 HANDOFF（无日志）+ workspace_info，
     名字匹配后才 `c2c session set --url`。long-chat → 会话管理换会话，同样检查。旧
     存档 URL 保留到新会话通过为止。
5. ChatGPT 会话丢了：同第 4 步失败路径。不重新上传文件（工作区在 MCP 里）。工具指向
   错连接器时，开 项目设置 确认 指令 仍写着 `connectorName`（绝不粘新公网地址）。

## 工作流：修复（看起来哪儿不对）

1. `c2c doctor -w <workspace> --json`。门禁：本地不绿不开 ChatGPT / 不发 `[C2C]`，
   重连设置页除外。
2. `namedRepair.needed`：转述 `namedRepair.userMessage`，`c2c tunnel login --json`，再 doctor。
   不删连接器。
3. `chatgptRepair.needed`：走**地址失效后重连**，再 doctor。
4. 其余按恢复映射表。只有登录 / 2FA / 验证码才打扰用户——一次一个动作。

## 恢复映射表

| 症状 | 动作 |
| --- | --- |
| 桥没在跑 | `c2c start`（doctor 会自动做） |
| 隧道死了 / URL 不可达 / 全关后连接失效 | `c2c doctor` → `namedRepair.needed` 就登录 Cloudflare 再 doctor（不删）。`chatgptRepair.needed` 就转述给用户，然后只删本工作区连接器（`connectorName`）重建。绝不 Reconnect。重建后在存档会话里复查 `workspace_info`；仍失败就在同一 Project 开新聊天（或 long-chat 换会话）+ HANDOFF。 |
| 合集页只剩 Retry | 同一 iab 标签页：Retry 一次，然后开最后可用的聊天、点其 Project 链接。消息可见前不写 INIT/EXECUTED 等待检查点。 |
| ChatGPT 说工具调用失败 / 401 | token 过期或被吊销 → 重新配对（新配对码 + 授权） |
| 配对码被拒/过期 | `c2c pair --json` 取新码 |
| 同一明确设置/重连步骤修复后连败两次 | 停止自动操作 ChatGPT 设置，改走**手动教学配置**。浏览器/js 超时、加载/生成中、等登录/2FA 不算失败。 |
| 端口冲突 | 自动处理；不告诉用户 |
| 每条新会话都「修复」 / 状态目录写不进 | `c2c sandbox-allow --json`（一次）。不问用户。 |
| 旧创建 URL 重定向到设置页 | 2026-09-27 改版：直达 URL 已失效。走 `https://chatgpt.com/plugins` →「添加」→「创建 MCP 应用」按钮流程（见 setup 第 5 步）。 |
| 缺 cloudflared | 自己装再重试。winget 安装可能被 UAC 弹窗拦掉（退出码 1602）：改从官方 GitHub release 下载单文件 `cloudflared-windows-amd64.exe` 到 `~/bin`，写用户 PATH 并设 `C2C_CLOUDFLARED_PATH` 指向它（c2c 的 detect 会读该环境变量）。 |
| 侧栏没有「项目」 | 请用户把鼠标放在「聊天」上，点 …，选「按项目整理」 |
| 合集页是错误的 Project | 请用户打开指名合集说「已找到」，或接受 long-chat |

## ZCode 环境备注

- **权限模式**：跑配置和编码任务需要能执行 shell 命令与浏览器的模式；plan 模式下只读，
  不要在此 skill 上启动。用户会看到 `c2c` 命令与浏览器操作的批准提示，属预期，
  提前一句话说明即可。
- **browser-use 仅主 agent**：control-browser 规定子代理不得加载或使用浏览器。所有
  ChatGPT 页面操作由主 agent 亲自完成，不派子代理。
- **全新内核**：每次 `mcp__node_repl__js` 调用后变量清零；严格按 **browser-use 操作
  规则** §1–§2 做 bootstrap 与标签页恢复，不缓存 tab 对象。
