# WorkBuddy 适配 — ChatGPT Brain 手动中继版（办公型任务）

WorkBuddy（腾讯）是通用办公型桌面 Agent：本地文件操作强，编程能力弱。所以它接入
ChatGPT Brain 的定位是**办公型交付物**——文档、表格、汇总、PPT 大纲这类任务的
规划与审核交给网页版 ChatGPT，WorkBuddy 负责本地执行。代码类任务请用 ZCode 或
Qoder 适配层。

控制平面由人中继（WorkBuddy 不假定有网页自动化能力；若你的版本具备桌面/浏览器
操作能力，可让它自己完成「粘贴到 ChatGPT」的动作，其余流程不变——二期验证项）。
数据平面完整：ChatGPT 经 MCP 连接器自己读工作区文件，不靠人搬运内容。

## 分工

| 角色 | 谁 | 说明 |
| --- | --- | --- |
| 规划 + 审核 | 网页版 ChatGPT | 经 MCP 自己读文件/目录/git 状态，产出 PLAN、独立核查结果 |
| 执行 | WorkBuddy | 按 PLAN 在本地产出/修改交付物（文档、表格等） |
| 中继 + 代跑 CLI | 你 | 转发 <1KB 的 `[C2C]` 消息；WorkBuddy 不能稳定跑终端命令时，`c2c record/session` 由你在终端代跑 |

## 一次性配置

与 Qoder 版完全一致：装桥 → `c2c setup -w <工作区>` → 浏览器建 MCP 应用
（`chatgpt.com/plugins` →「添加」→「创建 MCP 应用」→ OAuth + 配对码，2026-09-27 改版后
无需开发者模式）→ Boot Prompt + workspace_info 验证 → 存会话/建 Project。步骤照
`../qoder/README.md` 的「一次性配置」执行即可。工作区选你放交付物的文件夹
（WorkBuddy 的产出目录），它同样会被 MCP 只读暴露给 ChatGPT。

安全提醒：MCP 桥的敏感文件默认拒绝 + `.c2cignore` 规则照常生效；把不希望 ChatGPT
看到的目录/文件名加进工作区根的 `.c2cignore`（示例见 `../../examples/c2cignore.example`）。

## 日常循环（给 WorkBuddy 的指令写法）

WorkBuddy 以对话驱动为主，把下面的要求放进任务描述或其自定义指令里：

```
你在与网页版 ChatGPT 协作（ChatGPT Brain 协议）。你负责本地执行，ChatGPT 负责规划审核。

规则：
1. 需要规划时，把下面格式的 INIT 消息打印出来（替换 GOAL），等我粘贴到 ChatGPT，
   然后把我带回来的 [C2C] STATE: PLAN 回复当作执行依据。
2. PLAN 里 ACTIONS 每一条照做；产出全部落在本地工作区内。
3. 一轮做完后，打印 EXECUTED 消息（填 CHANGED_FILES 数量与结果一行），等我粘给
   ChatGPT 审核；把我带回来的 DONE/PLAN/BLOCKED 作为结论或下一轮依据。
4. 绝不在消息里粘贴文件正文——ChatGPT 通过 MCP 连接器自己读工作区。
5. 循环到 DONE 或 BLOCKED 为止，最多 12 轮。

INIT 模板：
[C2C]
STATE: INIT
TASK_ID: c2c_xxxx
ITERATION: 0

GOAL:
<任务目标一段话>

INSTRUCTION:
Inspect the connected workspace through the ChatGPT Brain MCP connector.
Produce a C2C PLAN message.

EXECUTED 模板：
[C2C]
STATE: EXECUTED
TASK_ID: c2c_xxxx
ITERATION: <n>

RESULT:
Execution finished.

CHANGED_FILES:
<数量>

TESTS:
<不适用时写 n/a>

Please independently inspect the workspace and current git diff through MCP.
```

人类中继者补充两件事（WorkBuddy 不做）：

1. 每轮 EXECUTED 后在终端代跑记录（可选但推荐，供 ChatGPT 的 execution_summary 读取）：
   `node "<本仓库>/bin/c2c.js" record -w <工作区> --task <id> --iteration <n> --changed-files "<列表>" --exit-status ok`
2. 出任何异常：`node "<本仓库>/bin/c2c.js" doctor -w <工作区> --json`，按 Qoder 版
   README 的自检清单处理。

## Boot Prompt

与 ZCode 版相同（把 "ZCode" 读作 "WorkBuddy"），见 `../zcode/SKILL.md` 的 Boot Prompt
章节。审核类回复要求对办公型交付物同样成立：审核必须基于 MCP 拉到的实际文件内容，
不信执行端自述。

## 适配现状与二期计划

- 一期：人工中继，协议与安全模型与上游一致。
- 二期候选：验证 WorkBuddy 的桌面/浏览器操作能力，若可用则让它自动完成「向 ChatGPT
  粘贴消息、轮询回复」的控制平面动作，升级为全自动；办公场景下由 ChatGPT 产出
  交付物大纲、WorkBuddy 落地的模板化工作流。
