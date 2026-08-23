# UnityClient 模块证据索引

模块文档只保存目标模块的协议、入口、Prefab、实现、验证和遗留项。新任务只读取目标模块，不默认读取历史全文。

机器可读状态与验收参数统一维护在 `tools/unity-migration/unityclient-modules.json`。

> Steam范围先读 `../STEAM_SCOPE.md`。其中12个 `steam-excluded` 模块禁止继续迁移；下表的历史实现说明不能覆盖该平台决策。

后续模块统一复用 Task 样板：运行时控件 ID 与矩阵全等、关键中文/禁用态语义断言、固定账号快照精确恢复、G5 双端输入哈希与源码来源。

| 模块 | 文档 | 状态 |
|---|---|---|
| 底层/登录 | `FOUNDATION.md` / `LOGIN.md` | 登录与创角 G0-G6 已通过；Steam SQLite 启动前置处于 `S0-S4 passed / S5 current / S6-S8 pending` |
| 系统设置 | `SETTINGS.md` | `G0-G6 passed / 21/21 complete`；设备级持久化、切号隔离、`no-server-fixture`、8/8 双端视觉和 Bootstrap 幂等通过 |
| 主界面 HUD | `PLAYERHUD.md` | `G0-G6 passed / 56/56 complete`；11/11 双端视觉、14/14 语义、只读权威显示、路由边界、生命周期与 Bootstrap 幂等通过 |
| 背包 | `BAG.md` | `G0-G1 passed / G2-G6 pending / 0/26 current complete`；当前 `btn_Bag` 与固定账号证据已通过，7张Cocos原图复用、3张缺失生命周期状态新拍，尚未进入Unity实现 |
| 任务 | `TASK.md` | `G0-G6 passed / 14/14 complete`；通用硬门禁回归样板 |
| 神将/阵容 | `HERO.md` | `G0-G6 passed / 16/16 complete`；阵容主链保持有效，装备操作后的 `/70` 属性刷新由 HeroEquip 重新开门禁修复 |
| 神将培养模块 B | `HEROCULTIVATION.md` | `G0-G1 passed / G2-G6 pending / 41 controls frozen`；15 个当前 Cocos 原生状态已冻结，升级、升星、突破、修炼、信息与左右已上阵神将切换继续独立重验 |
| 装备（法宝边界回归） | `HERO_EQUIPMENT.md` | `G0 passed / G1-G6 pending`；方案A冻结12来源/963业务记录/86控件，含40个装备碎片来源ID；法宝仅作兄弟入口及共享协议隔离回归，历史33控件/20视觉仅作诊断 |
| 邮件 | `MAIL.md` | `G0-G6 passed / 13/13 complete`；当前证据路径存在 |
| 商城 | `SHOP.md` | `G0-G6 passed / 21/21 complete`；当前证据路径存在 |
| 玩法商店 | `GAMEPLAY_SHOPS.md` | `G0 pending / evidence-missing`；登记的15个正式证据路径当前缺失，旧完成态已撤销 |
| 体力领取 | `STAMINACLAIM.md` | `steam-excluded`；历史证据仅留档，不再迁移 |
| 资源找回 | `RESOURCERECOVERY.md` | `steam-excluded`；历史证据仅留档，不再迁移 |
| 支付前置 | `PAYMENT.md` | P2 首个前置；仅完成设计冻结，源码尚未实现 |
| 全部基金 | `FUNDS.md` | `steam-excluded`；成长/活跃基金均不再迁移 |
| 好友 | `FRIEND.md` | `steam-excluded`；含好友赠送 |
| 聊天 | `CHAT.md` | `steam-excluded`；含HUD聊天条 |
| 队伍 | `TEAM.md` | `steam-excluded` |
| 帮派 | `GUILD.md` | `steam-excluded`；含宗门 |
| 世界/战斗/副本 | `WORLD.md` | `G0-G6 passed / 25/25 complete`；当前证据路径存在 |
| 福利 | `WELFARE.md` | `steam-excluded`；含在线奖励和体力领取 |
| 活动 | `ACTIVITY.md` | `steam-excluded`；充值、排行榜及其他玩家数据活动整体排除 |
| 神将招募 | `DRAW.md` | `G0-G5 retained / G6 audit missing`；当前控件矩阵缺硬门禁 v2 `g6Audit`，旧 LuckyDraw 排除 |
| 玩法大厅 | `GAMEPLAY.md` | `G0 passed / G1-G6 pending`；Steam过滤后按5项/8控件重新取证，旧13项/16控件结果只作历史参考 |
| 七日目标 | `SEVEN_DAY.md` | `steam-excluded`；历史G0/G1诊断只留档 |
| 决战昆仑 | `KUNLUN.md` | `steam-excluded`；依赖匹配对手数据 |
| 血战到底 | `BLOOD_FIGHT.md` | `steam-excluded`；依赖全服排行榜数据 |
| 游历三界 | `YOULI.md` | 逻辑通过；Cocos 基准与差异报告缺失，视觉待修 |
| 封神列传 | `FENGSHEN_STORY.md` | `G0-G6 passed / 25/25 complete`；真实挑战/奖励、12 组双端视觉、精确恢复与 Bootstrap 幂等通过 |
| 竞技场 | `ARENA.md` | 逻辑 Runner 已通过；Cocos 基准与差异报告缺失，视觉待修 |
| Cocos UI Timeline | `UI_TIMELINE.md` | 29 处有效调用对应 Prefab 完成 |
| ImodAnim 兼容播放 | `IMOD_ANIMATION.md` / `IMOD_ANIMATION_CALLS.md` | 885 个可播放资源全动作验证；7 个源资产缺口 |

新增模块文档固定结构：当前结论、范围、三方证据、实现边界、有效证据、缺口和下一步；统一门禁见 `../MIGRATION_GUIDE.md`。
