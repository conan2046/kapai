# 脚本触发战斗模块

> 状态：2026-08-31 用户明确排除；师门、心魔、藏宝图三条旧脚本战斗不进入当前 Unity 迁移与战斗表现验收分母。

## 范围

- `server/src/fight.h::EFTScript=4` 的源码入口仅剩三组旧流程：师门/周师门、试炼心魔、藏宝图/护宝小妖。
- 当前服务端 `CUserMission` 的旧接取、查询、更新和删除实现已注释，师门与心魔不能形成当前产品运行链。
- 当前正式服务端 `item.json` 共443条道具，不含`2441/2442`或`script=22441`；客户端`item_dat.lua`也无对应条目，藏宝图入口不能形成当前产品运行链。
- 用户已明确这三条流程不需要，不继续G1动态取证、不启动Cocos/Unity、不新增Unity入口。

## 三方证据

- 协议：/8、/12、/13、/21、/22、/23、/244。
- 服务端处理函数：`CScene::ShiMenFight`、`CScene::WabaoFight`、`ShiLianXinMoFight`均设置`EFTScript`；共享战斗仍使用`/21-/23`。
- 旧客户端请求/解析：任务追踪`/12-/13`、背包使用`/8`、共享`LBattleLogic`。
- 当前可达性证据：`server/src/mission_manager.cpp`、`server/config/json/item.json`、`client/ProjectX/src/ConfigData/item_dat.lua`。
- 用户范围证据：本任务2026-08-31明确“这三个不需要的”。

## 实现边界

- 不创建`BattleScriptController`、ViewState、RenderBridge或验证夹具。
- 不修改共享战斗播放器来支持当前产品不存在且用户排除的入口。
- 保留服务端和Cocos遗留源码，不删除线上路径。

## 验证

- 结论：用户排除，不属于通过；无G1-G6证据，不复用其他战斗截图或Runner。

## 冻结项

- G0已记录源码入口与配置不可达性，以及用户范围决定。
- G1-G6停止；未来若用户恢复任一流程，必须从G0重新冻结并取得当前Cocos动态证据。

## 遗留

- 自动生成的协议草稿和注册项仅作审计，不代表模块通过。
