# AGENTS — agent-with-chatgpt 子项目

把网页版 ChatGPT 变成规划与审核大脑，本地 agent（ZCode / Qoder / WorkBuddy）当手脚。本仓库 fork 自 XiaoDuoYa/codex-with-chatgpt（MIT），upstream remote 保留可同步。

## 硬性规则

1. **桥代码贴上游**：`src/` 只做最小必要改动（产品名/描述字符串等），每一处与上游的代码差异必须登记在 `docs/adapter-matrix.md` 的「与上游的差异」清单，含文件、原因、上游冲突风险。
2. **原 Codex 版 Skill 不动**：`skill/SKILL.md` 原样保留供 Codex 用户；各端适配一律放 `skills/<agent>/`，不要互相覆盖。
3. **凭证纪律**：配对码是唯一允许出现在浏览器里的凭证；任何 token/cookie/session storage 不碰；仓库路径与隧道公网地址不写进 ChatGPT Project 指令（只写连接器名）。
4. **不点菜单**：ChatGPT 页面操作只用固定 URL 清单 + DOM 快照定位，不写死 CSS 选择器，不做截图轮询。
5. **git**：不主动 commit / push；提交内容先给用户确认。同步上游用 `git fetch upstream && git merge upstream/main`，冲突优先保上游桥逻辑、再补本方差异。
6. **进度只记 `STATE.md`**（四段式：已完成 / 待用户完成 / 未开始 / 阻塞），每轮实质性工作后更新。
7. 新会话先读本文件与 `STATE.md`；背景看 `BRIEF.md`（为什么做）、`TASK.md`（执行范围）、`参考文档-codex-with-chatgpt/调研报告.md`。

## 目录速览

- `src/ bin/ tests/`：上游桥接服务（c2c CLI + 只读 MCP + OAuth + 隧道），上游原结构。
- `skill/`：上游原 Codex 版 SKILL.md（保留）。
- `skills/zcode|qoder|workbuddy/`：本项目新增的三端适配层（zcode 与 qoder 各有全自动 SKILL.md，qoder 另有手动中继 README，workbuddy 为手动中继 README）。
- `install/`：安装脚本（装桥 + 装对应端 skill）。
- `docs/`：adapter-matrix.md（三端能力矩阵 + 与上游差异清单）+ 上游原 README 存档。
