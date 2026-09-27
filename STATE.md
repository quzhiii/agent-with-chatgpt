# STATE — agent-with-chatgpt 当前状态

更新时间 2026-09-27（**端到端实测通过**，一期全部完成）

## 已完成

- 上游调研（报告存档 `参考文档-codex-with-chatgpt/调研报告.md`）：双平面架构、9 个只读 MCP 工具、[C2C] 协议状态机、c2c CLI、安全模型、三端可移植性
- Clone 上游 XiaoDuoYa/codex-with-chatgpt v0.1.3（commit 9663b88），remote 命名 upstream；popnie fork 确认为上游未改动镜像
- 治理文件（AGENTS/BRIEF/TASK/STATE）；工作区 AGENTS.md 子项目地图已登记本子项目
- 品牌化最小改造（PRODUCT_NAME / 连接器名 → "ChatGPT Brain"，CLI / MCP 描述 / OAuth 页去 Codex 化），**178/178 测试全绿**；全部差异登记 `docs/adapter-matrix.md`
- 三端适配层：`skills/zcode/SKILL.md`（browser-use 全自动）、`skills/qoder/`、`skills/workbuddy/`（手动中继）
- 安装脚本 ps1/sh（cloudflared 免提权兜底：官方 release 下载到 `~/bin` + `C2C_CLOUDFLARED_PATH`）；skill 已装 `~/.zcode/skills/chatgpt-brain/`
- 本地验证：PoC 全链路（401 → OAuth → 配对 → 9 工具 → .env 拒绝）+ doctor 全绿
- **端到端实测（2026-09-27，全部走通）**：
  - 环境：cloudflared 2026.9.3（官方 exe）、quick 隧道、`c2c setup` 起桥
  - ChatGPT 侧：iab 登录（Google OAuth 被 webview 风控拦，**改用邮箱验证码路线成功**）→ 插件页「添加 → 创建 MCP 应用」（旧直达 URL 已失效；无需开发者模式，勾风险确认框）→ OAuth 授权 + 配对码 → **workspace_info 读到 agent-with-chatgpt**
  - 完整循环：INIT → ChatGPT 经 MCP 读 git 状态产出 PLAN → 执行（创建 docs/e2e-test-note.md）→ `c2c record` → EXECUTED → ChatGPT 独立审核（read_file 逐字节比对 + execution_output 检查 + 确认无其他文件变动）→ **STATE: DONE**，四项验收全 PASS
  - 会话已存（long-chat，记录在本机 c2c 状态目录，URL 不写入仓库）
  - 实测经验全部回写 `skills/zcode/SKILL.md`（§4 新入口、§7 发送按钮/勾选框、§9 生成判定、§10 视口调高、登录降级、恢复映射表 2 行）并登记差异清单 #9/#10

## 待用户完成

- 本仓库 git commit（按工作区规则不主动提交；含新增适配层 + 8 处品牌化改动 + 本次实测回写）；后续可加 origin 远端发布
- 可选升级：ChatGPT Project 模式（Bind Project：用户建合集 + 项目指令，见 SKILL.md 会话管理节）；固定域名隧道（Cloudflare 登录，地址不再变化）
- 日常使用：任意项目目录下对 ZCode 说「使用 chatgpt-brain 完成 XXX」即可进入规划-执行-审核循环

## 未开始

- 二期：WorkBuddy 桌面/浏览器自动化能力验证；Qoder 网页操作工具出现后的适配升级
- 二期候选：非 cloudflared 隧道；Qoder/WorkBuddy 端安装自动化

## 阻塞

（无）

## 运行时现状（截至本文件更新）

- 桥在跑（端口 48765），quick 隧道活着（实时地址用 `c2c status -w <项目> --json` 查，不写入仓库）
- 连接器「ChatGPT Brain · agent-with-chatgpt」已在用户 ChatGPT 账号创建并授权
- 重启电脑后隧道地址会变：届时跑 `c2c doctor -w <项目>` → 按提示删旧连接器重建（SKILL.md 重连工作流已覆盖）
- 端到端测试产物 docs/e2e-test-note.md 已在首次提交前清理（内容已记录在上表）
