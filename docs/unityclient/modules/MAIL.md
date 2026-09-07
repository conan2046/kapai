# 邮件模块

## 当前门禁

- 2026-09-07用户完成已打开Unity Editor内的Mail整模块测试并明确要求直接标记G6。当前门禁为`G0-G6 passed / 13/13 complete / manualPassed=true`；最终证据：`.local/unity-validation/mail-final-user-acceptance-latest.json`，复盘：`.local/unity-validation/mail-retrospective-latest.json`。
- 一键删除语义与Cocos一致：只删除已处理的本地历史，未读/未领取的服务端邮件继续保留；左侧列表立即刷新，提示文案为`删除成功`/`没有可删除的邮件`。证据：`.local/unity-validation/mail-delete-all-user-acceptance-latest.json`。
- 用户明确规定后续Unity验收只能操作已打开Unity的GameView；BatchMode/Runner仅保留编译、夹具、oracle和诊断用途，不再作为G4/G6验收通过证据。

- 2026-09-07当前输入复核：原生Cocos真实主界面邮件入口已稳定产生`/128`并打开页面，2026-09-05的“无`/128`且退出”未复现。固定双端四状态已按同一选择重采/重跑；Unity清除验证截图中的登录广播、附件视口由5格修为6格，并按Cocos `ItemCatalog`的`id优先/type兜底`读取附件说明和来源。四状态现仅保留已批准的Cocos列表不滚与详情数量0两项差异；视觉证据为`.local/unity-validation/mail-g5-current-visual-ready-20260907.md`及`.local/ui-fidelity/Mail/compare/g5-20260907/`。用户最终验收后正式门禁已升级为`G0-G6 passed`。

- 2026-09-05双端状态修复：`mail-visual-fixture.json`统一货币、当天本地中午的邮件时间及长正文；MySQL夹具新增三项货币快照/恢复，SQLite拒绝覆盖未清理备份。独立数据库导出确认两端角色名T00057、三项货币及15封邮件字段一致。MailPresenter修复Select不刷新ChooseBg导致高亮滞后，标准Runner增加详情选中一致性断言；Full继续13/13控件、5/5语义通过，独立夹具恢复测试通过。
- 新夹具下Cocos已登录固定身份，但入口点击未产生`/128`，客户端随后退出；断开时另有MySQL `login_log_9`格式错误，尚不能认定是退出根因。旧Cocos四图因输入变化已失效，G5仍待诊断后重采。两端夹具均恢复、残留0，相关游戏/MySQL已关闭。证据：`.local/unity-validation/mail-visual-parity-result.md`。

- 2026-09-05 G5准备：补齐13项Cocos输入，原生Computer Use从真实入口补采四态（列表拖动、九附件末端、3201详情），身份`7200057/1000115`与四图SHA已冻结；合同及RequireInputs预检均通过。MySQL夹具恢复哈希`3ebc3430810a061e0d5227c63835ba96cdac915977df13fa4b721c1256c2ccad`、残留0，游戏和本轮MySQL已关闭。
- G5仍未通过：两端账号映射、顶部货币、生成/到期时间、详情背后选中邮件尚不一致；两套夹具长正文也不同。当前四组对比仅诊断。下一步统一可逆双端状态合同并重采受影响状态，不能改旧证据指纹。详见`.local/unity-validation/mail-g5-current-review.md`及`.local/ui-fidelity/Mail/compare/diagnostic-20260905/`。

- 2026-09-05标准SQLite Full通过13/13控件、5/5语义，编译、重登业务断言、整库恢复及残留0均通过。证据位于`.local/unity-validation/`：`mail-fixed-account-latest.json`、`mail-fixed-account-timings-latest.json`、`mail-sqlite-fixture-snapshot.json`。
- 2026-09-05 VisualReplay初次因缺少`sourceAudit`被拒绝；随后补齐四项源码审计，10/10附件PNG签名检查及VisualReplay重试通过，原阻塞已在操作账本Resolved。该结构复检本身不等于验收；2026-09-07已另由当前双端证据与用户最终确认完成G4-G6。

- 2026-09-05用户明确要求“跳过需要人工验收的步骤，进行其他步骤”：本轮暂缓早期及最终人工Play，继续标准Runner自动验证。此授权不代表人工通过，不设置`manualPassed=true`；正式完成态仍须满足实际证据要求。

- 当前正式门禁：G0-G6 passed，13/13控件完成，5/5语义通过，用户最终验收通过。下述2026-07-27旧证据仅作历史输入；本轮收口以2026-09-07当前输入证据和用户确认为准。
- G1 批准差异：当前 Cocos 左侧邮件 `cc.TableView` 不滚动；Unity 已修复并在 G5 单列。
- G5 修复差异：Cocos 附件详情把 `10点贵族经验` 错显为 `数量:0`；Unity 按权威附件显示 `数量:10`。
- Unity固定账号：persistentDataPath SQLite `userId=7200057 / roleId=1000003`；Windows 100%；原生客户区 `1334×750`。Cocos历史G1仍使用当时冻结身份，不与Unity运行库混用。

## 当前 G3 重验（2026-09-03）

- 新增`Invoke-MailSqliteFixture.ps1/.py`，在Unity本地`projectx.db`准备14封可见邮件和1封隐藏已领取邮件，覆盖无附件、单附件、双附件、九附件、长正文和滚动状态。
- 当前标准固定账号Runner通过13/13真实控件和5/5语义断言；`/128 op2/3/4`、重复失败、串行一键领取/已读、本地删除、空态和账号隔离链均由当前源码执行。
- 运行前快照SHA-256为`CAD6FCF3E98F64A491328650CA911DFA685F6301E49CEDA3E8C7365AA23A3511`；重登后邮件业务状态一致，最终整库精确恢复，夹具备份残留0。
- 本机证据：`.local/unity-validation/mail-g3-runtime-latest.json`、`.local/unity-validation/mail-fixed-account-runner-latest.json`、`.local/unity-validation/mail-sqlite-fixture-snapshot.json`、`.local/unity-validation/mail-fixed-account-timings-latest.json`。
- 当前不升级G4：先由用户从真实入口早测列表/正文/附件滚动、附件详情、单封/一键领取和删除反馈。

## 源码闭包审计（2026-09-05）

- 入口：`MainUI.lua:2038`的邮件按钮进入`Social.SocialLayer(openTab=1)`，该层只声明邮件页签；`MailUI.lua`明确加载`csd/MailLayer.csb`。Unity `ProjectXApp.BindMailClick/EnsureMailPresenter/ConfigureMailFrame`通过真实按钮、`MailLayer`与`OneLevelLayer`装配；关闭调用返回栈，附件详情复用`BagFlowPresenter.ShowMailAttachment`。写信、回复等旧入口不属于当前可达范围。
- 协议所有权：`Resources/Lua/Bootstrap.txt`把邮件按钮与操作交给`Mail.MailController`，包分发调用其`onPacket`；仅`Protocol.MAIL`被消费，op2列表、op3领取、op4已读、op5通知重查。Controller拥有pending、串行领取和重查；`MailPresenter`仅调用传入回调及渲染Store。服务端`CPackageDeal::XinShi`按`id + to_id`约束领取与已读，重复/非法请求走失败回包；本地历史删除不新增服务端删除协议。
- 配置资源：`MailController.describeReward`按奖励id优先、type兜底查询`Data.ItemCatalog`，传递name/pic/quality及权威amount。`ResourceService.LoadItemIcon`按`ItemIcons/equip{pic}`、`MonsterBust/{pic}`查找，缺图会记录而非伪装通过。当前SQLite夹具的10种奖励映射为`3201→3500、500→5018、613→524、851→710、853→717、854→711、855→25105、861→3014、862→3015、863→3016`，对应ItemIcons PNG全部存在。动态邮件不枚举所有游戏物品作为本模块分母；后续新增奖励配置仍须重新核对资源。MailLayer、OneLevelLayer、common/huoqutujing均使用现有Prefab；附件模板来自MailLayer，未引入Timeline或Imod替代品。
- 运行时布局：`MailPresenter`列表使用原MailBtn模板及`VirtualList`；正文顶左锚点、自动首选高度、RectMask2D和纵向ScrollRect；附件视口宽624（6格），单格88、间距104、左侧锚定、横向Clamped滚动且内容宽不小于视口。空态拉伸居中，删除时间宽420；`ConfigureMailFrame`顶左锚点、单位缩放，邮件及公共层置顶，单页签禁用切换。附件详情按权威数量展示，说明/来源读取当前Cocos道具目录并隐藏获取跳转按钮。布局审计确认运行时改动位置与归属，不替代正式G5门禁顺序。
- 当前标准Full保留13/13控件、5/5语义和5张截图；2026-09-07最终用户验收记录将`manualPassed`设为true，并与当前门禁、复盘及双端证据共同完成G6收口。

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
