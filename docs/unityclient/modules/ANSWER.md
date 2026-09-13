# 每日答题模块（Unity）

> 状态：实现完成；Unity/SQLite定向批处理与用户真人Play均已通过。Cocos版本不增加本需求逻辑修改。

## 1. 产品口径

- Unity无场景NPC、无自动寻路、无 `/191 op=1002` 中转。
- 开放条件取正式 `function_id=27` 的 `open` 字段；当前为10级。
- Unity通过 `function-routes.json` 的 `pageOverride=1` 将答题放入玩法大厅，避免改动Cocos的 `function` 页面归属。
- 玩家点击玩法大厅 `Function_27/EnterBtn` 后请求 `/198 op=1`；成功才显示答题界面。
- 每日可体验次数取 `answer_settings.daily_attempt_limit`；达到上限后入口仍保留，点击提示 `今日答题次数已用完`，不进入答题UI。
- 题目、四选一、20秒倒计时、正误反馈、10题流程和最后结算保持原答题逻辑。
- `reward_rank type=41` 缺失或未命中奖励时，仅Unity SQLite路径按配置临时发金币；当前占位为 `type=60000, amount=1000`，后续改表。

## 2. 入口与调用链

```text
HUD玩法按钮
  -> 玩法大厅读取 gameplay.json
  -> Function_27 使用 function[27].openLevel
  -> 点击参加
  -> AnswerController.onClick
  -> /198 op=1
  -> 失败：Toast，保持玩法大厅
  -> 成功：加载现有 AnswerLayer.prefab
  -> 选项1~4或20秒超时选项5
  -> /198 op=2
  -> 1秒正误反馈
  -> 未结束：再次 /198 op=1
  -> 第10题：追加MultiAward、Toast总金币、关闭答题页
  -> 再次点击且达到上限：今日答题次数已用完
```

## 3. 协议 `/198`

| 方向 | op | 包体 | 说明 |
| --- | ---: | --- | --- |
| C→S | 1 | `Byte op` | 请求下一题；首次请求同时承担入口次数校验 |
| S→C | 1成功 | `Byte result, Byte index, Byte remaining, String question, String answers` | `answers`以`|`分隔 |
| S→C | 1失败 | `Byte result=0, String tip` | 上限提示或配置/题库错误 |
| C→S | 2 | `Byte op, Byte answer` | `1~4`为选择，`5`为超时 |
| S→C | 2答对 | `Byte result=1, UInt currentReward` | 累计答对数 |
| S→C | 2答错 | `Byte result=0, Byte correctIndex, UInt currentReward, String tip` | 显示正确选项 |
| S→C | 第10题追加 | `Byte count, repeat(Word type, UInt typeId, UInt amount)` | 最终奖励 `MultiAward` |

## 4. 配置与数据

| 文件/表 | 字段 | 用途 |
| --- | --- | --- |
| `server/config/json/function.json` | `id=27, open` | Unity开放等级权威源；Cocos文件不修改 |
| `unityclient/.../Configs/function-routes.json` | `pageOverride/iconOverride/target` | Unity专属大厅路由 |
| `server/config/source/answer-settings.csv` | `daily_attempt_limit` | 每日轮数 |
| 同上 | `fallback_reward_type/amount` | 缺失奖励的Unity金币兜底 |
| `outputs/answer-question-bank/question.xlsx` | `Sheet1!A1:H42` | 38道中文题策划源 |
| `server/config/source/question.csv` | `id/question/answer1~4` | 由策划表生成的运行源；`answer1`为正确答案 |
| SQLite `answer_settings` | 上述运行配置 | 本地服务端读取 |
| SQLite `answer_daily_progress` | `role_id/day_key/used_count` | 按角色、自然日记录完成轮数 |
| `server/config/json/reward_rank.json` | `type=41` | 原答题最终奖励；缺失才使用金币兜底 |
| SQLite/MySQL `question` | 题目与答案 | 已同步38道中文文物题；客户端通过 `/198` 接收，不硬编码题目 |

次数/奖励配置导出：`tools/local/Export-AnswerSettings.ps1`。题库链路：`question.xlsx` → `tools/local/Import-QuestionWorkbook.py` → `question.csv` → `tools/local/Export-QuestionBank.ps1`。题库种子为 `server/sql/sqlite/seeds/question.sql` 与 `server/sql/mysql/seeds/question.sql`，并同步写入两端初始结构。

## 5. UI与资源

- 原Cocos：`client/ProjectX/res/csd/dati/AnswerLayer.csb`。
- Unity现有Prefab：`unityclient/Assets/ProjectX/res/csd/Prefabs/dati/AnswerLayer.prefab`，未重做、未修改布局。
- `RewardBg/Reward` 作为Prefab内置品质框节点，`Reward/Icon` 直接引用金币图标，默认数量为当前兜底配置 `1000`；运行时只校验并复用节点，不动态创建品质框或图标节点。
- Unity动态引用：`unityclient/Assets/ProjectX/Resources/UiPrefabs/AnswerLayer.asset`。
- 大厅图标：`unityclient/Assets/ProjectX/Resources/GameplayIcons/ui_icon_wanfa_dati.png`，由正式Cocos plist帧提取。
- 渲染绑定：`AnswerPresenter.cs`；协议/业务状态：`AnswerController.lua.txt`；生命周期：`ProjectXApp.Answer.cs`。

## 6. 平台边界

| 范围 | 处理 |
| --- | --- |
| Cocos Lua、CSB、NPC、玩法大厅 | 不修改 |
| Cocos题库逻辑 | 不修改；workspace-local MySQL共享题库数据同步为38道中文测试题 |
| MySQL/Cocos每日次数 `ExtData8[6]` | 保持原逻辑 |
| MySQL/Cocos奖励 | 保持原 `reward_rank` 逻辑，不启用金币兜底 |
| Unity玩法入口 | function 27 + Unity route override |
| Unity次数与奖励兜底 | 仅SQLite连接生效 |

## 7. 验证合同

- 固定身份：`userId=7200057 / roleId=1000003`。
- 可逆夹具：`Invoke-AnswerSqliteFixture.ps1`，整库快照并清零当日次数、题数、答对数。
- 自动化标志：`-projectXAnswerValidation`。
- 自动化目标：11/11控件、10题真实 `/198` 循环、最终金币、第二次入口上限提示、SQLite变更、恢复/重登哈希及零残留。
- 预期截图：`bootstrap-answer-question.png`、`bootstrap-answer-result.png`、`bootstrap-answer-daily-limit.png`；每张图必须带相邻 `-ui-resource-map.md`。
- 用户于2026-09-13明确反馈“测试通过”，当前控件矩阵记录 `manualPassed=true`。

## 8. 当前已知项

- 已按用户确认导入 `D:\xuancai\museum\策划\excel\question.xlsx` 的38道完整中文文物题；项目交付表为 `outputs/answer-question-bank/question.xlsx`，运行源为 `server/config/source/question.csv`。
- 原表ID 25、26题干相同但正确答案不同，当前原样保留，待策划后续确认是否合并或改题干。
- 金币兜底数量 `1000` 是临时可配置值，待用户后续调整。
- Cocos入口与Unity入口故意不同，不做像素级入口对照；答题主体UI仍以原 `AnswerLayer` 为视觉基线。

## 9. 2026-09-13 定向验证结果

- Unity批处理结果：`success=true`，11/11控件、5/5语义断言通过。
- 固定账号真实完成10次 `/198 op=1/2` 循环，最终金币 `1000`；第二次入口显示精确提示 `今日答题次数已用完`。
- 截图分辨率 `1334x750`；题目、正误反馈、次数上限三态均已生成相邻资源映射文档。
- 视觉复核后修正两项：隐藏Cocos原逻辑已隐藏的 `RewardBg/Bg1/Icon`；次数上限提示前清理上一条奖励Toast，避免提示排队。
- 用户复核奖励位后补齐Prefab固定金币展示：内置品质框、金币图标和默认 `1000` 数量，不使用运行时动态节点。
- 中文题库已写入Unity当前 `projectx.db` 与workspace-local MySQL：38行、英文占位题0行、SQLite完整性为`ok`；客户端仍完全通过 `/198` 收题。
- SQLite夹具完成 ``Setup -> AssertSetup -> AssertMutated -> Restore -> AssertRestored -> AssertReloginHash -> Cleanup -> AssertCleanup`；进程与备份残留为0。
- 中央迁移门禁仅标记G0通过；G1要求新鲜Cocos原生运行证据，本次Unity专属改动不伪造该证据，因此G2/G3中央状态仍待后续门禁任务。
- `manualPassed=true`：用户于2026-09-13在Unity Player完成真实输入测试并明确反馈“测试通过”。
- 中央G1-G6仍保留待补：本需求明确不修改Cocos版本，当前没有伪造Cocos原生基线或标准双端视觉证据；本次发布只确认Unity答题功能的人测结果。
