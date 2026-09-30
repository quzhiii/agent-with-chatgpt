# STATE — agent-with-chatgpt 当前状态

更新时间 2026-09-29（一期实测通过后进入发布准备：README 双语、来源标注、SkillHub 发布素材）
上次更新 2026-09-27（**端到端实测通过**，一期全部完成）

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
- **Qoder 手动中继实测通过（2026-09-27，c2c_qd01）**：Qoder 按 relay README 规则执行——INIT→ChatGPT PLAN→创建 scripts/repo-stats.mjs→c2c record→EXECUTED→ChatGPT 独立复核（逐文件累加验证 7 文件 1022 行）→DONE；Qoder 全程遵守协议并主动报告 AGENTS.md 规则 6（STATE.md 更新交还主会话）
- Qoder 工具盘点：**browser-use MCP 16 工具、DOM 级**（take_snapshot/fill/click/press_key/evaluate_script），本机走 headless Chrome（视口 0、截图不可用——协议本来就不依赖截图）→ 全自动可行
- `skills/qoder/SKILL.md` 全自动版（日常循环全自动 + 首配人工 + 中继降级兜底），已装 `~/.qoder/skills/chatgpt-brain/`
- Qoder 全自动首轮实测发现**权限墙**（2026-09-28）：自动权限模式的分类器把 c2c 桥命令判为「与任务无关」静默拦截（放行选项不生效、不弹窗）；协议执行本身全对（门禁、目录确认、降级建议都对）。修复：skill 增加「权限前置检查」（被拦一次即停、请用户切到每条命令询问/信任模式，不愿切则走中继）；已提交推送并重装。待用户切模式后继续该轮验证（TASK_ID c2c_qd02 --no-upstream 任务）
- 隐私清理后首次提交并推送（2026-09-27）：清理 STATE.md 中的会话链接与隧道地址、移除测试产物、git 身份用 GitHub noreply 邮箱；私有仓库 `quzhiii/agent-with-chatgpt`（origin）+ upstream 双远端就位；Qoder/WorkBuddy 适配文档同步新版 UI 流程
- **发布准备（2026-09-29，产物待用户过目）**：README 双语化（中文主 + `README.en.md`，顶部语言切换、新增「致谢与来源」「许可证」章节、真实 clone 地址）；`package.json` 加 `repository`、description 多端化（差异清单 #11/#12）；新增 `skills/skillhub/`（平台中立 chatgpt-brain skill，SKILL.md 兼作小红书 SkillHub 详情页）；小红书笔记文案与上架素材草稿存 `docs/publish/`；官方 redskillhub-upload skill ZIP 已下载并审查（临时目录，未执行其中脚本）——打包规则确认：zip 打包由 CLI 负责、SKILL.md 全文即上架详情页、发布固定问 原创/转载 + 中文标签（实时拉取）、确认卡后需用户明确回复「提交」才 submit

## 待用户完成

- 过目发布准备产物：README 双语、`skills/skillhub/SKILL.md`、`docs/publish/` 两份文案（笔记标题三选一、原创/转载决策）；确认后 commit + push
- 小红书发布链路（Phase 3，等过目后执行）：隐私复查 → 用户确认后转公开（`gh repo edit quzhiii/agent-with-chatgpt --visibility public`）→ ensure-cli 版本门禁（Windows 用户级 npm prefix，进程级环境变量）→ 二维码登录（图片直发用户）→ 确认卡核对 → **仅用户明确回复「提交/确认/submit」才最终提交**；笔记由用户手动发布
- Qoder 全自动版首轮验证：新开 Qoder 会话说「使用 chatgpt-brain 完成 XXX」（skill 已装 `~/.qoder/skills/chatgpt-brain/`）；关注两点——headless Chrome 里 chatgpt.com 登录态是否持久、Cloudflare 是否放行；失败自动回退中继模式，回报即可
- WorkBuddy 端实测（README 已按新版 UI 更新）
- 可选升级：ChatGPT Project 模式（Bind Project：用户建合集 + 项目指令，见 SKILL.md 会话管理节）；固定域名隧道（Cloudflare 登录，地址不再变化）；仓库转公开：`gh repo edit quzhiii/agent-with-chatgpt --visibility public`（当前私有）
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
