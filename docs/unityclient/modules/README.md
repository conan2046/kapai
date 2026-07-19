# UnityClient 模块证据索引

模块文档只保存目标模块的协议、入口、Prefab、实现、验证和遗留项。新任务只读取目标模块，不默认读取历史全文。

机器可读状态与验收参数统一维护在 `tools/unity-migration/unityclient-modules.json`。

| 模块 | 文档 | 状态 |
|---|---|---|
| 底层/登录/主界面 | `FOUNDATION.md` / `LOGIN.md` | 功能第一阶段完成；视觉 1:1 待重验 |
| 背包 | `BAG.md` | 功能第一阶段完成；视觉 1:1 待重验 |
| 任务 | `TASK.md` | 功能第一阶段完成；视觉 1:1 待重验 |
| 神将/阵容/装备/法宝 | `HERO_EQUIPMENT.md` | 阵容 `visual-1to1-complete`；装备/法宝 G0-G4 与 G6 逻辑门禁完成，状态 `g6-logic-complete-visual-fixing`；两组列表差异图已恢复，详情/弹窗/失败态 Cocos 基准待重采 |
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

新增模块文档固定结构：范围、三方证据、实现、功能验证、视觉 1:1 记录、遗留项、关键坑；视觉门禁见 `../UI_1TO1_STANDARD.md`。
