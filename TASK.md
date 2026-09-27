# TASK — 一期执行范围

## 做

1. Clone 上游（remote 命名 upstream），存档调研报告到 `参考文档-codex-with-chatgpt/`。✅
2. 治理文件（AGENTS/BRIEF/TASK/STATE）。✅
3. 品牌化最小改造：PRODUCT_NAME / DEFAULT_CONNECTOR_NAME → "ChatGPT Brain"，MCP 工具描述去 Codex 化，测试同步；差异登记 adapter-matrix.md。
4. `skills/zcode/SKILL.md`：以上游 SKILL.md 为底，浏览器自动化全部换成 browser-use（bootstrap / getForUrl / domSnapshot / getByRole 填表 / 20–30 秒快照轮询 / finalize handoff），安装路径 `~/.zcode/skills/chatgpt-brain/`，明确 browser-use 仅主 agent 可用，ZCode 权限模式说明。
5. `skills/qoder/README.md`、`skills/workbuddy/README.md`：手动中继版（何时贴什么的消息模板 + 自检清单），同一协议同一桥。
6. `install/install-zcode.ps1|.sh`：环境自检（Node≥20、pnpm、cloudflared 缺则给 winget 命令）→ 构建 → 复制 skill 到用户目录并回填仓库路径。
7. README.md 重写（多 agent 定位 + 快速开始 + 边界表）+ `docs/adapter-matrix.md`。
8. 本地验证：`pnpm install && pnpm build && pnpm test`；`c2c doctor`；`scripts/poc-client.mjs` 模拟连接器完成 OAuth+配对+只读工具调用。
9. 更新 STATE.md。

## 不做（二期再说）

- ZCode 端到端实测（需要用户 ChatGPT Plus/Pro 登录协作，列为待用户完成）
- Qoder/WorkBuddy 的自动化浏览器适配（等确认其工具能力）
- 深度改名（CLI c2c、协议标记 [C2C]、状态目录名保留，保证上游可合并）
- 非 cloudflared 隧道（TunnelProvider 已抽象，需要再做）
