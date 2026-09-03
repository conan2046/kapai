# UnityClient 模块证据索引

模块文档只保存目标模块的协议、入口、Prefab、实现、验证和遗留项。新任务只读取目标模块，不默认读取历史全文。

机器可读状态与验收参数统一维护在 `tools/unity-migration/unityclient-modules.json`。

> Steam范围先读 `../STEAM_SCOPE.md`。其中14个 `steam-excluded` 模块禁止继续迁移；下表的历史实现说明不能覆盖该平台决策。

后续模块统一复用 Task 样板：运行时控件 ID 与矩阵全等、关键中文/禁用态语义断言、固定账号快照精确恢复、G5 双端输入哈希与源码来源。

| 模块 | 文档 | 状态 |
|---|---|---|
| 底层/登录 | `FOUNDATION.md` / `LOGIN.md` | 登录与创角 G0-G6 已通过；Steam SQLite 为 `S0-S7 passed / S8 local accepted / external deferred` |
| 系统设置 | `SETTINGS.md` | `G0-G6 passed / 21/21 complete`；设备级持久化、切号隔离、`no-server-fixture`、8/8 双端视觉和 Bootstrap 幂等通过 |
| 主界面 HUD | `PLAYERHUD.md` | `G0-G3 retained / G4-G6 invalidated / user retest pending`；共享货币与 ResourceFoundation/Bootstrap 输入已变，旧 G4-G6 仅作历史证据 |
| 背包 | `BAG.md` | `G0-G6 passed / 26/26 complete`；当前 SQLite 身份、真实控件、16态 G5、精确恢复及用户最终复测均已收口 |
| 任务 | `TASK.md` | `G0-G6 passed / 14/14 complete`；通用硬门禁回归样板 |
| 神将/阵容 | `HERO.md` | `G0 passed / G1-G6 invalidated / G1 recapture blocked`；G5硬门禁发现当前Cocos状态集大面积重复，必须经Computer Use重采16态后串行重验 |
| 强化大师 | `ENHANCEMASTER.md` | `G0-G3 passed / early user Play pending / G4-G6 pending / 40 controls frozen`；14个当前Cocos状态、13个Unity G3运行态、六页签及装备/法宝养成路由已通过，等待早期真人Play反馈 |
| 神将培养模块 B | `HEROCULTIVATION.md` | `G0-G2 passed / G3 early user Play pending / G4-G6 pending / 51 controls frozen`；18个当前Cocos状态与G3初版已完成，等待用户按最终Prefab布局复测 |
| 装备（法宝边界回归） | `HERO_EQUIPMENT.md` | `G0-G2 passed / G3 early user Play pending / G4-G6 pending`；方案A冻结14来源/974业务ID/86控件；历史G4-G6仅作诊断 |
| 邮件 | `MAIL.md` | `G0-G3 passed / early user Play pending / G4-G6 pending`；SQLite固定身份`7200057/1000003`当前G3通过13/13控件与5/5语义，旧G4-G6仅作诊断 |
| 商城 | `SHOP.md` | `G3 runtime-ready / early user Play passed`；Panel_12隐藏、Shop自有关闭、全控件射线及数量InputField修复已通过用户早测；正式G1-G2及G4-G6仍pending |
| 将魂商店 | `GAMEPLAY_SHOPS.md` | `G0-G4 passed / early user Play passed / G5-G6 pending`；当前仅保留function_id=15/type=2及全部调用入口，29/29控件与9/9语义通过，其他玩法商店分支暂不修复 |
| 体力领取 | `STAMINACLAIM.md` | `steam-excluded`；历史证据仅留档，不再迁移 |
| 资源找回 | `RESOURCERECOVERY.md` | `steam-excluded`；历史证据仅留档，不再迁移 |
| 支付前置 | `PAYMENT.md` | P2 首个前置；仅完成设计冻结，源码尚未实现 |
| 全部基金 | `FUNDS.md` | `steam-excluded`；成长/活跃基金均不再迁移 |
| 好友 | `FRIEND.md` | `steam-excluded`；含好友赠送 |
| 聊天 | `CHAT.md` | `steam-excluded`；含HUD聊天条 |
| 队伍 | `TEAM.md` | `steam-excluded` |
| 帮派 | `GUILD.md` | `steam-excluded`；含宗门 |
| 世界/战斗/副本 | `WORLD.md` | `V0 closed / A=16,19 / World G0-G6 passed / 32/32 complete`；BattleFengShenStory 子模块亦已完成 G6；`47–53`移除 |
| 福利 | `WELFARE.md` | `steam-excluded`；含在线奖励和体力领取 |
| 活动 | `ACTIVITY.md` | `steam-excluded`；充值、排行榜及其他玩家数据活动整体排除 |
| 神将招募 | `DRAW.md` | `G0-G5 retained / G6 evidence missing`；矩阵已有`g6Audit`，但登记的56份逐控件双端图片当前全部缺失 |
| 玩法大厅 | `GAMEPLAY.md` | `G0-G3 passed / early user Play retest pending / G4-G6 pending`；Steam 范围固定为 `function_id=1/3/9/10`，Arena 已排除，不再作为 G5 前置 |
| 七日目标 | `SEVEN_DAY.md` | `steam-excluded`；历史G0/G1诊断只留档 |
| 决战昆仑 | `KUNLUN.md` | `steam-excluded`；依赖匹配对手数据 |
| 血战到底 | `BLOOD_FIGHT.md` | `steam-excluded`；依赖全服排行榜数据 |
| 游历三界 | `YOULI.md` | `G0 passed / G1-G6 evidence missing`；实现保留，Cocos/Unity基准与差异目录当前缺失 |
| 封神列传 | `FENGSHEN_STORY.md` | 用户确认保留；战斗19的BattleFengShenStory子模块已完成G0-G6；父模块仍按自身门禁推进 |
| 竞技场 | `ARENA.md` | `G0 pending / legacy logic only`；历史Runner不替代当前Cocos基准与控件闭包 |
| 法宝搜索 | `XUNBAO.md` | `G0 passed / G1-G6 evidence missing`；实现保留，Cocos/Unity基准与差异目录当前缺失 |
| Cocos UI Timeline | `UI_TIMELINE.md` | 29 处有效调用对应 Prefab 完成 |
| ImodAnim 兼容播放 | `IMOD_ANIMATION.md` / `IMOD_ANIMATION_CALLS.md` | 885 个可播放资源全动作验证；7 个源资产缺口 |

新增模块文档固定结构：当前结论、范围、三方证据、实现边界、有效证据、缺口和下一步；统一门禁见 `../MIGRATION_GUIDE.md`。
