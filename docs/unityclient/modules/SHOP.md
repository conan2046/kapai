# 商城模块

## 范围

基础商品列表、购买次数/限购、刷新倒计时、货币、购买确认、单次购买、奖励和持久化复查。

## 三方证据

- 协议：`/221 MSG_SHOP`。
- `op=1`：列表；`op=2`：购买；`op=3`：刷新；`op=4`：计数。
- 列表响应：请求回显、成功、刷新次数/剩余、商品 `[grid, tid, buyCount]`。
- 购买请求：`op,type,tid,num,use`；响应追加成功、总购买次数、奖励类型和数量。
- 权威配置：`server/config/json/shop.json`、`item.json`。

## 实现

- `ShopStore + ShopCatalog + ShopPresenter + ShopController.lua`。
- 入口：`Layer/Main_UI/ButtonGroup5/btn_shangcheng`、`tankuang1/btn_shangcheng`。
- 真实 Prefab：`shop/shangcheng.prefab`，未被自动化重写。
- 三列 VirtualList，复用 Resource、ServerTime、Currency、Reward、MessageBox、UiStack。
- 服务端实际将配置货币 `60001` 通过 `AddTongBao(type=0)` 扣为非绑定元宝 `60003`；Unity 按真实余额展示，未修改服务端。

## 已验证

- 17 件基础商品，缺图 `0`。
- 隔离角色 `7172217` 商品 `1001` 严格购买一次。
- 元宝 `100000→99980`、购买次数 `0→1`、金币奖励 `100000`。
- 再次 `op=1` 确认次数持久化为 `1`。
- `Tundra build success`，无 C# warning、无实际严重运行异常。
- 列表与购买确认截图均为 `1334×750`。

## 关键坑

- Unity.exe 调用可能异步返回；必须 `Start-Process -Wait`。
- 同一角色并发 Runner 会重复购买；最终证据必须使用全新角色串行执行。
- 购买按钮原 Prefab 文本不稳定，运行时创建确定性居中文字。

## 遗留

- `op=3` 手动刷新、特殊商店、错误/空态/断线组合、刷新成本与次数完整表现。
