# 本地 Agent Adapter 状态概览

本页汇总三个本地 Agent 适配层（zcode / qoder / workbuddy）的适配模式、当前状态与对应文件路径。用于快速对照，详细能力矩阵见 `docs/adapter-matrix.md`。

## 状态一览

| 本地 Agent | 模式 | 当前状态 | 文件路径 |
| --- | --- | --- | --- |
| zcode | 全自动 | 已定稿并端到端实测通过，浏览器自动传 `[C2C]` 消息 | `skills/zcode/SKILL.md` |
| qoder | 手动中继 | 已就绪，终端执行由人转发 `[C2C]` 消息并回填状态 | `skills/qoder/SKILL.md`、`skills/qoder/README.md` |
| workbuddy | 手动中继 | 已就绪，面向文档 / 办公类工作流，`record` 由人代跑 | `skills/workbuddy/README.md` |

## 说明

- 模式区分：全自动端由 Agent 自己操作网页收发 `[C2C]` 消息；手动中继端由用户在中间转发消息、代跑 CLI。
- 当前状态依据工作区现有文件确认，未记录未文档化的能力。
- 降级策略：全自动端遇浏览器自动化不可用时可临时切到手动中继流程，协议不变；手动端若获得网页操作工具，可升级为全自动。
- 上游原 Codex 版说明保留在 `skill/SKILL.md`，不在本表范围内。
