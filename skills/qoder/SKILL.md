---
name: chatgpt-brain
description: >
  用网页版 ChatGPT（Plus/Pro 订阅）做规划与审核大脑，Qoder 保留完整执行权。
  ChatGPT thinks. Qoder works. 当用户说 "使用 chatgpt-brain ..." / "用 ChatGPT 规划" /
  "Set up ChatGPT Brain" / "连接 ChatGPT"，或要求把 ChatGPT 接入当前工作区、断开连接、
  或通过 ChatGPT 规划-审核循环跑一个任务时使用。浏览器自动化用 Qoder 内置
  browser-use MCP 工具（navigate_page / take_snapshot / fill / click）。
---

# ChatGPT Brain（Qoder 全自动适配版）

ChatGPT 负责思考，Qoder 负责干活。

你（Qoder）拥有执行权：编辑、shell、git、测试、恢复。
ChatGPT 拥有高层推理：理解、规划、独立审核。
C2C 桥给 ChatGPT 提供对当前工作区的只读 MCP 访问，所以你和 ChatGPT 之间的控制消息
恒小于 1 KB——ChatGPT 自己经 MCP 拉取它需要的任何数据。协议全文见
`<ACTUAL_CHECKOUT_PATH>/docs/protocol.md`；本文件是 Qoder 端的操作剧本。

## 黄金规则

1. 绝不把文件内容、diff、日志粘贴给 ChatGPT。ChatGPT 经 MCP 连接器自己读。
2. 绝不向用户暴露技术内部（MCP、OAuth、PKCE、隧道、端口、localhost）。只说
   「连接 ChatGPT / 安全连接 / 配对」。
3. 配对码是唯一允许输入浏览器的凭证。绝不碰 OAuth token、cookie、session storage。
4. 出问题先跑 `c2c doctor` 并静默修复。只在登录、验证码、2FA 或需要人工建/删
   MCP 应用时打扰用户——一次只给一个动作。
5. 所有 ChatGPT 页面操作用 Qoder 内置 **browser-use** MCP 工具（见下面的工具映射）。
   不做截图轮询（本协议用 DOM 快照轮询；且本机 browser-use 截图不可用）。
6. 会话复用只看 `c2c session --json` → `conversation.mode`。**long-chat**（当前默认）：
   每工作区一条 ChatGPT 长对话，绝不悄悄开新会话。每工作区只有一个 MCP 应用。
7. ChatGPT 页面只去本文件列出的 URL。绝不从首页点菜单探索。
8. **Doctor 门禁。** `c2c doctor -w <workspace> --json` 之后，本地不绿就不得打开
   ChatGPT、不得发 `[C2C]`。`chatgptRepair.needed` 为 true 时不许自行修连接器——
   转述给用户并进入中继降级（见「修复与降级」），等用户处理完再复查 doctor。

## 工具映射（browser-use MCP）

| 需求 | 工具 |
| --- | --- |
| 打开/跳转页面 | `navigate_page`（先 `list_pages`/`select_page` 管理页面） |
| 读页面（唯一依据） | `take_snapshot`（DOM/ARIA 快照） |
| 填聊天输入框 / 表单 | `fill`（目标引用来自最新快照） |
| 点「发送」/ 按钮 | `click` |
| 按键兜底 | `press_key` |
| 定向等待/检查 | `wait_for`、`evaluate_script`（后者会改页面状态，慎用） |

参数名以你自己的工具 schema 为准（读工具描述），本文件只规定流程与纪律。
禁用项：`take_screenshot`（本机不可用且协议不需要）、`drag`/`hover`（用不到）、
`upload_file`（绝不向 ChatGPT 上传文件）。

## 浏览器纪律

1. **快照是定位的唯一依据。** 每次读取用 `take_snapshot`；从快照里的角色/可见文本/
   元素引用构造 `fill`/`click` 目标，绝不猜选择器。导航后、动作后都重新快照确认。
2. **单页面。** 只维护一个 ChatGPT 页面，换地址用 `navigate_page`，已在目标页就不重复跳。
3. **聊天输入框**是页面主 textbox（新对话页占位符「询问 ChatGPT」，会话内同名）。
   `fill(消息)` 后 **按 Enter 可能只换行**——必须点「**发送**」按钮。发送成功的判定：
   消息文本出现在会话历史（快照出现「你说：」+ 文本）。
4. **Chat/Work 模式**：composer 上方「撰写器模式」组，「聊天」带选中标记才继续；
   是「工作」就换新 Chat 会话（发 HANDOFF）。
5. **等回复（不挂长等待）。** 发出任何消息后，每 20–30 秒一次 `take_snapshot` 检查：
   - 生成中（有「停止」按钮或「正在生成」状态）→ 继续等，不输入不重发；
   - `STATE: PLAN` / `DONE` / `BLOCKED` → 读到后按协议继续；
   - 可见报错 → 修复，不开新会话。
   超时不是失败：重取快照、继续轮询。绝不开第二个页面，绝不因超时重发消息。
6. **只去这些 URL**：
   - 已存 C2C 会话: `c2c session --json` 里的 `conversation.chatUrl`（日常循环入口）
   - 插件页（仅排查时看，不自动操作）: `https://chatgpt.com/plugins`
   出现登录墙：停下，请用户处理（见「首次引导」），一次一个动作。

## 位置与命令

- 本仓库位于 `<ACTUAL_CHECKOUT_PATH>`（安装副本已回填实际路径）。
- CLI：`node "<ACTUAL_CHECKOUT_PATH>/bin/c2c.js" <command>`（下称 c2c）。作用于用户项目
  的命令加 `-w <workspace>`；机器级命令（`update-check`、`sandbox-allow`、`prefs`）不加。
- 仓库没有 `node_modules` 或 `dist/` 时先在里面跑
  `corepack pnpm install && corepack pnpm build`。

## 工作流：日常任务（「使用 chatgpt-brain 完成 XXX」）

协议状态：INIT → PLAN → EXECUTING → EXECUTED → REVIEW → (PLAN | DONE | BLOCKED)。
本地检查点（只进 `c2c session set`，绝不作为 ChatGPT 的 STATE 行）：`INIT`、
`PLAN_RECEIVED`、`EXECUTING`、`EXECUTED_LOCAL`、`EXECUTED_SENT`、`DONE`、`BLOCKED`。
没有 `STATE: RESUME`，会话丢了就发 HANDOFF。

0. **权限前置检查（先于一切）。** 本 skill 需要反复执行桥命令（`node "<checkout>/bin/c2c.js" ...`）。
   若会话处于自动权限模式，分类器可能把 c2c 命令判定为「与任务无关」直接拦截（不弹窗）。
   第一次被拦时：不要重试超过一次；立即停下告知用户——「自动模式的分类器拦了桥命令，
   请把会话权限模式切到“每条命令询问”（或信任模式），切完回复“好了”」，等用户切换后再继续。
   用户明确不愿切模式时，改走「中继降级」并如实说明（中继仍需用户在终端代跑 c2c record）。
   然后跑 `c2c doctor -w <workspace> --json`（自动修复）。门禁不绿按黄金规则 8 处理。
   任务号：`c2c_` + 4 位随机十六进制；已有检查点则复用，不许另铸。
1. `c2c session -w <workspace> --json` 取 `conversation.chatUrl`。`browser-use` 打开该
   URL，`take_snapshot` 确认会话加载（看得到历史消息与输入框）。**先查检查点恢复**
   （`session.checkpoint`）：`EXECUTED_SENT` 就只等审核；`EXECUTED_LOCAL` 只发 EXECUTED；
   `PLAN_RECEIVED` 直接执行；`DONE` 清检查点收尾；`BLOCKED` 转述原因。无检查点才发新 INIT。
2. 发 INIT（fill + 点「发送」，确认消息可见后写检查点）：

```
[C2C]
STATE: INIT
TASK_ID: c2c_xxxx
ITERATION: 0

GOAL:
<用户的目标，一段话>

INSTRUCTION:
Inspect the connected workspace through the ChatGPT Brain MCP connector.
Produce a C2C PLAN message.
```

   然后：`c2c session set -w <ws> --task <id> --iteration 0 --state INIT --protocol-state INIT --waiting-for GPT_PLAN --goal "<一句话>" --next-step "wait for PLAN"`
3. 轮询等 `STATE: PLAN`。读 GOAL/ACTIONS/TESTS/SUCCESS_CRITERIA；只有一句空话时追问一次
   "Please expand the plan with rationale and concrete per-file suggestions."
   然后：`c2c session set -w <ws> --protocol-state PLAN_RECEIVED --waiting-for none --next-step "execute PLAN"`
4. 你用自己的工具执行 PLAN（ChatGPT 不微管理工具调用）。开工前写检查点
   `--protocol-state EXECUTING --next-step "finish PLAN then record"`。
5. 记录执行（元数据必有）：
   `c2c record -w <ws> --task <id> --iteration <n> --changed-files "<逗号分隔>" --tests "<结果>" --exit-status ok|failed`
   本轮跑过测试/构建/lint/类型检查时，把 stdout/stderr 先写本地临时文件，再加
   `--command "<cmd>" --output-file <临时文件> --exit-code <n>`。成功失败都记。
   绝不记录 shell 历史、`.env`、密钥。然后检查点
   `--protocol-state EXECUTED_LOCAL --next-step "send EXECUTED"`。
6. 发 EXECUTED（无 diff、无日志）：

```
[C2C]
STATE: EXECUTED
TASK_ID: c2c_xxxx
ITERATION: <n>

RESULT:
Execution finished.

CHANGED_FILES:
<数量>

TESTS:
<一行结果>

Please independently inspect the workspace and current git diff through MCP.
If execution_output lists a readable item for this iteration, list then read it.
If status is restricted, ignore it and review from git_diff.
```

   检查点：`--protocol-state EXECUTED_SENT --waiting-for GPT_REVIEW`。
7. 轮询等审核结论。DONE → 用大白话向用户总结 +
   `c2c session set -w <ws> --state DONE --clear-checkpoint`；
   PLAN → 回到第 4 步，iteration 递增；BLOCKED → 转述 ChatGPT 的原因和需要用户拍板的
   那一个决定，`c2c session set -w <ws> --protocol-state BLOCKED --waiting-for USER`。
8. 循环上限 12 轮（`.c2c.json` 可配），到顶停下问用户是否继续。

## 首次引导（每工作区一次，人工协作）

全自动剧本**不**自动创建 MCP 应用。用户照 `<ACTUAL_CHECKOUT_PATH>/skills/qoder/README.md`
的「一次性配置」执行（浏览器人工操作：插件页「添加 → 创建 MCP 应用」→ OAuth → 配对码，
2026-09-27 改版后无需开发者模式）。你只负责：跑 `c2c setup` 给出 `mcpUrl`/`connectorName`、
在配对码表单上屏时跑 `c2c pair --json` 把码给用户、配置完成后发 Boot Prompt +
workspace_info 验证、`c2c session set` 存会话 URL。Boot Prompt：

```
You are the planning and review layer of a local coding/working session.

Qoder owns execution.
You own high-level reasoning, planning and review.

You have access to the current local workspace through the
"ChatGPT Brain" MCP connector.

Rules:

1. Do not ask Qoder to paste files that are available through MCP.
2. Inspect only the files needed for the task.
3. Use MCP to inspect current code, git status and diff.
4. Produce concise executable plans.
5. Qoder will execute your plan using its own harness.
6. After Qoder reports EXECUTED, independently inspect the diff.
   If execution_output lists a readable item for this iteration, list
   then read it. If status is restricted, ignore the body and review
   from git.
7. Do not assume an implementation succeeded just because Qoder says so.
8. Continue until the implementation satisfies the success criteria.
9. Avoid unnecessary rewrites.
10. Return C2C structured control messages.
11. Be substantive. PLAN and review replies must carry enough signal for
    Qoder to act on: rationale, per-file natural-language suggestions,
    risks worth checking, and test advice. Never reply with a bare one-liner.
12. If you receive a HANDOFF message, this conversation continues an
    existing task. Trust the handoff brief for history, re-read any code
    you need through MCP, and resume from NEXT_EXPECTED_STEP.
13. If this chat sits in a ChatGPT Project, use only the connector named
    in that Project's instructions.
```

workspace_info 验证（同一会话发送）：
`Use the "<connectorName>" connector: call workspace_info and read a hello-style top-level file. Reply with the workspace name.`
回复点名工作区后才 `c2c session set` 存 URL。

## 修复与降级

| 症状 | 动作 |
| --- | --- |
| 桥没在跑 | `c2c start`（doctor 会自动做） |
| `chatgptRepair.needed` / 隧道地址变了 | 不自行修。转述 doctor 的 `userMessage`，请用户在浏览器里删旧 MCP 应用重建（README「一次性配置」步骤 3），完成后重跑 doctor。期间可切换中继降级继续干活。 |
| ChatGPT 说工具调用失败 / 401 | 重新配对：`c2c pair --json` 把新码给用户，请用户在 MCP 应用的授权里重新输入 |
| 页面登录墙（本 browser 会话未登录） | 停下请用户处理登录；若该 browser 会话无法持久登录（headless 每次丢失），如实报告并切换中继降级 |
| 会话 404 / 只剩 Retry | `navigate_page` 回已存 URL 重试一次；仍坏就发 HANDOFF 到新 Chat 会话（boot prompt + HANDOFF + workspace_info），通过后 `c2c session set --url` 换存 |
| 配对码过期 | `c2c pair --json` 取新码 |

**中继降级（任何时候可用）**：你没有浏览器可用时，回退为打印 `[C2C]` 消息让用户转发
（消息模板与铁律见 `<ACTUAL_CHECKOUT_PATH>/skills/qoder/README.md`），数据平面照常工作。
如实告知用户当前处于中继模式。
