---
name: chatgpt-brain
description: >
  把网页版 ChatGPT（Plus/Pro 订阅）接入本地 AI 编程/办公 Agent 当「规划与审核大脑」：
  ChatGPT 负责理解、规划、独立审核，本地 Agent 保留完整执行权。仓库不上传、
  不需要 OpenAI API Key、不消耗 API 额度。当用户想用 ChatGPT 规划或审核任务、
  把 ChatGPT 接入当前工作区，或提到 ChatGPT Brain / C2C 时使用。
---

# ChatGPT Brain

**ChatGPT 负责思考，你的本地 Agent 负责干活。**

你已经在为 ChatGPT Plus/Pro 付费。这个 skill 让网页版 ChatGPT 成为本地 AI Agent
的「大脑」：ChatGPT 做理解、规划、**独立审核**；你的本地 Agent（ZCode / Qoder /
WorkBuddy / Codex 等）保留完整执行权。规划与审核所需的代码、diff、文件，ChatGPT
通过官方「连接器」功能从你本地**只读**拉取——仓库不上传、不需要 OpenAI API Key、
不消耗 API 额度。

```
        网页版 ChatGPT（你已有的 Plus/Pro 订阅）
        理解 · 规划 · 独立审核
         │               ▲
控制平面  │ <1KB 状态消息  │ 数据平面
（浏览器  │  [C2C] 协议    │ ChatGPT 经官方连接器
 自动化） ▼               │ 只读拉取代码/diff
        本地桥 c2c（127.0.0.1 + OAuth 2.1 + 隧道）
        9 个只读 MCP 工具，写操作在服务端不存在
```

## 为什么值得装

1. **订阅复用，不烧 API**：走你已有的 ChatGPT 网页订阅，不需要 API Key，
   不产生 API 账单。
2. **独立审核，不信口头汇报**：Agent 每完成一轮，ChatGPT 自己经只读连接器拉取
   git diff 逐项核查，而不是听 Agent 说「我做完了」。
3. **代码不出本机**：仓库绝不上传；ChatGPT 经加密隧道只读拉取，桥接服务里
   写/删/执行工具根本不存在，prompt injection 无从下手。

## 它是怎么工作的

任务循环：`INIT`（目标）→ `PLAN`（ChatGPT 出有限、具体、可执行的计划）→
本地 Agent 执行 → `EXECUTED`（只上报元数据：改了几个文件、测试结果）→
ChatGPT 拉取 diff 独立核查 → `PLAN`（下一轮）/ `DONE` / `BLOCKED`。

## 安装与使用

前置：Node.js ≥ 20、Git、ChatGPT Plus/Pro 订阅。

1. 克隆并安装桥接服务（仓库含各平台安装脚本）：

   ```bash
   git clone https://github.com/quzhiii/agent-with-chatgpt.git && cd agent-with-chatgpt
   powershell -ExecutionPolicy Bypass -File install\install-zcode.ps1   # Windows
   bash install/install-zcode.sh                                        # macOS / Linux
   ```

2. 重开会话后，对你的 Agent 说：**「用 chatgpt-brain 完成首次配置」**——它会装缺的
   依赖、启动本地桥、带你在 ChatGPT 里完成一次性连接器配置（登录/验证码/配对码
   一次只要求一个动作）。
3. 之后对你的 Agent 说：**「使用 chatgpt-brain 完成 XXX」**，进入规划-执行-审核循环。

各端（ZCode / Qoder / WorkBuddy）的完整操作剧本、协议文档与故障排查见仓库：
<https://github.com/quzhiii/agent-with-chatgpt>

## 安全模型

- 桥只绑 127.0.0.1，公网仅经 Cloudflare 加密隧道暴露；OAuth 2.1 + PKCE +
  一次性配对码（5 分钟过期、限 5 次尝试）。
- MCP 服务端只有 9 个只读工具；敏感文件默认拒绝，执行输出经本地脱敏门控，
  token 只存 SHA-256 哈希。
- 凭证全部存在系统应用状态目录，绝不进项目目录。

## 适用边界

- 需要 ChatGPT Plus/Pro 订阅（连接器是订阅功能）。
- chatgpt.com 页面改版可能影响自动定位；适配层只用 DOM 快照定位，坏了可按
  仓库的 troubleshooting 指南修复。

## 来源与协议

本 skill fork 自开源项目 [XiaoDuoYa/codex-with-chatgpt](https://github.com/XiaoDuoYa/codex-with-chatgpt)
（MIT，5.2k+ stars），在其本地桥接服务基础上新增多端适配层，**保持开源、免费**，
同样以 [MIT](https://github.com/quzhiii/agent-with-chatgpt/blob/main/LICENSE) 协议发布。
感谢上游作者与贡献者。非官方社区项目，与 OpenAI 无隶属或背书。
