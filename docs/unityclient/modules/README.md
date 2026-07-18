# UnityClient 模块证据索引

模块文档只保存目标模块的协议、入口、Prefab、实现、验证和遗留项。新任务只读取目标模块，不默认读取历史全文。

机器可读状态与验收参数统一维护在 `tools/unity-migration/unityclient-modules.json`。

| 模块 | 文档 | 状态 |
|---|---|---|
| 底层/登录/主界面 | `FOUNDATION.md` / `LOGIN.md` | 按当前运行代码重新验收中；本地登录/隔离创角/进入当前主界面通过 |
| 背包 | `BAG.md` | 第一阶段完成 |
| 任务 | `TASK.md` | 第一阶段完成 |
| 神将/阵容/装备/法宝 | `HERO_EQUIPMENT.md` | 第一阶段完成 |
| 邮件 | `MAIL.md` | 第一阶段完成 |
| 商城 | `SHOP.md` | 第一阶段完成 |
| 好友 | `FRIEND.md` | 第一阶段完成 |
| 聊天 | `CHAT.md` | 第一阶段完成 |
| 队伍 | `TEAM.md` | 第一阶段完成 |
| 帮派 | `GUILD.md` | 第一阶段完成 |
| 世界/战斗/副本 | `WORLD.md` | 第一阶段完成 |
| 福利 | `WELFARE.md` | 第一阶段完成 |
| 活动 | — | 旧版玩法取证已判废；待按当前运行代码重新立项 |
| Cocos UI Timeline | `UI_TIMELINE.md` | 29 处有效调用对应 Prefab 完成 |
| ImodAnim 兼容播放 | `IMOD_ANIMATION.md` / `IMOD_ANIMATION_CALLS.md` | 885 个可播放资源全动作验证；7 个源资产缺口 |

新增模块文档固定结构：范围、三方证据、实现、验证、遗留项、关键坑。
