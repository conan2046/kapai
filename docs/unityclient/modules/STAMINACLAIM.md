# 体力领取（StaminaClaim）

## 当前结论

- 本轮已严格完成 G0-G6；2026-07-18 首期截图、Runner、完成标记仅作线索，未计入本轮证据。
- 模块拥有 `/321 op=2/3` 的三档状态查询与真实领取；共享 `/321 op=1` 仍归 PlayerHud 的体力显示/恢复倒计时。
- 旧 Unity `read-only first phase`、禁用三档按钮和 `mutatesServer=false` 结论作废。
- 固定主/不足元宝/体力上限账号均完成预检、快照、恢复、重登录哈希和残留 0 闭环；16/16 控件、13/13 语义、8 组双端稳定帧与两次真实 BuildBatch 均通过。

## G0 范围

- 入口：`MainUI.btn_wanfa → Utils:OpenFunction(EMID_WANFA) → WanFaEntranceUI function_id=18/EnterBtn（或 WanFaInfoUI/EnterBtn） → Utils:InitUI(WelfareActivityUI, SpecialLayer, 1) → ReceiveTiliUI`。G1 已实证 `EMID_HUODONG=18` 枚举冲突，玩法入口必须定向，不能走活动空列表分支。
- 页面：`csd/huodong/huodong_bg.csb` 公共福利框 + `csd/huodong/tililingquLayer.csb` 体力页。
- 在册：真实入口、关闭、体力/资源找回页签、体力/金币加号、禁用通宝加号、三档领取按钮、补领确认/取消、体力红点、三类权威货币显示，共 16 项。
- 状态：三档时段；`0不可领取/1免费领取/2元宝补领/3已领取`；奖励/体力变化；补领扣款；满体力上限；重复领取；返回重进；断线重连；重登录持久化；切号隔离。
- 固定主账号：`7200057/1000115`；隔离账号：`705213/1000006`；Windows 100%，原生客户区 `1334×750`。
- 排除：`/321 op=1` 的恢复倒计时深化、体力使用/购买页业务、金币商城业务、资源找回页业务；仅验证其可见入口/路由边界与返回无串页。

## 当前三方源码证据

- Cocos：`ReceiveTiliUI:initData` 发 `/321 op=2`；三个 `Button_bg` 绑定 `GetTiliEvent`；免费发送 `op=3,idx,0`，补领确认发送 `op=3,idx,1`；成功后更新体力、该档置 3、显示奖励提示并刷新红点。
- 协议：`LuaNetSendMsg:QueryTiLiInfo` 写 `op[,idx,type]`；`LuaNetRecvdMsg.DealTili` 读取 `op=2` 三档或 `op=3 receiveType/idx/error/[stamina|string]`。
- 服务端：`CPackageDeal::DealSpirit → CUserSpirit::MakeFreeSpiritMsg/GetFreeSpirit`；免费加 50，补领扣 `60001×20` 后加 50；上限、未到时、未确认补领、余额不足、重复领取均由服务端拒绝。
- 配置：服务端 `stamina.json` 为 `12:00-14:00 / 18:00-20:00 / 21:00-22:00`、每档 50、补领 20；当前 Cocos 生成配置仍显示 100，属于必须在 G1 取证并在 G2 明确处理的源差异。
- 持久化：`role.user_spirit` 压缩保存 `m_spirit/m_lastSpiritTime/m_freeGetState[1..3]`；账号元宝在用户货币字段中。

## 门禁状态

| Gate | 状态 | 退出条件 |
|---|---|---|
| G0 | passed | 16/16 矩阵、workflowPolicyVersion=1、7 个 given/when/then、机器门禁已通过 |
| G1 | passed | Computer Use 操作当前原生 Cocos Simulator，取得玩法真实入口、全部控件和状态证据 |
| G2 | passed | 入口/协议/配置/资源/Transform 闭包与 Cocos 100、服务端实际 50 差异已冻结 |
| G3 | passed | Unity 真按钮、`/321 op=2/3` 权威渲染、三账号可逆 Fixture 与 DataPreflight 完成 |
| G4 | passed | 正式 fixed-account batch 覆盖领取、拒绝、重进、重连、持久化和切号隔离 |
| G5 | passed | 8 组同账号同数据同步骤原图、并排、叠加、增强差异和报告完成 |
| G6 | passed | 16/16 控件、13/13 语义、严重错误 0、Fixture 残留 0、台账未解决 0、双次 BuildBatch 通过 |

## 证据合同

- 所有状态必须使用当前原生 Cocos 与正式 Unity batch 产物；旧 `bootstrap-stamina-claim.png` 不得复用。
- Fixture 必须快照主/隔离账号的 `user_spirit`、角色/账号货币和身份绑定；setup/preflight/restore/relogin hash/cleanup residual=0 全链闭环。
- G4/G6 只接受中央 batch Runner；G5 必须生成同账号、同数据、同步骤、同稳定帧的原图、并排、50%叠加、增强差异与报告。

## 本轮收口证据

- 正式摘要：`.local/unity-validation/staminaclaim-fixed-account-latest.json`；`success=true`，原生 `1334×750`，16 项控件、13 项语义全通过。
- Fixture：主账号 `7200057/1000115`、不足元宝账号 `705213/1000006`、上限账号 `7200260/1000119`；恢复哈希分别为 `195d412daf2bfde2dd0334e15de7d9d80429a7ce29274b158792a43697152347`、`d974b2b8ffb7d9b901b85ac69a66af035c01ddb4e002ee0e83658d9201bcf2dc`、`8ab310364dd2d68a90a816886b6c2883c5233d47f89c6e3708bbb83e2ff7fc4e`，残留 0。
- 视觉：`.local/ui-fidelity/StaminaClaim/compare/g5-20260804/report.json`，覆盖 mixed、补领确认/成功、全领取、断线/重连、元宝不足、体力上限；MAE `6.58-11.39`。
- 幂等：两次真实 `ProjectX.Editor.BootstrapSceneBuilder.BuildBatch` 均为 `FA73F3DB609F18F054EE5CDB3699A3BDEED12A607F97EF4638317DC29E01DDA3`。
- 操作台账与自动复盘：`.local/unity-validation/staminaclaim-operation-ledger.json`、`.local/unity-validation/staminaclaim-retrospective-latest.json`。
