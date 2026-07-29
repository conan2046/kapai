# 玩法商店模块

## 当前结论

- G0-G6 已通过；Runner `59/59` 控件与 `9/9` 语义断言有效。六页视觉修复、同数据重拍、人工逐页验收、完整回归和 Bootstrap 幂等均完成。
- 固定账号 `7200057 / roleId=1000115` 完成真实 `/221 op=1/2/3/4`、12 页面、购买/刷新/次数、成功/失败、重拉/重进/重连/切号及精确恢复。
- 原生 `1334×750` 的六页双端证据已重拍；结构错位、错资源和文字裁切/重叠均为 `0`，剩余像素差来自 JPEG/PNG、字体光栅和透明边缘混合。
- `BootstrapSceneBuilder.BuildBatch` 已重新连续执行两次，SHA-256 均为 `53939A9C337FE4E853EC9869BBB0324FC145FEEFB41E0071AC1E7DF9E569B9EE`。
- 本模块只声明兑换商店的查询、交互、消费和恢复闭环；父玩法的资源产出链在所属玩法模块迁移前不作完成声明。
- 机器矩阵：`docs/unityclient/matrices/GAMEPLAY_SHOPS_CONTROLS.json`。

## 范围

当前真实入口为主界面 `btn_shangcheng → tankuang1/btn_jianghun 或 btn_wanfa`，另含竞技场与血战页面的替代入口。覆盖将魂 `type=2`、竞技场 `type=3/4`、血战 `type=5/6/7/8`、昆仑 `type=23`、帮派 `type=25/26`、转盘 `type=27/28` 的列表、页签、购买次数/限购、价格/折扣、持有货币、将魂刷新、购买弹窗、奖励/详情、入口、返回、失败与生命周期。

基础商城 `type=1` 由 `Shop` 模块负责；充值、VIP 与渠道支付不属于本模块。

## 三方证据

- 当前入口：`MainUI.shopTouchCallback → tankuang1/btn_jianghun → AppDef.EMID_SHOP_HUN=15 → Shop.JiangHunShop`；`tankuang1/btn_wanfa → EMID_SHOP_JINGJI=16 → Shop.WanFaShopMainUI(sub=1)`；血战页入口 `EMID_SHOP_XUEZHAN=17 → Shop.WanFaShopMainUI(sub=2)`。
- 当前 Prefab：`shop/jianghunshop.csb`、`shop/wanfashop.csb`。
- 协议：`/221 MSG_SHOP`，`op=1` 查询、`op=2` 购买、`op=3` 刷新。
- 协议页：将魂 `type=2`；竞技场商品/奖励 `type=3/4`；血战初/中/高装备及奖励 `type=5/6/7/8`；昆仑 `type=23`；帮派/精魄 `type=25/26`；转盘积分/元宝 `type=27/28`。
- 列表响应：`type,success,refreshTimes,freeTimes,refreshRemaining,count,[grid,tid,buyCount]`。
- 权威配置：`server/config/json/shop.json`、`shop_config.json`、`item.json`。

## G2 协议与数据契约

协议号：`MSG_SHOP=221`。服务端原样保留请求字段作为响应前缀，因此 Unity 必须按下表精确读取，失败分支不得继续读取成功字段。

| op | 请求体（不含协议号） | 成功响应（响应首字节仍为 op） | 失败响应 |
|---:|---|---|---|
| 1 查询 | `byte type` | `byte type, byte success, ushort refreshTimes, byte freeTimes, ushort remainingSec, byte count, count × (byte grid, ushort tid, ushort buyCount)` | `type, success=0, string reason`；配置/商店不存在时服务端当前可能只回显请求，客户端必须按 pending/超时硬失败 |
| 2 购买 | `byte type, ushort tid, ushort num, byte use` | 回显请求字段后：`byte success, ushort totalBuyCount, ushort awardType, uint awardUnitNum` | 回显请求字段后：`success=0, string reason` |
| 3 刷新 | `byte type` | 与 op=1 相同的完整列表体 | `type, success=0, string reason` |
| 4 查购买次数 | `byte type, ushort tid` | 回显请求字段后：`byte success, ushort buyCount` | 回显请求字段后：`success=0, string reason` |

服务端购买语义：

- `num` 上限被服务端钳制到 `10000`；限购按当前 `cnt` 与配置 `count[2]` 判断。
- 购买条件由 `CheckUserCond(buyCond)` 判定；失败分别覆盖已售罄、条件未达、货币不足。
- 价格按当前累计购买次数对应的 `price_real` 百分比逐次累加，不能用 `unitCost × num` 代替。
- 成功后先扣真实 `MultiCost`，再增加 `award.num × num`，回包的 `awardUnitNum` 是单次配置数量，不是总奖励数。
- `use=1` 会在发奖后立即使用物品；本模块默认发送 `0`，只有明确需要时才允许启用。
- op=3 只对将魂 `type=2` 开放；优先消耗免费次数，否则消耗刷新令 `400×1`，并返回完整新列表。

页面与货币：

| 页面 | type | 主要货币 |
|---|---:|---:|
| 将魂 | 2 | `60014` 神魂、`60001/60003` 元宝；刷新令 `400` |
| 竞技商品/奖励 | 3/4 | `60050` 竞技积分 |
| 血战一/二/三层、奖励 | 5/6/7/8 | `60025` 星宿精华 |
| 昆仑 | 23 | `60051` 昆仑币 |
| 帮派/圣灵 | 25/26 | `60021` 帮贡、`60054` 圣灵货币 |
| 转盘积分/元宝 | 27/28 | `60056` 转盘积分、`60001/60003` 元宝 |

`60001` 是旧配置展示 ID，服务端实际元宝扣款链还会更新 `60003`；Unity 必须以登录/增量协议的真实余额为权威，G4 需对扣款前后两者做硬断言，禁止只看图标或客户端预测值。

## G2 所有权与实现边界

- Lua `GameplayShopController` 独占自己发起的 `/221` pending，并拥有请求队列、op/type/tid/num/use、回包游标、错误、超时、刷新/重拉/重连与切号清理。
- Lua 只在 pending 精确匹配时消费 `/221`；否则返回 `false` 交给基础 `ShopController`，不得串读 `type=1`。
- C# `GameplayShopStore` 只保存服务器回包形成的 12 个页面缓存；配置只补名称、图标、条件文本、价格阶梯和显示规则，不能生成服务器未返回的商品。
- C# `GameplayShopsPresenter` 只负责真实 Prefab 节点绑定、滚动、页签、详情、数量弹窗、公共奖励/Toast 与控件证据；点击动作回调 Lua，禁止直接改货币、购买次数或背包。
- 购买成功后先应用回包购买次数与权威货币/背包增量，再重拉当前 type；失败只展示服务端原因，不做乐观扣款。
- `ItemBuyUI`：`leftTimes==1` 直接购；`leftTimes>1` 打开数量弹窗并限制为 `1..leftTimes`；无限购使用客户端显示上限但最终由服务端钳制/校验。
- 关闭、断线、重连、切号必须清空 pending、弹窗、临时选择、页面缓存与验证队列；基础 Shop Store 不能被清空或覆盖。
- 转盘入口等级锁属于路由边界；未满 99 级显示原生语义 Toast，满级后加载 `type=27/28`，两个状态都必须进入后续证据。

## 实现

- `GameplayShopStore`、`GameplayShopController.lua` 和 Runner 已覆盖 12 个页面，并将 `type=1` 基础商城留给原 `ShopController`。
- `GameplayShopsPresenter` 复用真实 `jianghunshop/wanfashop` 内容布局与 `shop/shop_bg` 原生框架，渲染将魂 6 格及全部玩法商店页面。
- `GameplayShopController.lua` 独占自己发出的 `/221` 请求；未激活时把协议继续交给原 `ShopController`，基础商城链路不变。
- `ProjectXApp.EnterGameplay(15/16/17)` 接通入口、UiStack 返回、分类/子页签请求和六态截图。
- 购买、数量弹窗、将魂刷新、详情、奖励与公共反馈均接真实回调；客户端不做乐观扣款。

## 功能验证

- 本轮 G0 证据：当前入口库存、控件候选、MainUI/AppDef、JiangHunShop/WanFaShopMainUI/WanFaShopDelegate、ItemBuyUI、`/221` 服务端处理和两份真实 Prefab。
- 本轮 G1：固定账号 `7200057 / roleId=1000115` 已完成原生动态取证。证据 `.local/ui-fidelity/GameplayShops/cocos/g1-20260729/G1_COCOS_EVIDENCE.md` 及同目录 `00-main-native.jpg` 至 `17-arena-insufficient-native.jpg`。
- G1 可逆性：误触将魂直购后，元宝、背包和 `shenhunShop` 均按快照精确恢复；重登录后背包解压非零字节数为 `0`，残留为 `0`。
- G2：`.local/protocol-evidence/GameplayShops-221.md` 与 `.local/unity-validation/gameplay-shops-g2-protocol-evidence.md`。
- G3：最终编译指纹见 `.local/unity-validation/unity-compile-preflight-latest.json`。
- G4：先通过匹配账号/适配器 SHA/需求指纹的 `DataPreflightOnly`，再完成正式固定账号验证；结果 `.local/unity-validation/gameplayshops-fixed-account-latest.json`。
- G4 结果：真实购买 `type=28,id=28001,quantity=25`、权威重拉 `buyCount=25`、售罄重复拒绝、余额不足、条件不足、重复 pending、将魂免费刷新均通过；`59/59` 控件、`9/9` 语义。
- G5：`.local/ui-fidelity/GameplayShops/cocos/g5-20260729/`、`.local/ui-fidelity/GameplayShops/unity/g5-20260729/`、`.local/ui-fidelity/GameplayShops/compare/g5-live-20260729/report.json`、`manual-acceptance.json` 与 `G5_VISUAL_ACCEPTANCE.md`。
- G6：`.local/unity-validation/gameplay-shops-g6-evidence.md`、`.local/unity-validation/gameplayshops-latest.json`、`.local/unity-validation/bootstrap-idempotence-latest.json`；6/6 截图、59/59 控件、9/9 语义及双次 BuildBatch 通过。
- 恢复：固定账号原始哈希 `e9850155b76b5de9b9cd417612ed1c524f67de4dfa571fefec4b257b15707263`，重登录复核通过，fixture 行数为 `0`。

## 视觉 1:1 记录

- 当前状态：`same-data-g5-passed / G6-passed`。
- 六组同账号、同确定性数据、同 `1334×750` 的 Cocos/Unity 原图、并排、叠加和差异报告已完成。
- 修复项：替换错误 `OneLevelLayer` 外框，恢复 `shop/shop_bg`、菱形导航、正确页签和公共层；补齐真实品质框、物品数量、刷新令、碎片角标与合成计数；修正 940/955 宽行模板居中造成的 7.5 px 偏移及名称/合成数字对齐。

## 模块外边界

- 竞技、血战、帮派、昆仑、转盘等父玩法的资源产出不属于本模块；后续迁移对应玩法时再验证“玩法产出 → 商店兑换 → 消费”的端到端闭环。
- 充值、VIP、渠道支付继续后置；元宝加号只保留明确边界，不伪造支付入口。

## 关键坑

- `/221` 同时服务基础商城与玩法商店；控制器必须只消费自己发出的请求，否则基础 `ShopController` 会读错游标。
- 完整固定账号验证与 VisualOnly 拆跑时，G6 摘要必须按账号、角色、源码指纹、G5 指纹和逐图 SHA 合并视觉证据；仅有业务摘要或仅有截图摘要都不能通过。
- 竞技商店实际是 `type=3/4` 两页，血战商店实际是 `type=5/6/7/8` 四页，不能只按功能 ID 各迁一个页面。
- 将魂配置约 724 条候选，服务端只返回本角色当前随机 6 格；Unity 必须以回包 `tid` 为权威，不能直接全量展示配置。
- 当前固定角色为 60 级，转盘入口原生显示 `99级开启此功能`；G4/G5 必须通过可逆数据预演同时覆盖锁定态与解锁后的 `type=27/28`，不得把锁定截图当作双页面完成。
- `ShopCatalog` 的展示数据不能替代服务端累计价格、条件和限购判断；任何新增商店类型仍需以 `/221` 权威回包为准。
