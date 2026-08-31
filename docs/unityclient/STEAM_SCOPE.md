# Steam 版本迁移范围

> 本文件只定义 Steam 平台的模块纳入/排除边界，不维护完成率。实时进度仍以根目录 `UNITYCLIENT_STATUS.md` 为唯一来源，机器状态以 `tools/unity-migration/unityclient-modules.json` 为准。

## 强制规则

- 下列 `steam-excluded` 模块不得继续迁移，不得进入 G0-G6，不得补 UI、协议、Prefab、截图或验收证据。
- 不得因为仓库仍保留旧 Unity 实现、Cocos Lua、服务端协议、配置或历史文档，就重新开启迁移。
- Cocos与服务端线上逻辑继续保留，不为 Steam 范围决策删除或改写。
- 两个中央 Runner 会读取 `migrationExcluded=true` 并拒绝执行；禁止通过手工 PlayMode、临时脚本、MCP或直接调用内部方法绕过。
- 只有用户明确改变 Steam 产品范围后，才能同时修改本文件、`UNITYCLIENT_STATUS.md`、Manifest、入口配置和 Runner 门禁。

## 已排除模块

| Manifest Key | 中文范围 | Steam处理 |
|---|---|---|
| `SevenDay` | 七日目标、HUD 7日活动 | 玩法大厅与HUD入口隐藏；路由和验收关闭 |
| `Funds` | 成长基金、活跃基金、全部基金 | 玩法大厅隐藏；支付/领取不迁移 |
| `ResourceRecovery` | 资源找回 | 玩法大厅隐藏；查询/找回不迁移 |
| `Welfare` | 福利、在线奖励 | HUD入口及在线奖励隐藏 |
| `StaminaClaim` | 体力领取 | 作为福利子模块排除，玩法大厅隐藏 |
| `Friend` | 好友、好友赠送 | HUD和玩法大厅入口隐藏 |
| `Chat` | 聊天、HUD聊天条 | 入口及聊天条整体隐藏 |
| `Team` | 队伍 | 入口隐藏 |
| `Guild` | 帮派、宗门 | 入口隐藏 |
| `Activity` | 运营活动、首充、充值、折扣礼包 | 整体排除；HUD对应入口隐藏，`/222`不得重新显示折扣入口 |
| `KunLun` | 决战昆仑 | 玩法大厅隐藏；匹配对手及共享红点 `/213 op=25` 不再请求 |
| `BloodFight` | 血战到底 | 玩法大厅隐藏；全服血战排行榜不迁移 |
| `Arena` | 竞技场 | 用户于2026-08-31确认当前版本保持屏蔽；玩法大厅入口、每日任务和战斗验收不迁移 |
| `BattleScript` | 师门、心魔、藏宝图旧脚本战斗 | 用户于2026-08-31明确不需要；不创建Unity入口或战斗验收 |

## 当前保留范围

- 单人玩法：游历三界、封神列传、法宝搜索、每日任务及已纳入的基础功能。
- 玩法大厅 Steam 列表固定为 `function_id=1/3/9/10`。其他 `function_id` 即使仍在原始 Cocos 配置中，也不得由 Unity Steam 列表展示。

## 新任务启动检查

1. 先读本文件和 `UNITYCLIENT_STATUS.md`。
2. 在 `tools/unity-migration/unityclient-modules.json` 检查目标模块是否有 `migrationExcluded=true`。
3. 若已排除，立即停止该模块；不得启动 Cocos、Unity、服务端或 Fixture。
4. 若未排除，才按 `MIGRATION_GUIDE.md` 从当前门禁继续。
