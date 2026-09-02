# 将魂商店模块（机器键 GameplayShops）

## 当前结论

- 当前正式基线为 `a35a7f264f5766526d9db18ce59bfa337dc5a33b`；工作区仅保留用户未跟踪的 `tmp/`，本模块不改基础商城 Prefab。
- 2026-09-02 按用户范围决策重开：只处理将魂商店 `function_id=15 / type=2`；玩法商店其他分支暂不修复。
- 当前 G0-G4 与用户早期真实 Play 已通过；固定账号批量验证为 29/29 控件、9/9 语义，SQLite 精确恢复且残留 0。按用户本轮免截图约定，G5-G6 保持 pending。2026-07 的 12 页、59 控件和 G5/G6 记录仅作诊断线索，不作为本轮证据。
- 机器矩阵：`docs/unityclient/matrices/GAMEPLAY_SHOPS_CONTROLS.json`；覆盖清单：`docs/unityclient/matrices/GAMEPLAY_SHOPS_COVERAGE.json`。

## 范围

- 当前入口闭包：
  - 主界面 `btn_shangcheng → tankuang1/btn_jianghun → EMID_SHOP_HUN=15`。
  - 招募页 `Layer/Shop` 与 `Layer/GoldCheck/GoldIcon2/AddBtn`。
  - 通用 `ItemSourceUI` 中所有 `item_source` 含 `15` 的跳转。
  - 封神列传奖励获取途径 `Button_2 → function_id=15`。
- 页面：`Shop.JiangHunShop → csd/shop/jianghunshop.csb`，公共框为 `shop/shop_bg`。
- 业务：`/221` 的 `op=1/2/3/4` 且 `type=2`；服务端随机返回六格，购买数量固定 `1`。
- 配置分母：`server/config/json/shop.json` 中 `type=2` 共 724 条，ID `2001–2724`、6 个格位、48 个奖励物品，成本为 `60014` 神魂或 `60001/60003` 元宝链。
- 排除：基础商城 `type=1` 继续归 `Shop`；竞技、血战、昆仑、帮派以及转盘/其他玩法商店均不进入本轮。

## 三方证据

- Cocos：`MainUI.lua`、`HappyDrawUI.lua`、`ItemSourceUI.lua`、`JiangHunShop.lua`、`AppDef.lua`。
- 服务端：`protocol.h` 的 `MSG_SHOP=221`，`pack_deal.cpp` 注册与处理，`user_shop_manage.cpp` 商店状态，`shop.json/shop_config.json`。
- Unity：`GameplayShopController.lua.txt → GameplayShopStore → GameplayShopsPresenter → ProjectXApp.HandleCommerceRoute(15)`。
- 当前协议提取：`.local/protocol-evidence/221.md`。

## 协议与权威边界

| op | 请求 | 成功结果 | 失败结果 |
|---:|---|---|---|
| 1 | `type=2` | 刷新次数、免费次数、恢复秒数及六格 `grid/tid/buyCount` | `success=0 + reason`；短包/静默必须超时失败 |
| 2 | `type=2,tid,num=1,use=0` | `buyCount,rewardType,rewardUnitNum`，货币/背包由权威增量同步 | `success=0 + reason`，不得本地预扣或改已购态 |
| 3 | `type=2` | 完整新列表；免费次数优先，否则刷新令 `400×1` | 失败不换列表、不扣次数/道具 |
| 4 | `type=2,tid` | 权威 `buyCount` | 失败释放 pending 并明确反馈 |

- `/221` 与基础商城共享：将魂控制器只消费自己发起且 `op/type/tid/quantity` 精确匹配的 pending，不得串读 `type=1`。
- 724 条配置只用于补充名称、图标、成本、折扣和限购语义；运行列表只能来自服务器六格，禁止客户端补货。
- 购买不在 C# 预判业务成功；服务端失败前后货币、背包与 `buyCount` 必须原子不变。
- `CurrencyStore`、`BagStore`、`ServerTime` 与回包重拉共同驱动可见刷新；倒计时按秒变化并在重连后重建。

## G0 范围冻结

- `workflowPolicyVersion=1`、`hardGateVersion=3`。
- 直接控件 21：4 类入口、公共关闭/帮助、神魂详情、6 个物品详情、6 个购买按钮、刷新。当前 Cocos 证明招募页 GoldIcon2 加号属于道具兑换；`yuanbao/add` 无可见可达运行态，二者不计入当前分母。
- 场景状态 8：权威六格、折扣/已购、刷新状态、购买成功、余额不足、刷新成功、返回/重连、切号。
- 固定 Unity 早测身份为 `7200057/1000003`，数据只能来自 `Application.persistentDataPath/LocalServer/projectx.db`；任何 MySQL 夹具不能替代用户测试数据。

## G1-G3 当前结果与退出条件

- G1：当前原生 `ProjectX.exe / Cocos Simulator` 已冻结六格、帮助、神魂详情、物品详情、主界面入口与招募底部商城入口；GoldIcon2 实测为道具兑换，已移出本模块。
- G2：关闭入口、共享协议所有权、724 配置到48物品/图标资源、Prefab运行时 Transform、事件监听和返回栈已审计；当时登记的 SQLite/G3 缝隙已在 G3 解决。
- G3：运行时 Lua/Presenter/ProjectXApp 已收窄到 type=2；补神魂详情、秒级倒计时、服务端权威失败和返回生命周期。SQLite `7200057/1000003` 登录预检、整库 SHA 精确恢复、Unity 编译指纹与298项中央工具回归通过；未修改任何 Prefab。
- 早测不替代 G4-G6；G6 最终确认仍必须由用户在最后一次相关变更后完成。

## 已知风险

- 固定账号合同和夹具已切换为 persistentDataPath SQLite direct-hex 六格格式；旧多页 Runner 的休眠实现不得用于 G4-G6，后续正式 batch 必须继续只覆盖 type=2。
- 旧 Presenter 保留玩法商店多页代码；本轮可保留为休眠兼容，但路由、请求、场景和验收不得触发其他类型。
- Cocos `JiangHunShop.updateData` 在回包少于六格时会从配置补齐；Unity 按当前迁移硬标准不复制这一客户端伪造行为，空/短列表作为受控差异在 G1/G2 明确。
