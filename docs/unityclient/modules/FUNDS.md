# 全部基金

> 状态：`logic-validated-visual-deferred`，完成成长基金与活跃基金只读首期。

## 范围

- 成长基金：`function_id=25 → WelfareActivity.WelfareActivityUI(sub=5) → View.WelfareActivity.FundRebate → huodong/ChengZhangLayer`。
- 活跃基金：`function_id=26 → WelfareActivity.WelfareActivityUI(sub=6) → View.WelfareActivity.HuoyueLayer → huodong/HuoyueLayer`。
- 两页共用 `huodong/huodong_bg` 父框、顶部货币栏及福利活动页签。

## 三方证据

- 协议：`MSG_TMP_HUODONG /222`；成长基金 `op=83, opType=1`，活跃基金 `op=94, opType=1`。
- 服务端：`server/src/pack_deal.cpp` 的 `HD_LEVEL_JIJIN1`、`HD_HUOUE_JIJIN1`；配置源为活动奖励管理器，本地最小库无正式数据时仅在 `local_test=1` 返回确定性只读样例。
- Cocos：`LuaNetRecvdMsg.DealFundRebate` 解析基金档位、倍率、价格、总返利、等级/登录天数条件、领取状态和奖励。

## 实现

- `FundsStore/FundsCatalog` 同时保存 Growth(83) 与 Active(94) 两个权威页面。
- `FundsController.lua` 一次请求并完整解析两个分支；双回包全部提交后才完成验证。
- `FundsPresenter` 复用原版 `ChengZhangLayer/HuoyueLayer`，绑定前两档基金卡与奖励条件；福利父框扩展为体力、资源、成长、活跃四页签。
- 第一阶段购买和领取按钮全部禁用，避免误消耗；线上活动配置与写操作路径未改。

## 验证

- 命令：`Run-UnityModuleValidation.ps1 -Module Funds`。
- 结果：成长基金 2 档、活跃基金 2 档，双协议无未读字节；入口、父背景、四页签、货币栏、关闭/Esc 返回通过。
- GameView：`1334×750`，`build/ui-migration/bootstrap-funds.png`。
- 本地服务端：仅正式活动配置为空且 `local_test=1` 时提供两档×三阶只读回包；验证结束后 Unity、服务端和 workspace-local MySQL 已关闭。

## 遗留

- 购买、充值 SDK 跳转、基金奖励领取及写操作验证后置。
- 字体、奖励图标、多档横向滚动和像素级装饰按“可运行优先”口径后续人工细调；尚未通过 Cocos 同状态视觉 1:1 门禁。
