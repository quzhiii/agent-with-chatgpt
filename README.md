# ChatGPT Brain — 网页版 ChatGPT 当大脑，本地 Agent 当手脚

ChatGPT thinks. Your local agent works.

简体中文 · [English](README.en.md)

本项目把网页版 ChatGPT（你已付费的 Plus/Pro 订阅）接入本地 AI 编程/办公 Agent：
ChatGPT 负责理解、规划、**独立审核**；本地 Agent 负责执行。规划与审核所需的一切
代码、diff、文件，ChatGPT 通过官方「连接器」功能从你本地只读拉取——仓库不上传、
不需要 OpenAI API Key、不消耗 API 额度。

fork 自 [XiaoDuoYa/codex-with-chatgpt](https://github.com/XiaoDuoYa/codex-with-chatgpt)
（MIT，5.2k+ stars），原样保留其经过 178 个测试的本地桥接服务，在其上新增三端适配层：

| 本地 Agent | 适配档次 | 说明 |
| --- | --- | --- |
| **ZCode** | ✅ 全自动 | browser-use 驱动内置浏览器传消息、轮询回复，体验与上游 Codex 版一致。见 [skills/zcode](skills/zcode/SKILL.md) |
| **Qoder** | 🔁 手动中继 | Qoder 跑终端与命令，人只转发 <1KB 状态消息。见 [skills/qoder](skills/qoder/README.md) |
| **WorkBuddy** | 🔁 手动中继 | 办公型交付物（文档/表格）场景。见 [skills/workbuddy](skills/workbuddy/README.md) |
| Codex（上游原版） | ✅ 全自动 | 原版 Skill 原样保留。见 [skill/](skill/SKILL.md) |

## 工作原理（双平面）

```
            网页版 ChatGPT（Plus/Pro）
            理解 · 规划 · 独立审核
             │               ▲
   控制平面  │ <1KB 状态消息  │ 数据平面
   （浏览器  │  [C2C] 协议    │ ChatGPT 经官方连接器
    自动化） ▼               │ 只读拉取代码/diff
            本地桥 c2c（127.0.0.1 + OAuth 2.1 + Cloudflare 隧道）
            9 个只读 MCP 工具，写操作在服务端不存在
             │
            本地 Agent：编辑 · shell · git · 测试
```

任务循环：`INIT`（目标）→ `PLAN`（ChatGPT 出有限、具体、可执行的计划）→ 执行 →
`EXECUTED`（只有元数据）→ ChatGPT **不信口头汇报，自己拉 diff 独立核查** →
`PLAN`（下一轮）/ `DONE` / `BLOCKED`。协议全文见 [docs/protocol.md](docs/protocol.md)。

## 快速开始（ZCode）

前置：Node.js ≥ 20、Git；ChatGPT Plus/Pro 订阅。

```bash
git clone https://github.com/quzhiii/agent-with-chatgpt.git && cd agent-with-chatgpt
powershell -ExecutionPolicy Bypass -File install\install-zcode.ps1   # Windows
bash install/install-zcode.sh                                        # macOS / Linux
```

然后：

1. 重开一个 ZCode 会话；
2. 在**你的项目目录**下对 ZCode 说：**「用 chatgpt-brain 完成首次配置」**——它会自动
   装缺的依赖（cloudflared）、起桥、开浏览器带你在 ChatGPT 建连接器（登录/2FA/输配对码
   时一次只要求你做一个动作）；
3. 之后对你的 Agent 说：**「使用 chatgpt-brain 完成 XXX」**，进入规划-执行-审核循环。

Qoder / WorkBuddy 的接入与日常循环见各自适配文档（需要你在浏览器完成一次性连接器配置，
之后人只中转状态消息）。

## 安全模型

- **只读 by construction**：MCP 服务端只有 9 个只读工具（读文件、搜索、git 状态/diff、
  执行记录），任何写/删/执行工具不存在，prompt injection 也开不出来。
- 桥只绑 127.0.0.1，公网仅经 Cloudflare 隧道暴露；OAuth 2.1 + PKCE + 一次性配对码
  （5 分钟 TTL、5 次尝试）。
- realpath 路径围栏 + 敏感文件默认拒绝 + `.c2cignore`；执行输出经本地脱敏门控
  （私钥整体拒绝、token 打码、截断）；token 只存 SHA-256 哈希。
- 凭证全部存在系统应用状态目录，绝不进项目目录。详见 [docs/security.md](docs/security.md)。

## 致谢与来源

本项目 fork 自 [XiaoDuoYa/codex-with-chatgpt](https://github.com/XiaoDuoYa/codex-with-chatgpt)
（MIT，5.2k+ stars），在此感谢上游作者与全部贡献者。

- **来自上游的**：`src/` 本地桥接服务（C2C CLI、只读 MCP、OAuth、隧道）——与上游保持
  最小差异（产品名等展示字符串），完整差异清单见 [docs/adapter-matrix.md](docs/adapter-matrix.md)；
  `upstream` remote 可持续同步上游更新。
- **本项目新增的**：ZCode / Qoder / WorkBuddy 三端适配层（[skills/](skills/)）、
  SkillHub 发布版 skill（[skills/skillhub](skills/skillhub/SKILL.md)）、安装脚本与多端文档。
- 上游原 README 存档：[docs/upstream-readme/](docs/upstream-readme/)。

## 许可证

[MIT](LICENSE)。与上游一致，本项目保持开源、免费使用。
`src/` 桥接服务版权归 codex-with-chatgpt 上游作者及贡献者所有；三端适配层与
SkillHub 发布版归本项目贡献者所有。

> 非官方社区项目，与 OpenAI 无隶属或背书。ChatGPT 连接器是官方功能；请遵守相应服务条款。

## 边界

| 事项 | 说明 |
| --- | --- |
| 需要 ChatGPT Plus/Pro | 连接器/开发者模式是订阅功能；无订阅可先装桥，实测待账号 |
| chatgpt.com 页面改版 | 可能影响自动定位；适配层只用 DOM 快照定位，坏了按 troubleshooting 修 |
| 不上传仓库 | ChatGPT 经隧道只读拉取；绝不把仓库传到 ChatGPT 文件/来源 |
| 手动中继的节奏 | Qoder/WorkBuddy 端由人控制发消息节奏，慢但协议与审核独立性不打折 |
