# BRIEF — 为什么要做 agent-with-chatgpt

## 起点

用户发现 popnie/codex-with-chatgpt（上游 XiaoDuoYa/codex-with-chatgpt，5279 stars）：网页版 ChatGPT 用已付费的 Plus/Pro 订阅当「大脑」（理解、规划、独立审核），本地 Codex 只当「手脚」。问：ZCode 能不能同样跟网页端 ChatGPT 协同——网页端做审核和项目规划、给出 prompt、本地 ZCode 执行、网页端再审核？并且最好把 Qoder、WorkBuddy 也适配进来。

## 为什么值得做

1. **订阅复用**：对话式规划/审核吃 token 很狠，走网页版订阅额度，不产生 API 费用。
2. **双脑分工**：规划/审核交给一个独立上下文（ChatGPT），它通过只读 MCP 自己拉 diff 独立核查，不轻信执行端自述——比单 agent 自查更接近真人 code review。
3. **三端收益不同但都成立**：ZCode 有 browser-use 浏览器自动化，可达上游同级全自动；Qoder 有 CLI 无浏览器自动化，走人工中继（人只转发 <1KB 状态消息，代码数据仍由 ChatGPT 经 MCP 自拉，核心价值不受影响）；WorkBuddy 编程弱但适合办公型交付物（文档/表格类任务的规划与审核）。

## 形态决策（已定）

- **Fork 内置**：clone 上游为底座，保留 MIT 与 git 历史，upstream remote 可同步；在其上新增三端适配层，README 重写为多 agent 定位（产品名 ChatGPT Brain）。
- **一期范围**：ZCode 全自动先行（实测门槛 = ChatGPT Plus/Pro + 首配协作），Qoder/WorkBuddy 先出手动中继版说明。
- 新建子文件夹 `E:\project\skills\agent-with-chatgpt\`，即本仓库。
