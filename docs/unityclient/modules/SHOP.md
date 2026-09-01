# 商城模块

## 当前结论

- 当前正式门禁：`G0-G4 passed / G5-G6 pending`；控件矩阵与旧G5-G6证据保留为重验输入，不再宣称当前收口。
- 旧“第一阶段完成”、账号 `7172217`、17 件商品、单次购买和旧截图只保留为实现线索，不能继承为本轮证据。
- 本轮范围固定为 `Shop / 基础商城 / type=1`，控件矩阵 `21` 项：`docs/unityclient/matrices/SHOP_CONTROLS.json`。

## G0 范围冻结

- 当前产品静态入口：
  - `Layer/Main_UI/ButtonGroup1/btn_shangcheng`：展开/收起 `tankuang1`。
  - `Layer/Main_UI/tankuang1/btn_shangcheng`：`Utils:OpenFunction(EMID_SCCHANGYONG)`。
  - `AppDef.moduleUI[EMID_SCCHANGYONG] = {lua="Shop.ShopUI", sub=1}`。
  - `ShopUI -> ShopPanel -> csd/shop/shangcheng.csb -> ShopTable/NormalShop/SelectedGood`。
- 当前页面控件：唯一“道具购买”Tab、三列动态商品与滚动、商品选择、数量减/加/输入、购买、一级框架货币加号和关闭。
- 公共弹窗控件：数字键盘、删除、确定、取消；目标要求的购买确认/取消、奖励项/关闭。
- 目标补齐项：手动刷新 `/221 op=3`、刷新次数/免费次数/倒计时。当前 Cocos type=1 未绑定该按钮，也未展示这些字段，G5 必须记录为“Unity 修复旧缺口”，但状态和扣费只能来自服务端。
- 排除：type=2..8 玩法商店、旧神秘/绑定/积分/帮贡/NPC/特供/神魄/砸蛋分支、充值/VIP/渠道支付。

## G2 协议与权威边界

- `/221 MSG_SHOP`：`op=1` 列表、`op=2` 购买、`op=3` 刷新、`op=4` 购买计数；`PRO_ERROR=0`、`PRO_SUCCESS=1`。
- 请求字段宽度已核定为 `u8 op,u8 type[,u16 tid,u16 num,u8 use]`；列表项为 `[u8 grid,u16 tid,u16 buyCount]`。
- 服务端入口：`CPackageDeal::ShopOption -> UserShopManager`。
- 当前 Cocos 解包：`LuaNetRecvdMsg.DealMsgShop`；成功购买后 type=1 自动重拉 `op=1`。
- C# 只能渲染 Lua/服务端权威状态，不得预扣货币、预增次数、伪造奖励或刷新结果。
- 配置 `60001` 的实际扣款映射为非绑定元宝 `60003`；G1 实测非绑定余额 `100000→99980`、绑定余额不变。
- type=1 配置为 `refresh_count=0,cost=[0],free_time=0,free_cd=0`，当前 `op=3` 只会返回“次数耗尽”。Unity 保留真实请求/错误解析，但刷新控件必须按权威配置禁用，不得伪造成功刷新。
- 完整字段表、短包规则和 G3 必修项：`.local/unity-validation/shop-g2-protocol-evidence.md`。

## 资源与实现现状

- 真实 Prefab：`unityclient/Assets/ProjectX/res/csd/Prefabs/shop/shangcheng.prefab`，只允许运行时绑定，不重建手工结构。
- 当前旧实现：`ShopStore + ShopCatalog + ShopPresenter + ShopController.lua`。
- 当前缺口：数量控件被 Unity 隐藏；无真实手动刷新按钮；旧 Runner 直接驱动确认流程且只覆盖 2 张截图；未登记控件 ID、语义断言、失败/重连/切号与固定账号恢复。

## 账号与夹具

- 固定视觉账号：`userId=7200057 / roleId=1000115`，原生 `1334×750`、Windows 100%。
- G1/G5 固定账号必须由 Shop 专用夹具执行：操作前快照、确定性商品/余额/次数注入、finally 精确恢复、恢复后哈希断言、重登录复核、夹具残留为 0。
- G4 写操作每次使用全新隔离角色，串行运行；禁止默认账号、旧账号和并发 Runner。

## G0 证据

- `tools/cocos-audit/generated/cocos-current-entry-inventory.json`
- `client/ProjectX/src/View/MainUI.lua`
- `client/ProjectX/src/core/AppDef.lua`
- `client/ProjectX/src/View/Shop/{ShopUI,ShopPanel,ShopTable,NormalShop,SelectedGood}.lua`
- `client/ProjectX/src/View/Common/InputNumUI.lua`
- `client/ProjectX/src/View/Background/FirstClassBg.lua`
- `client/ProjectX/src/NetWork/{LuaNetSendMsg,LuaNetRecvdMsg}.lua`
- `server/src/pack_deal.cpp`
- `server/src/user_shop_manage.cpp`
- `unityclient/Assets/ProjectX/res/csd/UnityMigration/documents/shop/shangcheng.json`

## G1 当前 Cocos 结果

- 固定账号 `7200057 / 1000115`，原生客户区 `1334×750`。
- 通过 Cocos 引擎原生 `GLView::handleTouches*` 后台触摸完成实际控件操作；未抢焦点、未移动真实鼠标、未直接调用 `Utils:OpenFunction`。
- 已覆盖：
  - 商城汇总展开、基础商城子入口、主界面金币加号、商城内金币加号、单次关闭返回。
  - 17 项商品列表、上下滚动、商品选择、详情、数量减/加、数字输入、删除、确定和取消。
  - 成功购买：商品 `1001×1`，元宝 `100000→99980`、角色金币 `1000000→1100000`、限购 `20→19`。
  - 失败购买：商品 `1015×200`，总价 `540000` 大于持有 `100000`，服务端提示“材料不足”，余额和购买计数不变。
  - 正常退出、重登录、真入口重进、夹具精确恢复、恢复哈希和夹具残留 0。
- 当前 Cocos 明确缺口：
  - `btn_Buy` 直接发送 `/221 op=2`，无二次确认。
  - type=1 无手动刷新按钮，也不展示刷新次数、免费次数和倒计时。
  - 成功购买无奖励弹窗。
  - `UserShopManager::GetShopMsg` 对空商品集合立即 `RefreshGrids`，当前 Cocos 不存在可保持的空态；Unity 必须补防御空态并清除旧数据。
- 证据总表：`.local/ui-fidelity/Shop/cocos/g1-20260728/G1_COCOS_EVIDENCE.md`。
- 固定账号结果与恢复：`.local/ui-fidelity/Shop/cocos/g1-20260728/shop-fixture-snapshot.json`。

## G3 Unity 逻辑实现

- `/221 op=1/2/3/4` 已由 Lua 维护单一 pending，并校验回包中的 `op/type/tid/num`。
- 数量减、加、真实 `EnterNumLayer` 数字键/删除/确定/取消已绑定；多数量价格按服务端累计百分比后一次截断。
- 购买先走公共确认，取消不发包，确认后才发送 `op=2`；奖励数量按权威回包与成交数量展示。
- type=1 刷新控件真实存在，但按当前 `refresh_count=0` 明确禁用；真实 `op=3` 错误链保留。
- `op=4` 购买次数、空态、重拉、超时、断线与切号清理已实现。
- Unity MCP 实测：`2022.3.62f3c1`、Bootstrap 场景空闲、无编译/Domain Reload、Console `0 error / 0 warning`。
- 证据：`.local/unity-validation/shop-g3-logic-evidence.md`。

## G4 隔离账号运行验收

- 最终 fresh isolated-role：`userId=7200123 / roleId=1000174`。
- `21/21` 真实控件、`5/5` 语义断言通过。
- `/221 op=1/2/3/4`、数量 `2`、购买取消/确认、余额不足、禁用刷新、购买次数、空态、重拉、关闭重进、断线重连和切号清理通过。
- `6/6` 原生 `1334×750` 截图均为本轮生成且 SHA-256 唯一。
- 结果：`.local/unity-validation/shop-latest.json`。

## G5 固定账号双端视觉验收

- 固定账号 `7200057 / 1000115`，Cocos/Unity 原生客户区均为 `1334×750`。
- 商品列表、数量键盘、滚动到底部、购买确认、购买奖励、重拉/重登共 `6/6` 状态通过。
- 修复了奖励弹窗被商城重拉层遮挡、商品行高 `150→115`、左栏文字截断，以及英雄阵容页面残留。
- 批准三项目标差异：Unity 增加购买确认、公共奖励弹窗，并明确显示 type=1 服务端配置为不可刷新。
- 快照、操作后恢复、重登录后恢复的哈希均为 `adabb7fcb1c9784356a98e1246074dad868ebe5c55dbb656230991beea302be0`，夹具残留 `0`。
- 证据：`.local/ui-fidelity/Shop/compare/g5-live-20260728/`。

## Steam SQLite S5（2026-08-20）

- 已通过：基础商城`type=1`同一8-case流程覆盖17项权威列表、`1001×1`成功购买、`op4`购买次数、重拉、`1015×200`余额不足拒绝、`refresh_count=0`刷新拒绝和最终状态；SQLite/MySQL运行态各55响应，重启拥有`/221`字节与语义一致。
- 持久化：`mysteryShop/package/mission/role_info.money`规范化哈希一致，`user_info1.money/bd_money`一致；非绑定元宝两端均`100000→99980`，购买次数重启后均为1。Shop隔离配置将登录元宝保底设为0，防止测试登录补款掩盖真实扣费；正式配置和业务分支未改。
- 清理：只删除隔离库`fxl_game_shop_s5_v1`；正式`fxl_game_local`及MySQL完整链路继续保留。证据：`.local/unity-validation/steam-sqlite-s5-shop-latest.json`。

## G6 收口

- 控件矩阵 `21/21 complete`，固定账号和隔离账号 Runner 均覆盖 `21/21` 控件与 `5/5` 语义断言。
- Python UI 解析测试 `16/16` 通过，Unity 运行日志无严重异常。
- 正式 `BootstrapSceneBuilder.BuildBatch` 连续两次 SHA-256 均为 `B27460DB36051DA396630CFF66EDED1115F3C3CB8148388F9574AA60A92D19AE`。
- 文档一致性和 G6 硬门禁通过；Shop 基础商城 type=1 本轮收口。
