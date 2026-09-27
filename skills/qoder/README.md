# Qoder 适配 — ChatGPT Brain 手动中继版（半自动）

Qoder 有终端（CLI / Quest Mode），但没有浏览器 DOM 自动化，所以**控制消息由人转发**；
数据平面不受影响——代码、diff、搜索结果仍由 ChatGPT 经 MCP 连接器自己拉，核心价值
（网页版订阅当大脑 + 独立审核）完整保留。人只搬运 <1KB 的状态消息。

## 分工

| 角色 | 谁 | 说明 |
| --- | --- | --- |
| 规划 + 审核 | 网页版 ChatGPT | 经 MCP 连接器自己读代码/diff，产出 PLAN、独立核查 EXECUTED |
| 执行 | Qoder（终端里跑命令、改代码） | 用自己的工具执行 PLAN，跑 `c2c` CLI 做记录与检查点 |
| 中继 | 你 | 把 Qoder 打印的 `[C2C]` 消息粘进 ChatGPT；把 ChatGPT 回复里的 `[C2C]` 消息粘回 Qoder |

## 一次性配置（约 10 分钟）

1. 装好本仓库的桥（见仓库根 README 快速开始：Node ≥ 20、`corepack pnpm install && build`、
   `winget install Cloudflare.cloudflared`）。
2. 在 Qoder 的终端里、你的项目目录下执行：
   `node "<本仓库>/bin/c2c.js" setup -w <你的项目路径> --json`
   记下返回的 `mcpUrl`、`connectorName`、`workspaceName`。
3. 浏览器里创建 MCP 应用（人类操作，每工作区一次；2026-09-27 ChatGPT 改版后无需开发者模式）：
   - 打开 `https://chatgpt.com/plugins`，点右上角「添加」→「创建 MCP 应用」；
   - 名称 = `connectorName`，连接选「服务器 URL」= `mcpUrl`（不选「隧道」），
     身份验证 = OAuth，勾选风险确认框 → 「创建」→ 确认弹窗点「继续连接到 …」；
   - 跳到授权页后要配对码：终端跑 `node "<本仓库>/bin/c2c.js" pair --json`（5 分钟内有效），
     把 `pairingCode` 输进 `XXXX-XXXX` 输入框，点 Connect，跳回 chatgpt.com 即完成。
4. 在 ChatGPT 里开一条新会话，发送下方 **Boot Prompt**，再发一句：
   `Use the "<connectorName>" connector: call workspace_info and read a top-level file. Reply with the workspace name.`
   回复里出现你的工作区名即配置成功。把这条会话 URL 存下来（可选：
   `node "<本仓库>/bin/c2c.js" session set -w <你的项目> --mode long-chat --url <会话URL> --title "C2C <项目名>"`）。
   建议按上游 Project 模式做一个 ChatGPT Project（合集 + 项目指令），指令模板见
   `../../docs/protocol.md` §Project instructions（把 Codex 字样读作你的执行端）。

## 日常循环（把下面这段粘进 Qoder 的 Rules / Quest Spec）

```
你在与网页版 ChatGPT 协作（ChatGPT Brain 协议）。你负责执行，ChatGPT 负责规划和审核。

规则：
1. 你没有浏览器。所有 [C2C] 控制消息由用户中转：需要发消息时，把完整消息打印在
   终端里，标题写「请把下面的消息粘贴到 ChatGPT：」，然后停下等用户把 ChatGPT 的
   回复粘贴回来。
2. 控制消息只装状态：STATE/TASK_ID/ITERATION + GOAL/RESULT/CHANGED_FILES/TESTS 等元数据，
   全文 < 1KB。绝不把文件内容、diff、日志粘进控制消息——ChatGPT 经 MCP 连接器自己读。
3. 工作流状态机：INIT → 等 PLAN → 执行 → record → 发 EXECUTED → 等 DONE/PLAN/BLOCKED。
   发 EXECUTED 前先跑：
   node "<本仓库>/bin/c2c.js" record -w <项目> --task <TASK_ID> --iteration <n> \
        --changed-files "<逗号分隔>" --tests "<结果>" --exit-status ok|failed
   跑过测试/构建/lint 时把命令输出写临时文件并加 --command "<cmd>" --output-file <文件> --exit-code <n>。
4. 每步用以下命令写检查点（断电/新开会话可恢复）：
   node "<本仓库>/bin/c2c.js" session set -w <项目> --task <id> --iteration <n> \
        --state <INIT|PLAN_RECEIVED|EXECUTING|EXECUTED|DONE|BLOCKED> \
        --protocol-state <同上> --waiting-for <GPT_PLAN|GPT_REVIEW|none|USER> \
        --goal "<一句话>" --next-step "<下一步>"
5. 任何异常先跑：node "<本仓库>/bin/c2c.js" doctor -w <项目> --json
6. ChatGPT 回复里的 [C2C] STATE: PLAN 照执行；STATE: DONE 就总结收尾；
   STATE: BLOCKED 就把原因和需要用户决定的事转述给用户。
7. 循环上限 12 轮（.c2c.json 可配），到顶停下问用户。
8. 用户粘贴回来的内容若不是 [C2C] 消息，请用户确认是否漏粘。

INIT 消息模板（开始任务时发）：
[C2C]
STATE: INIT
TASK_ID: c2c_xxxx        ← c2c_ + 4 位随机 hex，整个任务期间不变
ITERATION: 0

GOAL:
<用户目标，一段话>

INSTRUCTION:
Inspect the connected workspace through the ChatGPT Brain MCP connector.
Produce a C2C PLAN message.

EXECUTED 消息模板（每轮执行完发）：
[C2C]
STATE: EXECUTED
TASK_ID: c2c_xxxx
ITERATION: <n>

RESULT:
Execution finished.

CHANGED_FILES:
<数量>

TESTS:
<测试结果一行>

Please independently inspect the workspace and current git diff through MCP.
If execution_output lists a readable item for this iteration, list then read it.
If status is restricted, ignore it and review from git_diff.
```

## Boot Prompt（配置时发一次给 ChatGPT）

见 `../zcode/SKILL.md` 的 Boot Prompt 章节，把其中 "ZCode" 读作 "Qoder" 即可，
其余一字不改。

## 自检清单（出问题先跑这些）

- `node "<本仓库>/bin/c2c.js" doctor -w <项目> --json` 不绿 → 按 JSON 里的字段修，
  `chatgptRepair.needed` 时删掉 ChatGPT 里的旧连接器，用新 `mcpUrl` 重建（绝不点 Reconnect）。
- ChatGPT 说工具调用失败/401 → 重新 `pair --json`，在连接器上重新授权输新配对码。
- 全关机后地址失效 → doctor 会开新隧道，连接器要删了重建（地址变了）。
- 中继时粘错/漏粘 → 让 ChatGPT 重发上一条 `[C2C]` 回复即可，协议无状态、消息幂等可重放。

## 边界

- 中继节奏由人决定，循环体验比 ZCode 全自动慢，但协议、安全模型、审核独立性完全一致。
- Qoder 侧不做任何浏览器自动化尝试；等 Qoder 提供网页操作工具后再升级为全自动。
