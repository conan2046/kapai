# 邮件模块

## 当前门禁

- 当前正式门禁：G0-G2 passed，G3-G6 pending。下述旧G3-G6实现与证据仅作重验输入，不能代替当前门禁。
- G1 批准差异：当前 Cocos 左侧邮件 `cc.TableView` 不滚动；Unity 已修复并在 G5 单列。
- G5 修复差异：Cocos 附件详情把 `10点贵族经验` 错显为 `数量:0`；Unity 按权威附件显示 `数量:10`。
- 固定账号：`userId=7200057 / roleId=1000115`；Windows 100%；原生客户区 `1334×750`。

## 当前真实链

`UImainLayer_new/ButtonGroup7/btn_mail → MainUI.OnMailButtonClick → Utils:OpenFunction(EMID_SHEJIAO) → Social.SocialLayer(openTab=1) → DelayLoadSubUI('View.Mail.MailUI') → csd/MailLayer.csb → LuaNetSendMsg /128`

- `MailLayer.csb` 无 Timeline/Imod 动态资源；动态节点为左侧 `cc.TableView`、正文 `ScrollView_1` 和附件 `ListView`。
- 一级标题、唯一邮件页签和关闭按钮由 `SocialLayer + LUIFClassBgEvent` 公共框架提供。
- 红点由 `LRedDotCheckMgr.MailRedCheck -> #LRoleDataMgr.Social.NewMailData > 0` 驱动。

## G0 范围结论

- 当前真实存在：列表滚动、行选择、已读/未读、正文滚动、附件滚动/详情、单封领取、一键领取、单封删除、一键删除、空态。
- 当前单封“领取/删除”共用 `Panel/MailBtn/ReceiveBtn`，按本地已读状态切换文字和行为。
- 当前一键领取由 Lua 逐封调用 `/128 op=3,mail_id,clientUse=0`，不是服务端批量 op。
- 当前单封删除和一键删除只清 Cocos 本地 `OldMailData`；没有删除确认/取消弹窗。
- 写邮件、回复、好友选择和旧独立删除按钮绑定已注释，当前入口不可达，Unity 不得新增。

## 协议初审

- `/128 op=2`：请求列表；本地直连服务端返回 `count + id/fromId/fromName/expireAt/body/CommonReward[]`，最多 30 封。
- `/128 op=3`：领取；请求 `mail_id + clientUse`，成功后服务端将 `xin_shi.deleted=1`。
- `/128 op=4`：Cocos 对无附件未读邮件发送已读/删除请求；当前本地直连 `CPackageDeal::XinShi` 尚无 type=4 分支，G1 必须以运行证据确认并补齐本地测试兼容。
- `/128 op=5`：新邮件通知后重拉列表。
- 旧 Unity 仅覆盖列表和单封领取，且 Runner 直接调用 Lua claim、隐藏一键按钮、C# 预先标已读，均不满足当前矩阵。

## G2 协议冻结（2026-07-27）

- 请求：`op2 = byte 2 + byte reserved`；`op3/op4 = byte op + uint32 mailId + byte clientUse`。
- `op2` 响应：`byte op + byte count`；每封为 `uint32 id/fromId + string sender + uint32 expireAt + string body + byte rewardCount`；每奖励为 `uint16 type + uint32 typeId + uint32 amount`。
- `op3/op4` 响应统一为 `byte op + uint32 mailId + byte clientUse + byte success + string message`。
- 修复服务端两个确定性缺口：op3 不存在/重复 ID 不再静默；新增 op4 已读无附件处理。两者均用 `id + to_id` 限定当前角色并返回明确成功/失败。
- 权威边界：Lua Controller 独占请求、pending、批量串行及回包；C# 只渲染 Lua 提交状态。op3 成功后必须 op2 重拉；op4 成功后写当前账号本地已读历史；单删/一键删只删本地历史；op5 只触发去重重拉。
- Windows 服务端增量编译通过。完整证据：`.local/unity-validation/mail-g2-protocol-evidence.md`。

## G1 入口

- 为固定账号建立可逆 `xin_shi` 快照夹具，覆盖有/无附件、已读/未读、已领取、可删除、滚动、空态和非法/重复操作。
- Setup/AssertSetup/Restore/AssertRestored/Cleanup/AssertCleanup 必须齐全，并在重登录后验证最终快照哈希完全一致、夹具残留为 0。

## G1 运行结论（2026-07-27）

- 已建立 `tools/unity-migration/Invoke-MailCocosFixture.ps1`：14 封可见邮件 + 1 封删除态邮件，最大 9 个附件。
- 主界面真实入口、列表 populated、行选择、未读态、无/有附件、附件滚动和附件详情均取得原生 `1334×750` 证据。
- 原生缺陷为 `MAIL-05-LIST-SCROLL`：列表拖拽前后原图 SHA-256 完全一致；右侧附件列表在同一运行环境可滚动。
- 当前 Cocos 附件详情另有 `typeId=0` 被显示为“数量:0”的现存缺陷。
- 可逆根因诊断依次验证“禁用祖先 MailList 触摸”“同时启用 TableView 独占触摸”“按 FriendList 标准改为占位容器内 `(0,0)` 挂载”“注册已定义但被注释的滚动回调”，四组均由真实入口和 Computer Use 拖拽复现失败，且已全部恢复。由此排除 Lua 层常见的祖先拦截、swallow 配置、跨层挂载和滚动回调注册单点问题；阻断下沉到旧 Cocos TableView/触摸监听运行时，当前仓库缺完整引擎源码。
- 证据：`.local/ui-fidelity/Mail/cocos/g1-20260727/G1_COCOS_EVIDENCE.md`。
- 恢复：数据库基线哈希 `3e3588a207e5c6d309391bb0a0bbb5cde40b60ffd17b6d3d4eace0d0aa9b1098`；`UserDefault.xml` 哈希 `D8DC11EC96C6BDA7E4C254D5A382F70DED42E7DB6208D23EFF7226524EEFD450`；双次恢复断言、最终清理断言通过，残留 0。
- 用户于 2026-07-27 明确批准方案 2：记录 Cocos 缺陷，Unity 实现正确滚动并继续 G2-G6。G5 必须单列此批准差异，其余状态仍需逐项双端对比。

## G3-G6 运行结论（2026-07-27）

- G3：Lua 独占 `/128` 请求和回包；`MailStore` 按角色持久化已读/领取历史并完成账号隔离、合并、删除验证。证据：`.local/unity-validation/mail-g3-logic-evidence.md`。
- G4：隔离账号 `7200096/1000151` 完成 13/13 真实控件、5/5 语义断言和 5 张互异的原生 `1334×750` 截图；覆盖 op2/3/4、重复失败、串行一键领取、批量已读、本地删除、空态、重进、断线清理和切号隔离。证据：`.local/unity-validation/mail-latest.json`。
- G5：固定账号 `7200057/1000115` 在同一批 14 封邮件上完成 4 组 Cocos/Unity 原图、并排、叠加和差异；人工验收 4/4 通过。数据库两轮精确恢复、重登录复核、夹具残留 0。证据：`.local/ui-fidelity/Mail/compare/g5-live-20260727/`。
- G6：控件矩阵 13/13；正式 `BootstrapSceneBuilder.BuildBatch` 连续两次 SHA-256 均为 `B27460DB36051DA396630CFF66EDED1115F3C3CB8148388F9574AA60A92D19AE`。
- 公共复用：一级框架使用真实 `OneLevelLayer`，附件详情使用真实 `common/huoqutujing`；已移除 Mail 运行时临时标题/关闭按钮。

## Steam SQLite S5（2026-08-20）

- 已通过：同一隔离角色执行空列表、创建14封夹具邮件、领取9附件邮件、重复领取失败、重拉、读取/删除无附件邮件、重复删除失败、最终12封可见邮件；SQLite/MySQL运行态各69响应，重启各21响应，拥有协议`/128 op2/3/4`字节与语义一致。
- 持久化：`xin_shi` 14行（含两行`deleted=1`）全字段规范化哈希一致；`role_info.package/mission/save_data/user_spirit/money`原始值一致。仅将`local_test`夹具冻结到同日UTC基准并使用真实换行，正式邮件分支未改。
- 清理：只删除隔离库`fxl_game_mail_s5_v1`；正式`fxl_game_local`、MySQL源码/驱动/构建/Schema/脚本/回归全部保留，直到所有模块验收完成且用户明确通知删除。证据：`.local/unity-validation/steam-sqlite-s5-mail-latest.json`。
- 视觉修复：系统/活动使者标题、完整日期和删除时间、空态文字、附件视口/间距、列表/正文/附件裁剪和滚动均以真实运行图复核。
