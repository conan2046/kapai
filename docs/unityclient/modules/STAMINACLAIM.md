# 体力领取模块

## 范围

玩法大厅 `function_id=18` 对应福利活动的体力领取页。首期覆盖真实三档领取时段、奖励数量、免费/补领/不可领/已领状态、入口和返回；领取写操作禁用。

## 三方证据

- 当前入口：`AppDef.EMID_ACTIVITY_Tili_REVERT=18` → `WelfareActivityUI` → `ReceiveTiliUI`。
- 当前 Prefab：父层 `huodong/huodong_bg.csb` + 子层 `huodong/tililingquLayer.csb`，Unity 复用对应两个真实 Prefab。
- 协议：`/321 MSG_SPIRIT`；`op=1` 体力信息，`op=2` 免费体力状态，`op=3` 领取。
- `op=2` 响应：`op, success, count, [index,state]`；状态 `0不可领取/1免费领取/2元宝补领/3已领取`。
- 服务端处理：`CPackageDeal::DealSpirit` → `CUserSpirit::MakeFreeSpiritMsg/GetFreeSpirit`。
- 权威配置：`server/config/json/stamina.json`，三档为 `12:00-14:00`、`18:00-20:00`、`21:00-22:00`，每档 50 体力，补领 20 元宝。

## 实现

- `StaminaClaimStore` 缓存 `/321 op=2` 返回的三档权威状态。
- `StaminaClaimCatalog` 固化当前服务端三档展示配置；奖励值采用服务端 50，不采用旧客户端过期的 100。
- `WelfareActivityFramePresenter` 补齐 Cocos 公共背景、左侧体力/资源页签和顶部货币栏；`StaminaClaimPresenter` 绑定真实子层时段、奖励与状态。
- `StaminaClaimController.lua` 仅在页面主动请求期间消费 `/321 op=2`，不干扰主界面 `op=1` 体力同步。
- 首期只读：三个领取按钮均显示当前状态但禁用，避免自动化消耗角色体力或元宝。

## 功能验证

- 通过命令：`pwsh -File tools/unity-migration/Run-UnityModuleValidation.ps1 -Module StaminaClaim`。
- 结果：`COMPLETE`；三档权威状态完整、协议无未读字节、父背景/页签/货币栏和真实子页可见、Esc/关闭返回玩法大厅，Python UI migration 测试 16/16、严重异常 0。
- 截图：`build/ui-migration/bootstrap-stamina-claim.png`，固定 `1334×750`。

## 视觉 1:1 记录

- 当前状态：`pending-cocos-baseline`。
- 主布局与位置优先；字体、动画和像素级装饰按用户要求后续手调。

## 遗留项

- `op=3` 免费领取、20 元宝补领、体力上限错误和领取后权威回查。
- 主界面 `op=1` 体力恢复倒计时的独立深化。
- Cocos 同账号基准、节点映射和差异报告。
