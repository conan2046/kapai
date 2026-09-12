# 摇钱树模块

> 当前状态：源码/配置/协议闭包已定位，Unity运行实现已完成静态编译；真实Play、服务端回包和玩家验收待执行。

## 范围与入口

- 入口：玩法大厅 `function_id=23`；名称、开放等级、图标、描述来自正式 `function.xlsx` 生成链。
- UI：`huodong/GoldTreeLayer.prefab`；当前Cocos实际只展示并刷新金币树 `type=1`。
- 不包含：贵族界面迁移、绑元树扩展、帮派种植、神树。

## 权威数据与协议

- 请求：`/222`，活动操作码 `17`；子操作 `1` 查询，`2 + treeType:u8` 摇取。
- 查询回包：`success:u8, count:u8`，随后每项为 `type/useNum/freeNum/maxNum/costType/costValue/getType/getValue`。
- 摇取回包：`treeType:u8, success:u8`，成功后返回同一份最新记录。
- 服务端：`server/src/pack_deal.cpp` 的 `HD_YAO_QIAN_SHU`；奖励/消耗阶梯读取 `server/config/xml/yaoqianshu.xml`，免费次数读取 `server/config/json/vip.json`。
- 旧客户端：`LuaNetSendMsg.SendMoneyTreeReq`、`LuaNetRecvdMsg.DealMsgYaoQianShu`、`View/Activity/MoneyTreeUI.lua`。

## Unity实现

- `MoneyTreeController.lua.txt` 独占 `/222 op=17` 的读写和消息游标。
- `MoneyTreeStore.cs` 保存服务端回包快照与单次请求pending，不计算奖励、概率或次数。
- `MoneyTreePresenter.cs` 只绑定Prefab已有文本和按钮；收益、消耗、免费/总次数均直接渲染服务端数据。
- `/222` 在Bootstrap按顶层操作码统一分发给 MoneyTree/Funds/TempActivity，避免共享消息被错误控制器提前读取。
- `function-routes.json` 决定目标Controller与Prefab key；业务代码不按功能ID硬编码Prefab。

## 待验证

- 从HUD真实点击玩法 → 摇钱树，确认层级、关闭返回和无界面叠加。
- 查询正常/失败、免费摇取、付费摇取、次数耗尽、断线/重连、切号隔离。
- 核对摇取前后服务端/SQLite权威货币变化与UI最新记录。
- 用户最终真人Play确认前不得设置 `manualPassed=true`。
