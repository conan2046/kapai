# UnityClient 支付前置

> 状态：`planned-prerequisite`。当前仅冻结方案，未实现源码；P2 活动、全部基金、福利开始前必须优先完成。

## 1. 目标与边界

- 测试模式：玩家点击充值后不拉起第三方 SDK，直接向 `local_test=1` 本地服提交专用测试订单；只有服务端完成真实充值结算并回推成功，UI 才显示充值成功。
- 正式模式：只走目标平台第三方 SDK 的下单、支付、回调、服务端验单与到账流程；SDK 未接入或验单失败必须显示失败，禁止回退测试成功。
- 支付前置不计入 29 个业务模块分母；它是 P2 三个模块所有付费按钮的共同前置。

## 2. 现有源码基线

| 层 | 当前入口/职责 |
|---|---|
| Cocos 统一入口 | `client/ProjectX/src/Common/Utils.lua`：`Utils:Payment(money)` |
| Cocos Android/渠道 | `client/ProjectX/src/core/GameSdk.lua`：`U8Pay/QuickSDKPay` 等渠道调用 |
| Cocos iOS | `client/ProjectX/src/core/GameSdkIOS.lua`：`IAPPay`、receipt 回传 |
| Cocos订单协议 | `client/ProjectX/src/NetWork/LuaNetSendMsg.lua`：`QueryIAPOderId`、`QueryIAPInfoToServer` |
| 服务端充值入口 | `server/src/pack_deal.cpp`：`CPackageDeal::Charge`，协议 `PRO_CHARGE /84` |
| 服务端权威结算 | `server/src/main.cpp`：`CMainClass::ChongZhiSuccess`，统一处理元宝、基金、VIP、活动和每日首充 |
| 到账通知 | `server/src/utility.cpp`：`NoticeClientChargeResult`，协议 `MSG_CILENT_CHARGE /247` |

现有付费按钮至少包括：`RechargeUI.lua`、`FundRebate.lua`、`HuoyueLayer.lua`、`NewDiscountBagUI.lua` 中的 `Utils:Payment` 调用。G0 必须重新检索全部非注释调用，不能只覆盖此清单。

## 3. 编译宏与计划文件

- 互斥宏：`PROJECTX_PAYMENT_TEST`、`PROJECTX_PAYMENT_PRODUCTION`；必须且只能定义一个。
- 统一切换：计划新增 `tools/unity-migration/Set-UnityPaymentMode.ps1`，只修改 Unity 的支付编译符号，不允许各模块再建运行时布尔开关。
- Unity 统一入口：计划新增 `PaymentService`、`IThirdPartyPaymentSdk` 和 SDK 注册器；活动、基金、福利、充值/VIP及直购按钮全部调用同一入口。
- 构建保护：计划新增 `PaymentBuildGuard`；测试宏只能构建 Development Player，非 Development/正式包必须使用 Production 宏。

## 4. 测试模式服务端分支

- 在 `CPackageDeal::Charge` 增加专用测试支付类型、订单前缀和固定 receipt 标记，只允许 `server/config/config` 的 `local_test=1`。
- 点击后直接视为“测试支付完成”，但到账必须复用 `CMainClass::ChongZhiSuccess`；禁止客户端本地改元宝、VIP、基金或活动状态。
- 客户端以 `/247` 的订单号、金额和成功码作为最终成功依据；`/84` 仅表示请求已受理。
- 测试订单必须唯一、幂等、拒绝重复到账；正式服、Production 宏、非法标记和错误金额全部拒绝。

## 5. 正式模式 SDK 流程

`点击商品 → SDK下单/支付 → 平台回调 → 服务端验签验单 → ChongZhiSuccess → /247到账通知 → 目标模块重拉权威状态`

- SDK 适配器负责平台商品 ID、订单创建、取消、失败、恢复购买、回调和验签所需数据。
- 客户端 SDK 回调不能直接判定到账；只有服务端验单并发送 `/247` 才能刷新为成功。
- 未注册 SDK、回调超时、验签失败、订单金额/商品不匹配均失败，禁止调用测试分支兜底。

## 6. 按钮接线顺序

1. 先完成 `PaymentService`、双宏、构建保护、服务端测试分支和 `/84、/247` 协议闭环。
2. 接活动每日首充及其他充值活动按钮，成功后重拉 `/222` 权威状态。
3. 接成长/活跃基金购买按钮，成功后重拉 `/222 op=83/94`；奖励领取仍走基金自身服务端写操作。
4. 接福利中的充值、付费补领或直购按钮；无付费语义的免费领取不得经过支付服务。
5. 接充值/VIP页和折扣直购等剩余 `Utils:Payment` 等价入口。

## 7. 完成门禁

- 静态：双宏互斥且缺失即编译失败；Production 源码不包含自动成功回退；所有付费按钮只依赖统一支付入口。
- 测试模式：真实点击后服务端权威增加充值累计、元宝/VIP/基金/活动状态；重复订单不到账；失败、超时、断线、重连和切号隔离通过。
- 正式模式：至少提供一个目标平台 SDK 适配器的沙箱订单、取消、失败、验签到账证据；没有 SDK 时构建或运行明确失败。
- 数据：固定账号执行 snapshot → 测试支付 → `/247` → 目标模块重拉 → relogin → finally 精确恢复；Fixture 和测试订单残留为 0。
- 构建：测试宏非 Development 构建被阻断；Production 宏两次 `BootstrapSceneBuilder.BuildBatch` 幂等通过。
- 视觉：充值中、成功、失败/取消均取得同账号同状态 Cocos/Unity 证据；不得用静态截图证明支付结果。
