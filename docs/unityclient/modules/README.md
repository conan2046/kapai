# UnityClient 模块证据索引

模块文档只保存目标模块的协议、入口、Prefab、实现、验证和遗留项。新任务只读取目标模块，不默认读取历史全文。

机器可读状态与验收参数统一维护在 `tools/unity-migration/unityclient-modules.json`。

后续模块统一复用 Task 样板：运行时控件 ID 与矩阵全等、关键中文/禁用态语义断言、固定账号快照精确恢复、G5 双端输入哈希与源码来源。

| 模块 | 文档 | 状态 |
|---|---|---|
| 底层/登录/主界面 | `FOUNDATION.md` / `LOGIN.md` | 功能第一阶段完成；视觉 1:1 待重验 |
| 背包 | `BAG.md` | `G0-G6 passed / 26/26 complete`；双端视觉、真实协议、生命周期与幂等门禁通过 |
| 任务 | `TASK.md` | `G0-G6 passed / 14/14 complete`；通用硬门禁回归样板 |
| 神将/阵容 | `HERO.md` | `partial-interactive-audit-required`；矩阵0/16，等待真实按钮逐项重审 |
| 装备/法宝 | `HERO_EQUIPMENT.md` | `partial-interactive-audit-required`；历史协议诊断可复用，G4-G6按新矩阵重做 |
| 邮件 | `MAIL.md` | 功能第一阶段完成；视觉 1:1 待重验 |
| 商城 | `SHOP.md` | 功能第一阶段完成；视觉 1:1 待重验 |
| 将魂/竞技场/血战商店 | `GAMEPLAY_SHOPS.md` | 7 个 `/221` 协议页、74 条权威商品已通过门禁；视觉待重验 |
| 体力领取 | `STAMINACLAIM.md` | `/321 op=2` 三档权威状态已通过门禁；领取写操作禁用 |
| 资源找回 | `RESOURCERECOVERY.md` | `/52 op=1` 七条权威记录已通过门禁；找回写操作禁用 |
| 全部基金 | `FUNDS.md` | 成长/活跃基金 `/222 op=83/94` 双页权威状态已通过；购买/领取写操作禁用 |
| 好友 | `FRIEND.md` | 功能第一阶段完成；视觉 1:1 待重验 |
| 聊天 | `CHAT.md` | 功能第一阶段完成；视觉 1:1 待重验 |
| 队伍 | `TEAM.md` | 功能第一阶段完成；视觉 1:1 待重验 |
| 帮派 | `GUILD.md` | 功能第一阶段完成；视觉 1:1 待重验 |
| 世界/战斗/副本 | `WORLD.md` | 功能第一阶段完成；视觉 1:1 待重验 |
| 福利 | `WELFARE.md` | 功能第一阶段完成；视觉 1:1 待重验 |
| 活动 | `ACTIVITY.md` | 功能第一阶段完成；视觉 1:1 待重验；旧 `/209` 判废 |
| 神将招募 | `DRAW.md` | 功能第一阶段完成；视觉 1:1 待重验；旧 LuckyDraw 排除 |
| 玩法大厅 | `GAMEPLAY.md` | 真实主布局与公共公告已接；细节视觉按用户要求延后 |
| 决战昆仑 | `KUNLUN.md` | `/213 op=25`、真实背景/九宫格、权威空匹配状态已通过；战斗与动态模型延后 |
| 血战到底 | `BLOOD_FIGHT.md` | `/323 op=1`、真实主布局与权威空状态已通过；排行、战斗与特效延后 |
| 游历三界 | `YOULI.md` | 逻辑通过；Cocos 基准与差异报告缺失，视觉待修 |
| 封神列传 | `FENGSHEN_STORY.md` | 逻辑通过；Cocos 基准与差异报告缺失，视觉待修 |
| 竞技场 | `ARENA.md` | 逻辑 Runner 已通过；Cocos 基准与差异报告缺失，视觉待修 |
| Cocos UI Timeline | `UI_TIMELINE.md` | 29 处有效调用对应 Prefab 完成 |
| ImodAnim 兼容播放 | `IMOD_ANIMATION.md` / `IMOD_ANIMATION_CALLS.md` | 885 个可播放资源全动作验证；7 个源资产缺口 |

新增模块文档固定结构：当前结论、范围、三方证据、实现边界、有效证据、缺口和下一步；统一门禁见 `../MIGRATION_GUIDE.md`。
