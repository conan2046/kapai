# 资源找回模块

## 范围

玩法大厅 `function_id=19` 对应福利活动的资源找回页。首期覆盖权威可找回列表、次数、单次元宝成本、奖励容器、活动公共背景/页签/货币栏、入口和返回；找回写操作禁用。

## 三方证据

- 当前入口：`AppDef.EMID_ACTIVITY_REVERT=19` → `WelfareActivityUI(sub=2)` → `FindOfflineExp`。
- 当前 Prefab：父层 `huodong/huodong_bg.csb`，子层 `huodong/ziyuanzhaohui.csb`；Unity 复用对应两个真实 Prefab。
- 协议：`/52 PRO_FIND_RESOURCE`；`op=1` 查询列表，`op=2` 指定玩法找回，`op=3` 旧服务端分支已注释。
- `op=1` 响应：`op, count, [funcId:uint32, leftTimes:uint16, cost:(uint16,uint32,uint32), rewardCount:uint8, rewards...]`。
- 服务端处理：`CPackageDeal::FindResourceOption` → `CUser::ShowFindResourceMsg/BuyFindResource`。
- 权威配置：`server/config/json/revert.json`；名称、等级段、成本及奖励均以服务端为准。
- 本地角色真实回包：7 条可找回记录，包含封神列传、决战昆仑、血战到底、法宝搜索及试炼资源。

## 实现

- `ResourceRecoveryStore` 保存 `/52 op=1` 权威记录、成本和多奖励。
- `ResourceRecoveryCatalog` 提供当前 `revert.json` 的玩法名称映射。
- `WelfareActivityFramePresenter` 复用 Cocos 公共活动背景、两枚左侧页签及顶部体力/金币/元宝栏。
- `ResourceRecoveryPresenter` 基于真实列表模板构建可滚动列表；首期找回按钮禁用。
- `ResourceRecoveryController.lua` 请求并严格消费 `/52 op=1`，存在未读字节即失败。

## 功能验证

- 命令：`pwsh -File tools/unity-migration/Run-UnityModuleValidation.ps1 -Module ResourceRecovery`。
- 结果：`COMPLETE`；7 条权威记录、协议无未读字节、真实页面与滚动列表可见、Esc/关闭返回玩法大厅。
- GameView：`build/ui-migration/bootstrap-resource-recovery.png`，固定 `1334×750`。
- Python UI migration：16/16；严重异常 0；验证后 MySQL、服务端和 Unity 均已关闭。

## 遗留

- `/52 op=2` 指定次数购买、扣款错误、奖励入包与权威回查。
- 奖励图标和文本的像素级排版、Cocos 同账号基准及差异报告。
- `op=3` 当前服务端不可用，不迁移伪功能。
