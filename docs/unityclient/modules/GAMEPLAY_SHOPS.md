# 将魂/竞技场/血战商店模块

## 范围

玩法大厅 `function_id=15/16/17` 对应的三类商店一次迁移。首期覆盖权威商品列表、页签、购买次数/限购、价格/折扣、持有货币、将魂刷新次数与倒计时、入口和返回；购买、刷新写操作首期禁用。

## 三方证据

- 当前入口：`AppDef.EMID_SHOP_HUN=15` → `Shop.JiangHunShop`；`16/17` → `Shop.WanFaShopMainUI`。
- 当前 Prefab：`shop/jianghunshop.csb`、`shop/wanfashop.csb`。
- 协议：`/221 MSG_SHOP`，`op=1` 查询、`op=2` 购买、`op=3` 刷新。
- 协议页：将魂 `type=2`；竞技场商品/奖励 `type=3/4`；血战初/中/高装备及奖励 `type=5/6/7/8`。
- 列表响应：`type,success,refreshTimes,freeTimes,refreshRemaining,count,[grid,tid,buyCount]`。
- 权威配置：`server/config/json/shop.json`、`shop_config.json`、`item.json`。

## 实现

- `GameplayShopStore` 按协议类型缓存 7 个权威页面，避免切页覆盖基础商城或重复伪造数据。
- `GameplayShopsPresenter` 复用真实 `jianghunshop/wanfashop` 主布局，渲染将魂 6 格、竞技 2 页和血战 4 页。
- `GameplayShopController.lua` 独占自己发出的 `/221` 请求；未激活时把协议继续交给原 `ShopController`，基础商城链路不变。
- `ProjectXApp.EnterGameplay(15/16/17)` 接通当前玩法大厅入口、UiStack 返回、页签请求和三态截图。
- 首期只读：购买与将魂刷新按钮显示但禁用，避免自动化消耗正式角色资源。

## 功能验证

- 通过命令：`pwsh -File tools/unity-migration/Run-UnityModuleValidation.ps1 -Module GameplayShops`。
- 结果：`COMPLETE`；`/221 type=2..8` 七页共返回 74 条权威商品，协议无未读字节，三类页面可见、商品图标缺失为 0，Esc/关闭可返回玩法大厅。
- 回归：Python UI migration 测试 16/16 通过，Unity 日志严重异常 0；校验退出后自动关闭本次启动的 MySQL、`kapai.exe` 与 Unity。
- 截图：`bootstrap-gameplay-shop-jianghun.png`、`bootstrap-gameplay-shop-arena.png`、`bootstrap-gameplay-shop-blood.png`，固定 `1334×750`。

## 视觉 1:1 记录

- 当前状态：`pending-cocos-baseline`。
- 真实主布局与位置优先迁移；字体、模型、动画、像素级装饰按用户要求延后手工调整。

## 遗留项

- 购买确认、实际扣款/奖励和购买后权威回查。
- 将魂免费刷新、刷新令消耗、次数恢复完整闭环。
- 竞技/血战条件文本、红点和奖励页深度表现。
- Cocos 同账号基准、节点映射和差异报告。

## 关键坑

- `/221` 同时服务基础商城与玩法商店；控制器必须只消费自己发出的请求，否则基础 `ShopController` 会读错游标。
- 竞技商店实际是 `type=3/4` 两页，血战商店实际是 `type=5/6/7/8` 四页，不能只按功能 ID 各迁一个页面。
- 将魂配置约 724 条候选，服务端只返回本角色当前随机 6 格；Unity 必须以回包 `tid` 为权威，不能直接全量展示配置。
