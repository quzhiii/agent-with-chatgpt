# 适配矩阵 与 与上游的差异清单

更新时间 2026-09-27（端到端实测通过后），基于上游 v0.1.3（commit 9663b88）。

## 一、三端适配矩阵

| 能力 | ZCode | Qoder | WorkBuddy | Codex（上游） |
| --- | --- | --- | --- | --- |
| 数据平面（只读 MCP 桥 + OAuth + 隧道） | ✅ | ✅ | ✅ | ✅ |
| 控制平面（浏览器自动传 [C2C] 消息） | ✅ browser-use（iab） | ❌ 人工中继 | ❌ 人工中继（二期验证桌面能力） | ✅ 内置浏览器 iab |
| 协议状态机 / 检查点 / HANDOFF | ✅ | ✅ | ✅ | ✅ |
| 执行记录 + 脱敏输出 | ✅ | ✅ | ⚠️ CLI 由人代跑 | ✅ |
| 自动装 skill | `~/.zcode/skills/chatgpt-brain/` | 粘进 Rules / Quest Spec | 放任务描述 / 自定义指令 | `~/.codex/skills/codex-with-chatgpt/` |
| 适配文档 | skills/zcode/SKILL.md | skills/qoder/README.md | skills/workbuddy/README.md | skill/SKILL.md |

降级策略：全自动端遇浏览器自动化不可用（如 chatgpt.com 人机验证、内置浏览器被限制）时，
临时切到该端的手动中继流程，协议不变；反之手动端若获得网页操作工具，可升级为全自动。

## 二、与上游的差异清单（本仓库改动登记）

原则（AGENTS.md 规则 1）：`src/` 只做最小必要改动，全部登记于此。

| # | 文件 | 改动 | 原因 | 上游合并冲突风险 |
| --- | --- | --- | --- | --- |
| 1 | `src/version.ts` | `PRODUCT_NAME`: "Codex with ChatGPT" → "ChatGPT Brain" | 品牌独立（CLI 横幅、OAuth 资源名、MCP serverInfo） | 低（单行常量） |
| 2 | `src/config/endpoint.ts` | `DEFAULT_CONNECTOR_NAME`: → "ChatGPT Brain" | 新工作区连接器名随品牌（老装置保留已存名，向后兼容） | 低（单行常量） |
| 3 | `src/cli/index.ts` | program description 标语；`setup` 兜底连接器名改用常量；`record` 帮助文本；setup 提示语去 Codex 化 | 展示层去品牌残留 | 低（字符串行） |
| 4 | `src/mcp/server.ts` | `test_status` / `execution_summary` / `execution_output` 三个工具描述中 "Codex" → "local agent" | ChatGPT 看到的工具描述应指向「执行端」而非特定产品 | 低（字符串行） |
| 5 | `src/auth/oauth.ts` | OAuth 授权页 scope 描述与配对页提示中 "Codex" → "your local agent" | 配对页是用户可见 UI | 低（字符串行） |
| 6 | `tests/endpoint.test.ts` | 两条断言同步：老装置保留原名的断言改为字面量 "Codex with ChatGPT"（ documenting 向后兼容），新工作区命名断言改为 "ChatGPT Brain · Landing" | 与 #1/#2 对齐；178 测试全绿 | 低 |
| 7 | `README.md` / `README.zh-CN.md` | 移至 `docs/upstream-readme/`，重写为多 agent 定位 | 品牌与定位 | 无（纯新增/移动） |
| 8 | 新增 `skills/`、`install/`、`docs/adapter-matrix.md`、治理文件 | 本项目主体增量 | — | 无（纯新增） |
| 9 | `skills/zcode/SKILL.md` 相对上游 `skill/SKILL.md` 的有意分歧（2026-09-27 端到端实测后定稿） | ChatGPT 线上 UI 改版适配：①旧直达 URL `plugins#settings/Connectors?create-connector=true` 失效（重定向到设置页），创建改走插件页「添加 → 创建 MCP 应用」按钮流程；②设置页开发者模式开关已移除，创建无需开发者模式，只勾风险确认框；③聊天输入框 Enter 只换行，必须点「发送」按钮；④「新建插件」弹窗超 720px 视口，需 `setViewportSize` 调高；⑤内置浏览器 Google OAuth 被 Google 风控拦截，登录走邮箱验证码路线；⑥browser-use 新内核 bootstrap/标签页恢复协议替换 Codex iab 规则 | 适配层职责（不动 `src/`，上游 `skill/SKILL.md` 保留供 Codex） | 无（纯适配层） |
| 10 | `install/install-zcode.ps1` cloudflared 兜底 | winget 安装会触发 UAC（无人值守时被拒，退出码 1602）；脚本改为优先从官方 GitHub release 下载单文件到 `~/bin` 并写 `C2C_CLOUDFLARED_PATH` 用户环境变量（c2c detect.ts 读该变量） | 免提权安装 | 无（纯新增） |

**不改的**（保持上游可合并 + 行为兼容）：CLI 命令名 `c2c`、协议标记 `[C2C]`、状态目录
`codex-with-chatgpt`、`skill/SKILL.md`（原 Codex 版）、协议文档 `docs/protocol.md`、
全部桥接逻辑与安全模型。`update-check` 查 `origin` 远端——fork 未配 origin 时静默跳过，
无副作用；上游同步由维护者经 `upstream` remote 做（fetch + merge，冲突时保上游桥逻辑）。

## 三、上游同步操作手册（维护者）

```bash
git fetch upstream
git merge upstream/main        # 冲突预计只出现在 §二 表格列出的字符串行
corepack pnpm install && corepack pnpm build && corepack pnpm test
# 过后检查上游是否新增了 [C2C] 协议字段 / 新 CLI 命令：
#   有 → 同步 skills/zcode/SKILL.md 与两份手动中继 README 的对应段落
```
