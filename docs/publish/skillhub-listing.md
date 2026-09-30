# SkillHub 上架素材(草稿,待用户确认)

对应上传包:`skills/skillhub/`(单文件 SKILL.md,打包由官方 CLI 完成)。
发布时以上传后 `PROMPT.payload` 生成的确认卡为准,本页是预备素材与决策记录。

## 基本信息

| 项 | 值 | 来源 |
| --- | --- | --- |
| Skill 名称 | chatgpt-brain | `skills/skillhub/SKILL.md` frontmatter `name` |
| 简介 | 把网页版 ChatGPT(Plus/Pro 订阅)接入本地 AI 编程/办公 Agent 当「规划与审核大脑」……(frontmatter 全文) | frontmatter `description` |
| Skill 介绍 | SKILL.md 正文全文(平台会作为详情页展示,已按详情页标准撰写) | SKILL.md 正文 |
| 来源(source) | **建议:原创** | 见下方决策说明 |
| 标签(tag) | 发布时以 `redskillhub-upload tags --env prod` 实时拉取为准;预期选「编程开发」类 | CLI 固定交互 |

## 决策点:原创 vs 转载

- **建议选「原创」**:上传的是本项目撰写的多端适配版 skill(原创成分:适配层、
  skill 文案、安装体系),并非原样转载上游作品;fork 来源已在 SKILL.md「来源与协议」
  一节明确标注(XiaoDuoYa/codex-with-chatgpt,MIT),与 GitHub README 的来源标注一致。
- 若你倾向选「转载」:需附 ≤15 字符的转载来源,可用「GitHub:XiaoDuoYa」
  (「codex-with-chatgpt」共 18 字符,超限)。
- **最终由用户在发布交互中拍板。**

## 发布命令模板(Phase 3 执行,环境硬门禁:全部 --env prod)

```bash
# 0. CLI 版本门禁(Windows:先设 LOCALAPPDATA 用户级 prefix/cache,进程级生效)
node "<SKILL_DIR>/scripts/ensure-cli.mjs" --env prod --npm-tag latest
# 仅 status ∈ {current, installed, updated} 才继续

# 1. 拉取实时标签
redskillhub-upload tags --env prod

# 2. 发布会话(保持进程等待;未登录会先进二维码授权)
redskillhub-upload publish "E:\project\skills\agent-with-chatgpt\skills\skillhub" \
  --agent --source original --tag "<实时标签>" --env prod

# 3. 确认卡展示 → 用户修改走 edit 块 → 仅用户明确回复「确认/提交/submit」才写入 submit
```

安全约束(来自官方口令,已内化为执行规范):不自行解压/重打包 zip(交给 CLI)、
命令全部设超时、权限错误即停(最多自动重试一次用户目录方案)、不碰 sudo、
二维码图片直接发给用户、授权完成 ≠ 允许提交。
