# UnityClient 当前状态
> 最后更新：2026-09-03
> 本文件是迁移进度、当前批次和下一步的唯一状态源。
> 历史全文见 `docs/unityclient/history/`；唯一流程与标准见 `docs/unityclient/MIGRATION_GUIDE.md`。
> Steam模块黑名单见 `docs/unityclient/STEAM_SCOPE.md`；命中 `steam-excluded` 的模块禁止继续迁移。
## 1. 总进度
> 当前 Steam 业务模块分母固定为 16；2026-08-31用户确认竞技场保持屏蔽并移出当前分母。历史 29 模块及旧17模块口径只用于追溯，不再输出当前完成率。
| 口径 | 当前值 | 说明 |
|---|---:|---|
| Static | `386 CSB 已审计` | 325 个同路径 CSD，61 个 CSB 兜底 IR；历史 356 Prefab 含跨目录同名混入，不再记作 100% |
| Functional | `待逐控件重审` | 旧“约56%”只统计页面/协议主链，未统计 Cocos 可达控件和真实点击覆盖，现已作废 |
| Validated | `5/16 = 31.3%` | 仅统计当前 Manifest 完成态、G0-G6 全通过且证据可在本检出复核的主模块：Login、Settings、Bag、Task、World。BattleFengShenStory 作为非分母战斗子模块已独立完成 G6，不增加此处分子；PlayerHud 因共享输入变化保留到 G3，Arena 已排除。 |
禁止在其他文档维护第二份完成率。历史“第一阶段完成”统一解释为 `legacy-unverified`，不代表功能完成；新标准见 `docs/unityclient/MIGRATION_GUIDE.md`。
## 2. 模块状态
| 模块 | 状态 | 已完成边界 | 后续 |
|---|---|---|---|
| 运行时/网络/xLua | 第一阶段完成 | App 状态、协议分发、错误边界、重连、返回栈 | 回放、发布配置、完整错误码 |
| 登录与创角 | `G0-G6 passed / 21/21 complete` | 固定账号完成 17/17 双端原生视觉、21/21 真实控件、10/10 语义断言；覆盖 LoginBg/loginLayer/SeverListLayer/RoleCreateLayer/NoticeLayer、`/1001→/1003→/1004`、`/1002`、`/88`、已有/无角色、命名合法/非法/重复、失败/超时/断线/重连、返回/重进/切号隔离及精确恢复 | 正式登录服、渠道 SDK、发布配置后置；HUD 已独立完成 |
| UI 通用层 | 第一阶段完成 | VirtualList、MessageBox、Loading、Toast、Reward | 通用 Tab、分页、红点树深化 |
| 迁移提速工具 | 第三阶段完成 | 新增零副作用 Preflight、源码锚点、固定账号快照回滚、矩阵 ID 运行覆盖、中文语义断言、G5 输入哈希/提交来源；兼容 Task 回归样板 | 后续模块统一登记证据契约，再按 G0-G6 推进 |
| ResourceFoundation/资源/时间/旧动画 | `R0-R4 passed / early user Play passed` | 提交`97952ddd`；回退基线`7422cbd8`；Bootstrap为0业务PrefabInstance；110/110目录项、96个静态Source查询、登录5个Source入口通过；登录→主界面、设置重复开关、任务父子组合、HeroBook/HeroRecycle仅完成创建释放生命周期试点及无阻断残留确认，不代表两项业务功能已迁移 | 本轮收口；新Bootstrap已改变输入哈希，后续模块必须按当前输入重验。YooAsset后端、Atlas和内存预算后置 |
| 设置 | `G0-G6 passed / 21/21 complete` | 固定账号完成 8/8 双端原生视觉、21/21 真实控件、10/10 语义；覆盖默认/开关/音量边界与中值、返回重进/重启持久化、损坏回退、真实音频应用、切号身份隔离和设备偏好保留 | `no-server-fixture` 残留 0；公告、兑换码、商城/体力购买及支付等仍属独立模块 |
| 主界面 HUD | `G0-G3 retained / early user Play passed / G4-G6 pending` | 2026-09-04真人Play确认非绑定元宝`505/60003`与绑定元宝`506/60001`分流、跨页公共栏刷新及背包懒加载复测通过。ResourceFoundation现以`ParentKey`只保留运行时层级，不再随`OneLevelLayer`递归加载全部子页，英雄列表/详情改为显式请求后加载且默认关闭；Unity固定身份为版本化SQLite `7200057/1000003` | 当前修复已通过315项工具链、ResourceFoundation批验证和Bootstrap双次幂等；可进入标准G4，旧G4-G6仍不得复用 |
| 背包 | `G0-G6 passed / 26/26 complete` | 固定身份`1/1000001`完成26/26控件、18/18语义、真实`/8`与`/15`、ItemType 5/6奖励弹窗、异常/重连/重登/切号及精确恢复；G5同账号同数据16/16。G6真人Play发现并关闭礼包横向拖动缺口，用户最终复测“测试通过”；整库恢复、Fixture残留0，两次BuildBatch SHA一致 | 当前模块收口；下一模块按P1顺序从当前G0启动 |
| 任务 | `G0-G6 passed / 14/14 complete` | 固定账号完成 11/11 双端关键视觉状态；14/14 真控件覆盖每日任务、前往/领取/已领取、滚动、四档宝箱、奖励弹窗、货币加号/禁用态、失败/重连/持久化/切号及精确恢复 | 当前模块收口；下一任务重新选择模块执行 G0 |
| 神将/阵容 | `G0 passed / G1-G6 invalidated / G1 recapture blocked` | G5重复内容硬门禁发现当前G1 Cocos状态中`HERO-02/03/04/06/07/08/09-15`像素完全相同，不能证明逐状态交互；原G4批验降为诊断线索。新增最高优先backlog：神将重生、神将图鉴功能缺失，HeroEquip G6后分别从G0启动；用户微调Prefab为只读基线：`shenjiangchongsheng.prefab` SHA=`7E210120B232144840C62DAE3B323E48E82D4C0CE3D5CB682C7F761FFF5EA4B9`、`yingxiongtujianLayer.prefab` SHA=`77AB6917CE61D06D7A462148C50CE373B8950CF0C8D1FACF33070D933FD33FC7` | 先完成HeroEquip G6，再处理重生/图鉴且不得覆盖用户布局；神将/阵容旧G1仍待Computer Use恢复后重采 |
| 强化大师 | `G0-G3 passed / early user Play pending / G4-G6 pending / 40 controls frozen` | 14个当前Cocos状态、40控件/898业务ID与源码闭包已冻结；标准固定账号batch G3完成13个Unity运行态，六页签、装备/法宝养成路由、法宝材料滚动选择及按需加载通过；SQLite预检、精确恢复与211项工具回归通过 | 固定账号`1/1000001`已准备2套红装、4件已穿戴法宝和12件法宝材料；等待用户真实Play反馈，此前不进入G4 |
| 神将培养模块 B | `G0-G2 passed / G3 early user Play pending / G4-G6 pending / 51 controls frozen` | 18个当前Cocos状态冻结；`/24,/25,/48,/70`、配置/14个Prefab/Imod闭包与G3初版实现完成，用户调整后的Prefab布局已保留 | 用户按最终布局复测5-15分钟主路径并反馈；反馈闭环后才进入G4，测试数据仅允许Unity LocalServer SQLite |
| 装备（法宝边界回归） | `G0-G4 passed / G5 Unity capture passed, Cocos refresh blocked / final user Play passed, G6 blocked by G5` | 方案A冻结14来源、974业务ID、86控件；碎片Icon奇偶消失及觉醒/神铸双层叠加均已由用户复测通过。培养子页采用Presenter四选一，并由UiRouter关闭同源重复实例；固定SQLite Full通过86控件与全部语义，工具链319/319，整库恢复SHA=`56DCEFE5DBE88209E78C39F272604E79405F807D27F08BB9E765CF14601E7A3F` | 本轮缺陷关闭；当前Computer Use仅暴露浏览器，无法补拍被词条输入改动失效的Cocos详情基线，因此完整G5/G6仍阻塞。后续优先启动神将重生、神将图鉴，且不得覆盖用户布局 |
| 邮件 | `G0-G3 passed / early user Play pending / G4-G6 pending` | 2026-09-03切换到persistentDataPath SQLite固定身份`7200057/1000003`；当前源码G3批处理通过13/13真实控件、5/5语义及`/128 op2/3/4`，14封可见+1封隐藏邮件夹具完成重登业务断言、整库精确恢复和残留0 | 用户从当前真实入口早测列表/正文/附件滚动、详情、单封/一键领取与删除；反馈闭环后进入G4。旧G4-G6证据仅作诊断。 |
| 基础商城 | `G3 runtime-ready / early user Play passed；正式G1-G2因免截图保持pending，G4-G6 pending` | 2026-09-02完成当前入口、`/221`、type=1配置与资源闭包；隐藏`OneLevelLayer/Panel_12`，迁入Shop自有真实关闭按钮并修复全控件射线。用户早测确认页签、商品图标、刷新隐藏、数量输入和购买按钮修复无问题 | 早测反馈已闭环；后续仍须按正式门禁补G1-G2并进入G4，不能把本轮免截图或早测冒充G5/G6视觉通过。 |
| 将魂商店 | `G0-G4 passed / early user Play passed / G5-G6 pending / 29 controls + 9 semantics` | 2026-09-02按当前源码收窄为function_id=15/type=2；原生Cocos六格与各调用入口已冻结。Unity补齐六格底图、碎片角标语义、ActivityLayer子节点显隐、秒级倒计时及`/221`权威购买/刷新/失败回包；固定SQLite账号`7200057/1000003`完成29/29控件、9/9语义、整库精确恢复和残留0 | 用户最终实测通过；按本轮免截图约定停在G4提交，G5五状态视觉对比与G6最终收口仍pending；玩法商店其他分支继续暂缓 |
| 好友 | `steam-excluded` | Steam隐藏HUD入口、禁止路由和验收；Cocos/服务端保留 | 后续不迁移 |
| 聊天 | `steam-excluded` | Steam隐藏聊天入口及HUD聊天条、禁止路由和验收；Cocos/服务端保留 | 后续不迁移 |
| 队伍 | `steam-excluded` | Steam不生成队伍入口、禁止路由和验收；Cocos/服务端保留 | 后续不迁移 |
| 帮派 | `steam-excluded` | Steam隐藏帮派/宗门入口、禁止路由和验收；Cocos/服务端保留 | 后续不迁移 |
| 世界/战斗/副本 | `V0 closed / A=16,19 / World G0-G6 passed / 32/32 complete` | 2026-09-02用户先后确认主线成就屏内显示/关闭及普通宝箱打开/领取/返回地图通过；四个底部入口、成就权威`/320 op=11/12`、宝箱真实射线、G3完整链、G4权威交互、G5九态视觉、重登、SQLite精确恢复与残留0全部通过。 | 当前模块收口；证据`.local/unity-validation/world-final-user-play-latest.json`、`.local/unity-validation/world-fixed-account-latest.json`、`.local/ui-fidelity/World/compare/g5-current-battle/report.json`。星数排行保持隐藏。 |
| 福利 | `steam-excluded` | Steam隐藏福利入口、在线奖励和体力领取，禁止路由和验收；Cocos/服务端保留 | 后续不迁移 |
| 活动 | `steam-excluded` | 当前集合包含全服排行/最强榜等其他玩家数据，也包含充值活动；Steam隐藏入口并由Runner拒绝 | 后续不迁移；Cocos/服务端保留 |
| 抽卡 | `G0-G5 retained / G6 evidence missing` | G5双端主状态与差异报告仍存在；G6矩阵登记的28组Cocos与28组Unity逐控件图在当前检出全部缺失 | 重取或找回56份真实逐控件证据后重跑G6；禁止复制旧图补路径 |
| 玩法大厅 | `G0-G3 passed / early user Play retest pending / G4-G6 pending` | 当前 SQLite batch 保留 13/13 控件、13/13 语义、精确恢复及残留 0；MySQL `7200057/1000115` 与 SQLite `7200057/1000003` 的同逻辑身份映射已冻结 | 先完成白屏与跨页 LFS 修复后的早期真人复测，再进入 G4；Steam 只保留 `function_id=1/3/9/10`，Arena 已排除且不再阻塞 G5 |
| 法宝搜索 | `G0 passed / G1 implementation fixed, user retest pending / G2-G6 blocked` | 真人Play确认0次仍报一键搜索成功且无结果反馈；已补0次拦截、搜宝令背包边界、op28/29奖励弹窗、权威碎片数与合成前置校验 | 用户复测搜索次数不足、补次数、实际搜索结果和碎片刷新；当前证据目录缺失，仍须从G1串行重验 |
| 游历三界 | `G0 passed / G1-G6 evidence missing` | `/335 op1/2/3`实现保留；登记的Cocos/Unity空态与差异目录当前不存在 | 从当前源码重取G1，后续门禁串行重验；写操作以op1权威重查为准 |
| 竞技场 | `steam-excluded / user-confirmed disabled` | 当前以`migrationReady=false`隐藏大厅入口；2026-08-31用户确认竞技场本就屏蔽，不进入当前Unity迁移、战斗表现或16模块分母。历史Unity单端Runner、协议等价和旧截图仅作遗留线索 | 后续不迁移、不验收；若产品恢复竞技场，必须从G0重启并重新取得当前Cocos证据 |
| 封神列传 | `G0-G3 passed / early user Play retest pending / G4-G6 pending` | 2026-08-29重取当前Cocos关卡、首通奖励与获取途径原生证据；奖励复合格、公共货币栏、`/320`确认包及挑战/布阵关闭弹窗修复均已通过当前工作树BuildBatch。固定账号已切为Unity persistentDataPath SQLite `7200057/1000003`，预检完成整库精确恢复、隔离账号清理和零残留 | 用户用当前G3构建复测奖励图标/品质框/数量、公共货币栏、真实挑战与布阵返回；反馈闭环前不得进入G4，也不得切换到寻宝 |
| 封神列传战斗表现 | `G0-G6 passed / 9/9 complete / shared-battle regression passed` | Unity SQLite`7200057/1000003`固定账号完整batch通过9/9控件、自然结算/主动跳过分流、重登、精确恢复与零残留；用户确认苏全忠、姬发、郑伦朝向正确。World共享战斗修改后已于2026-09-01重跑完整batch，9/9与恢复合同继续通过。 | 当前模块收口；复盘241/241已解决、补充证据4、待诊断0、未解决0。证据`.local/unity-validation/battlefengshenstory-fixed-account-latest.json`、`.local/ui-fidelity/BattleFengShenStory/compare/g5/report.json`、`.local/unity-validation/battlefengshenstory-retrospective-latest.json`。 |
| 体力领取 | `steam-excluded` | 历史G0-G6证据保留；Steam按“福利整体排除”隐藏入口、移除路由并拒绝验收 | 后续不迁移；Cocos/服务端保留 |
| 血战到底 | `steam-excluded` | 包含全服血战排行榜与其他玩家排名数据；玩法大厅不显示，Runner拒绝 | 后续不迁移；Cocos/服务端保留 |
| 决战昆仑 | `steam-excluded` | 依赖匹配对手数据；玩法大厅不显示，不再请求昆仑红点 `/213 op=25`，Runner拒绝 | 后续不迁移；Cocos/服务端保留 |
| 七日目标 | `steam-excluded` | Steam大厅与HUD的7日活动入口均隐藏，Unity路由不接线，标准Runner拒绝继续验收；Cocos与服务端线上逻辑保留 | 后续不迁移、不验收、不计入当前16个Steam业务模块分母 |
| 支付前置/充值/VIP/渠道 | `steam-excluded-hud` | 用户确认Steam HUD不需要首充、充值及三类折扣礼包；6个入口固定隐藏，`/222 op89-91`不得重新开启；Cocos、服务端和配置保留 | 当前不迁移对应商业化入口；若未来恢复支付，须由用户重新确认Steam产品范围并重走支付前置门禁 |
| Steam SQLite/发布/热更/性能 | `S0-S7 passed / S8 local accepted / external deferred` | S5的17模块/25协议闭环；S6-S8已通过单入口启动、崩溃遗留回收、loopback、SQLite存档、中文只读安装、备份/日志/优雅退出及无MySQL依赖本机验收；用户确认当前以Unity可独立双击运行作为收口口径 | 物理干净Windows与真实Steam Depot安装/升级暂不要求；MySQL源码、驱动、构建、Schema、脚本、回归及正式`fxl_game_local`继续保留，未经用户通知不得删除 |
## 3. 最新验证基线
- Steam SQLite S6-S8 本机发布闭环（2026-08-20）：Windows Player在网络前监管`kapai.exe + SQLite`；默认角色NULL导致的真实`/1004`超时已修复，当前中文只读x64包以`ProjectX.exe`单入口启动，`/1004=78ms`并进入Main。发布树589文件，除Manifest自身外588文件全部纳入哈希，未登记/不一致/DoNotShip/PDB/MySQL/PowerShell均为0；6个已排除商业入口为零可见且不发送`/222`。缺资源、端口冲突、运行崩溃、第二实例、客户端硬崩溃遗留回收、SQLite存读档、3份备份`integrity=ok/schema=1`、优雅退出`save data end`及残留0均通过，精简PATH实测无需开发环境/MySQL。交互式Unity Editor点击Play会先自动构建缺失/过期的仓库Debug服务端，再启动`kapai.exe + SQLite`；构建失败取消Play，停止Play由`ProjectXApp.OnDestroy`保存并回收，批处理及`-projectXExternalServer`仍由外部工具管理。证据`.local/unity-validation/steam-sqlite-s6-latest.json`至`steam-sqlite-s8-latest.json`；用户确认当前以Unity独立双击运行作为完成口径，物理干净Windows与真实Steam Depot安装/跨版本升级暂缓，不纳入本轮阻塞。
- Steam SQLite S5 协议/状态等价（2026-08-20）：17模块共25条有效协议，22条主动请求/专用推送触发，`/18、/62、/70`双后端推送已出现；Task旧`/39`确认为停用链并排除。83-case通用套件双端各120响应、单边协议0，公告`/88`与11项持久字段一致；17项模块状态全部为通过或无服务端数据不适用。最后的XunBao双端运行态各2 case/46响应、重启态各1 case/20响应，真实`/319 op31`保持初始20次、30分钟恢复窗口且查询不改业务状态；`mission/save_data/xunbao`字节一致，`pet_equip`仅运行时时钟字段归一化。S5已收口，证据`.local/unity-validation/steam-sqlite-s5-latest.json`及十五个模块latest，下一门禁S6。
- SevenDay Steam范围决策（2026-08-20）：用户确认Steam版本不投放。Unity `gameplay.json` 以 `steamEnabled=false` 隐藏入口，`EnterGameplay(11)` 路由和自动验收入口已移除，中央Runner对 `migrationExcluded=true` 直接拒绝；历史诊断证据仅留档，不再恢复G1或计入分母。
- StaminaClaim G0-G6（2026-08-04）：固定主账号 `7200057/1000115`、不足元宝账号 `705213/1000006`、体力上限账号 `7200260/1000119`；16/16控件、13/13语义和8组双端原生 `1334×750` 视觉通过。真实 `/321 op=2/3` 覆盖三档单次领取、补领确认/取消、重复领取、元宝不足、体力上限、奖励/体力变化、重进、断线重连、持久化及切号隔离。三账号恢复 SHA256 为 `195d412daf2bfde2dd0334e15de7d9d80429a7ce29274b158792a43697152347`、`d974b2b8ffb7d9b901b85ac69a66af035c01ddb4e002ee0e83658d9201bcf2dc`、`8ab310364dd2d68a90a816886b6c2883c5233d47f89c6e3708bbb83e2ff7fc4e`，Fixture残留0；两次真实 BuildBatch SHA256 均为 `FA73F3DB609F18F054EE5CDB3699A3BDEED12A607F97EF4638317DC29E01DDA3`。证据 `.local/unity-validation/staminaclaim-fixed-account-latest.json`、`.local/ui-fidelity/StaminaClaim/compare/g5-20260804/report.json`、`.local/unity-validation/staminaclaim-retrospective-latest.json`。
- FengShenStory G0-G6（2026-08-04）：固定主账号 `7200057/1000115`、隔离账号 `705213/1000006`；25/25控件、10/10语义、12组双端原生 `1334×750` 视觉通过。真实 `/320 op24/op25/op10/op26`、第2-7章初始视窗与6章箭头翻页、四关三态、MonsterBust/Imod、宝箱/帮助/获取途径/章末奖励、返回重进、断线重连和切号隔离均闭环。主/隔离恢复 SHA256 为 `bd12c4e8d2c5bcf7d9bc2213dcadd5181500912778f049681d3b03569d96e7bf`、`9e8abe9c9623389f4b0a5cd0ce446af33e2a3ee2867e8dfd6bfe87c3d282672c`，Fixture残留0；两次真实 BuildBatch SHA256 均为 `FA73F3DB609F18F054EE5CDB3699A3BDEED12A607F97EF4638317DC29E01DDA3`；自动复盘102/102已解决、未解决0。证据 `.local/unity-validation/fengshenstory-fixed-account-latest.json`、`.local/ui-fidelity/FengShenStory/compare/g5-20260804/report.json`、`.local/unity-validation/fengshenstory-retrospective-latest.json`。
- Gameplay 历史 G0-G6（2026-08-02，当前失效）：旧固定账号、9组双端视觉、Runner与BuildBatch结果仅作诊断线索。本工作树缺少全部登记的G1/G5文件，且旧合同没有现行`cocosBaselineInputs`指纹，不能证明当前输入未漂移；2026-08-27审计仅保留G0，G1-G6待按当前检出重取。
- PlayerHud G0-G6（2026-08-02）：固定账号 `7200057/1000115`、隔离账号 `705213/1000006`；56/56 控件与 Runtime ID 完全一致，14/14 语义断言通过。11 组同账号同数据同步骤的 Cocos/Unity 原生 `1334×750` 截图、并排、50% 叠加、增强差异和报告完成，最大 MAE `17.9779`。HUD 仅消费 `/1004、/18、/26、/62、/65、/199、/206、/220、/222、/226、/321` 的只读显示分支；22 个路由按钮均真实调用，只有已完成设置页实际打开，其余仅给所有权/不可用反馈，未迁移支付、活动、基金、福利、竞技或社交页面。DataPreflight/setup/live assert/restore/cleanup 全通过，恢复精确且 Fixture 残留 0；严重错误 0。SceneBuilder YAML 规范化后，两次真实 `BootstrapSceneBuilder.BuildBatch` SHA-256 均为 `CE9FAD096983A00615EE522019AAC97AE72C8C008F89F097EFCBBAAC0CF256F3`；中央工具回归 `82/82`，自动复盘 `125/125` 已解决、未解决 0。证据 `.local/unity-validation/playerhud-fixed-account-latest.json`、`.local/ui-fidelity/PlayerHud/compare/g5-live-20260801/report.json`、`.local/unity-validation/playerhud-retrospective-latest.json`。
- Settings G0-G6（2026-08-01）：固定账号 `7200057/1000115`、隔离账号 `705213/1000006`；21/21 控件、10/10 语义断言、8/8 同账号同数据同步骤 `1334×750` 双端原生视觉通过。设置本体为设备级本地持久化，登记 `no-server-fixture`，服务端 Fixture 残留 0；切号后角色态隔离且 35%/65% 音频偏好保留。Unity 与服务端日志严重错误 0；两次正式 BuildBatch SHA-256 均为 `6A476349E892BF29E845CCA9F37D2292FB0853ADA1868415CAAF982FCD20660C`；自动复盘 72/72 已解决、未解决 0。Computer Use 持久化运行时遗漏已补记并关闭，G6 中央硬门禁新增残留检查。证据 `.local/unity-validation/settings-g6-latest.json`、`.local/ui-fidelity/Settings/compare/g5-live-20260801/report.json`、`.local/unity-validation/settings-retrospective-latest.json`。
- Login G0-G6（2026-08-01）：固定账号 `7200057/1000115`、可逆创角账号 `7300204/T00204`、隔离账号 `705213/1000006`；21/21 控件、10/10 语义断言、17/17 同账号同数据同流程 `1334×750` 双端原生视觉通过。覆盖 `/1001→/1003→/1004`、`/1002`、`/88`、已有角色/无角色、选服、合法/非法/重复名、连接失败/真实超时/断线重连、返回重进及账号隔离。创角夹具已精确恢复且残留 0；两次正式 BuildBatch SHA-256 均为 `6A476349E892BF29E845CCA9F37D2292FB0853ADA1868415CAAF982FCD20660C`；自动复盘 62/62 失败均已诊断并解决。证据 `.local/unity-validation/login-fixed-account-latest.json`、`.local/ui-fidelity/Login/compare/g5-live-20260801/report.json`、`.local/unity-validation/login-retrospective-latest.json`。
- World G0-G6（2026-08-01）：固定账号 `7200057/1000115`、终态隔离账号 `705213/1000006`，25/25 控件和 5/5 语义断言通过；6 组当前 `1334×750` 双端视觉完成。扫荡页按用户确认展示“扫荡5次收益汇总”，相同 `type/id` 奖励合并总量；按钮同步显示真实次数。源码缺失的 `4601–4604` 元数据只在 World 展示层依据素心装备表与连续碎片编号受控补全，不改共享掉落配置。恢复前后 SHA-256 均为 `1fe6274907b6aef8f631994fa0a7c4d9b17e19fe30e7a5b54ae2a6aca0eca11d`，Fixture 残留 0；两次正式 BuildBatch SHA-256 均为 `6A476349E892BF29E845CCA9F37D2292FB0853ADA1868415CAAF982FCD20660C`。证据 `.local/unity-validation/world-fixed-account-latest.json`、`.local/ui-fidelity/World/compare/g5-20260731-cua/`。
- Draw G0-G6（2026-07-31）：固定账号 `7200057/1000115` 以可逆 Fixture 保证高级首次招募权威返回神将 `64 郑伦`，真实完成 `/224 → /24 op=3 → /48 op=4` 的招募、培养、上阵、重进、断线重连和切换账号 `705213/1000006` 隔离；28/28 控件、6/6 语义断言通过。9 组同账号 `1334×750` 双端视觉完成；Cocos 上阵完成帧保留培养前陈旧数值，Unity显示服务端权威刷新值，已作为受控原生缺陷记录。恢复前后及重登录 SHA-256 均为 `d10f760ded12ce9b8518770097bad55e1d85b72906a0e3344a9de47fe23483ee`，Fixture 残留 0；冻结工具链加最小可选字段/终态身份修复后回归 `43/43`，两次正式 BuildBatch SHA-256 均为 `CBE2F1020F627C6904F6E754C08CB17D7848CF8FE5F56E70E523FF804C7F700B`。证据 `.local/unity-validation/draw-fixed-account-latest.json`、`.local/ui-fidelity/Draw/compare/g5-20260730/`。
- GameplayShops G5重验（2026-07-29）：六页恢复 `shop/shop_bg`、菱形导航、原生页签、真实品质框/物品图/数量/碎片角标/合成计数，并清除聊天公共层残留；同账号同数据 `1334×750` 逐页人工验收通过，MAE `6.7721～10.4781`，结构错位、错资源及文字裁切/重叠为 `0`。证据 `.local/ui-fidelity/GameplayShops/compare/g5-live-20260729/`。
- Shop G0-G6（2026-07-28）：范围固定为基础商城 `type=1`；固定账号 `7200057/1000115` 完成商品列表、数量键盘、滚动、购买确认、奖励、重拉/重登 `6/6` 双端原生 `1334×750` 视觉，控件矩阵 `21/21 complete`。最终隔离账号 `7200123/1000174` 完成 `/221 op1/2/3/4`、21/21 真实控件、5/5 语义断言、余额不足、空态、断线重连和切号清理。修复奖励弹窗层级、商品行高、页签截断及英雄阵容残留；批准购买确认、公共奖励弹窗和 type=1 不可刷新提示三项目标差异。固定账号恢复及重登录哈希均为 `adabb7fcb1c9784356a98e1246074dad868ebe5c55dbb656230991beea302be0`，夹具残留 0；正式 BuildBatch 两次 SHA-256 均为 `B27460DB36051DA396630CFF66EDED1115F3C3CB8148388F9574AA60A92D19AE`。证据 `.local/ui-fidelity/Shop/compare/g5-live-20260728/`、`.local/unity-validation/shop-latest.json`。
- Mail G0-G6（2026-07-27）：固定账号 `7200057/1000115` 同一批 14 封邮件完成 4/4 双端视觉；隔离账号 `7200096/1000151` 完成 13/13 真实控件、5/5 语义断言和 5 张互异原生图。`/128 op2/3/4/5`、重复/非法失败、串行一键领取、无附件已读、账号历史隔离、重进/断线/切号、空态均通过。Cocos 左列表不滚和附件详情数量 0 作为已记录缺陷，Unity 分别修为真实滚动和权威数量。固定账号重登录后精确恢复，夹具残留 0；正式 BuildBatch 两次 SHA-256 均为 `B27460DB36051DA396630CFF66EDED1115F3C3CB8148388F9574AA60A92D19AE`。证据 `.local/unity-validation/mail-latest.json`、`.local/ui-fidelity/Mail/compare/g5-live-20260727/`。
- Task G0-G6 收口（2026-07-27）：固定账号 `7200057/1000115` 从真实 `btn_renwu` 进入，Cocos/Unity 原生 `1334×750` 的 populated、滚动、前往、领取/已领取、四档宝箱、奖励弹窗确认/关闭/物品、重载和重连等 `11/11` 关键状态通过并排/叠加/增强差异与人工验收；控件矩阵 `14/14 complete`。`/37 type=2/type=0`、`/39`、`/65 type=101`、重复/非法拒绝、断线重连、持久化、切号清理均通过。注入前、恢复后及重登录后的固定账号哈希均为 `99ccff91ef8285ff80565658ce2366ec615682a30ebc48378f452ac341494d29`；最终隔离回归 `7200085/1000140`、16/16 Python UI、严重异常0。正式 `BuildBatch` 两次 SHA-256 均为 `B27460DB36051DA396630CFF66EDED1115F3C3CB8148388F9574AA60A92D19AE`。证据 `.local/ui-fidelity/Task/compare/g5-live-20260727/manual-acceptance.json`、`.local/unity-validation/task-latest.json`。
- 背包历史 G0-G6（2026-08-21，已失效）：旧链漏掉510-514随机装备盒业务分母，26/26控件、视觉、Runner、人工确认与构建SHA仅作诊断线索；不得作为2026-08-24重开后的当前门禁证据。
- 装备/法宝 G0-G6收口（2026-07-27）：固定账号 `7200057 / roleId=1000115`、原生 `1334×750`；Cocos/Unity 原图、并排/叠加/差异和人工视觉均 `20/20 passed`，控件矩阵 `33/33`。Unity MCP 真实 Button 覆盖主入口、六槽、背包/碎片、帮助、详情/更换、筛选、强化和关闭；G4穿脱、失败态、断服重连、持久化与切号清理继续有效。强化页补齐真实主角头像，单次强化 UID `2121072641` 本轮 `8→10→12`；缺图0、严重异常0、Console最终0 error/0 warning。正式 `BuildBatch` 经 Unity MCP 连续两次 SHA-256 均为 `188BFD6307DFB0B0F195596D94E95ACE2E103343B8C28057F8AD5A13F580CACB`。证据 `.local/ui-fidelity/HeroEquip/compare/g5-live-20260726/manual-acceptance.json`、`.local/unity-validation/hero-equip-g6-control-runner.json`。
- 神将/阵容 G0-G6收口（2026-07-26）：固定账号 `7200057 / roleId=1000115`、同数据、原生 `1334×750` 的 Cocos/Unity 原图、并排/叠加/差异、真实 Button 自动化和人工视觉均 `16/16 passed`。修复范围包括主界面公共层与圆形头像、阵容装备/法宝真实图标、候选页残留、养成页内容与经验条、强化大师、四装备/两法宝独立详情和完整属性弹窗。最终 Runner `build/ui-migration/bootstrap-app-result.json` 于 `2026-07-26T14:31:28.6502368Z` 成功，严重异常0；纳入 `ChatLayer` 后正式 Bootstrap 双批处理幂等 SHA-256 为 `408E3FF9E994AA681B9805AF28F598F2023126E44B00EF55D0BFCACB0C49FEDC`；G5、G6门禁已通过。证据 `.local/ui-fidelity/Hero/compare/g5-live-20260726/manual-acceptance.md`。
- 装备/法宝 G4（2026-07-26）：固定账号 `7200057/1000115` 经 Unity MCP 触发真实 Button，装备强化 `3→5`、穿脱恢复、法宝穿脱恢复、金币不足、非法 UID、重复卸下、断服重启重连、正常断开持久化及切号清理全部通过。修复普通强化误入自动化卸下链、法宝失败包错读 `replacedUid` 两个根因；重启权威回读装备阵位 1/强化 5、法宝阵位 1，缺图 0。
- 神将/阵容 G0-G2（2026-07-26）：隔离账号 `7200057` 取得原生客户区 `1334×750` 的16/16当前 Cocos真实点击证据；等级1夹具 `7200260` 补齐2/5/11/15级锁定阵位及拒绝提示。协议 `/24 op=1`、`/48 op=1/4`、6个Prefab、3份配置、Lua权威/C#渲染镜像边界、断线重拉和切号清理已冻结，机器门禁 G0-G2 passed。
- 完成口径纠正（2026-07-19）：用户人工检查确认 Unity 阵容页面大量 Cocos 原有操作按钮无效果。代码复核显示 Cocos `PetZhenRongUI` 已绑定养成、强化大师、替换、空位上阵、`EquipIcon1..6`、详细属性、布阵等回调，而 Unity `HeroPresenter` 仅绑定阵位卡/背包卡选择；旧 Runner 还存在直接调用内部弹窗绕过真实按钮的问题。旧 Functional `约56%`、阵容 `visual-1to1-complete` 及对应 G0-G6 结论全部撤销，Validated 归零。
- 装备/法宝 G0-G2（2026-07-19）：冻结 `userId=7200057`、`roleId=1000078/U00057`、Windows `100%`、原生 `1334×750`；确认真实链为神将详情 `EquipIcon1..6`、独立装备/法宝背包入口、共享更换/详情 CSB 与 `/319`。隔离角色持久化装备 5、法宝 3、碎片 `4701..4706` 各 10；18 张有效 Cocos 图覆盖全部冻结页面、弹窗、成功/失败及重连状态；`op2/3/4/16/18/19`、非法/重复与卸下恢复回读完成。失败态临时夹具已用 binlog 操作前镜像回滚，源码/EXE/角色状态恢复并独立重连通过。状态升级为 `g2-complete`，允许进入 G3。
- 阵容历史试点（2026-07-19，完成结论已撤销）：曾完成五组截图和 `/24、/48` 自动化换位，但未覆盖全部 Cocos 可达控件且部分流程绕过真实按钮；仅保留为数据、视觉和协议历史证据，不再作为完成证明。
- 阵容 Lua 权威状态试点（2026-07-18）：真实入口 `ButtonGroup1/btn_zhenrong → EMID_KAPAI_SHENJIANG → KaPaiPet.PetZhenRongUI`；Unity 改为 `HeroController → LegacyFormationModel → /24、/48 → C# render mirror`。隔离 `userId=7200057`，神将 57 阵位 `1→2→1`、服务端快照、Imod 动作 1、16/16 Python UI、编译及严重异常扫描通过。仅算逻辑通过：当前 Unity 图仍有武器/法宝/技能占位文字、错误图文、顶部公共层遮挡等问题，且缺有效 Cocos 同状态截图与差异报告，状态保持 `logic-validated-visual-pending`。
- 全部基金首期（2026-07-18）：`function_id=25/26 → WelfareActivityUI → ChengZhangLayer/HuoyueLayer → /222 op=83/94`，成长/活跃各返回 2 档权威计划；共用真实 `huodong_bg`、四页签和货币栏，双回包、入口/返回及 `1334×750` 截图通过。购买/领取禁用；本地最小库仅在 `local_test=1` 且活动配置为空时返回只读样例。
- 资源找回首期（2026-07-18）：`function_id=19 → WelfareActivityUI/FindOfflineExp → huodong_bg + ziyuanzhaohui → /52 op=1` 返回 7 条权威记录；真实公共背景/双页签/货币栏、可滚动列表、成本/次数、入口/返回、`1334×750` 截图、16/16 测试、严重异常 0 均通过。`op=2` 找回首期禁用。
- 将魂/竞技场/血战商店首期（2026-07-18）：`function_id=15/16/17 → JiangHunShop/WanFaShopMainUI → /221 type=2..8` 七页全部返回，共 74 条权威商品；真实 Prefab、商品图标、页签、价格/限购/货币、入口/返回、三张 `1334×750` 截图、16/16 测试、严重异常 0 均通过。购买与刷新首期禁用。
- 玩法子页快速移植（2026-07-18）：游历 `/335 op=1`、封神列传 `/320 op=24`、竞技场 `/161 op=0` 均已改为真实 Prefab 主布局并通过模块门禁；动态模型容器与字体/装饰细节按用户要求延后人工调整。
- 玩法大厅公共层（2026-07-18）：真实 `ui_shenjiang_tips.png` 底部公告与扇子装饰已接入；最终 `userId=7200047`、16/16 测试、严重异常 0，Bootstrap SHA-256 两次一致为 `8A160A8F17CAA1B2A45AD623F941C81E9EB2A39DE119262F540AB9F30A9F0519`。
- 玩法大厅视觉修复基线（2026-07-18）：`btn_wanfa → shop/shop_bg + WanFaEntranceUI/common/ActivityLayer → WanFaInfoUI/TaskPopupLayer`；最终 `userId=7200039`，13 项与 `/65` 三类隐藏态通过。Cocos/Unity 列表与详情均为 `1334×750`，流程、节点映射、四份差异报告位于 `.local/ui-fidelity/Gameplay/`。列表全屏差异率 `12.08%`、详情 `10.70%`，因公共装饰/公告层与字体采样差异仍未通过，状态保持 `visual-fixing`。
- 活动第一阶段（2026-07-18）：当前真实链为 `UImainLayer_new/ButtonGroup5/btn_huodong → WelfareActivityFormerUI → csd/huodong/ActivityRankingLayer + ActivityLevelLayer → /222 op=0xFF`；首个子页为 `tag=1 DailyRechargeUI → csd/DailyChargeLayer → /222 op=18/subOp=1`。最终 `userId=7200020`、`roleId=1000034`，列表 2 条、奖励 1 条，三张 `1334×750` 截图，严重异常 0，夹具与备份表残留 0。
- `.ani` 专项（2026-07-18）：活动 Lua 共 67 个构造入口、208 个调用、38 个动态加载表达式；886/886 ANI 可解析。Unity 逐项通过 885 个可播放资源、1327 个动作、10264 个动作序列帧，PNG/ANI 分离、附加层、翻转、颜色、透明度、旧速度倍率均通过；固定 UI 24 路径中 18 个真实播放、6 个源包缺整组资源，另有 `Skill/skill_5_h_l.ani` 缺 PNG。视觉联系表 `.local/validation/imod-static-ui-contact-sheet.png`。
- CSB Timeline 专项（2026-07-18）：29 处有效调用展开为 27 个唯一资源/Prefab；22 个有真实轨道、5 个源文件本身为空时间轴。累计导入 461 条轨道、2478 帧、34 个命名片段；唯一 CSB-only `FengShenLayer.csb` 已逐帧解码。Unity 实例化播放 27/27、命名片段 34/34、非空 FrameEvent 3/3，视觉抽样见 `.local/validation/timeline-*.png`。
- 真实资源：`LoginBgLayer.csb、loginLayer.csb、SeverListLayer.csb、RoleCreateLayer.csb`；登录背景 `res2/animation/effect_chuangjue_1` 动作 0 循环。
- Unity 门禁：依次断言 Logo 0.5 秒、Windows 六组资源预载态、本地服按钮与登录动画、`RoleCreateLayer` 男女动作、当前 `UImainLayer`，最后发送 `/88` 并渲染真实 `NoticeLayer` 标题/正文。
- 最终隔离账号：`userId=7300109`、`roleId=1000046`；公告验证数据由脚本临时写入并在退出路径精确清理。
- 结果：`build/ui-migration/bootstrap-app-result.json`，`success=true`；`bootstrap-login.png`、`bootstrap-login-notice.png` 均为 `1334×750`；严重异常 `0`。
- 活动旧版 `/209 + ActivityLayer` 结果已判为错误版本证据，不再计入完成率，也不得提交。
## 4. 总迁移顺序

| 阶段 | 模块 | 说明 |
|---|---|---|
| Steam 发布前置 | SQLite S0-S8：基线 → 双后端 → Schema → SQL兼容 → 核心数据 → Steam业务回归 → Unity监管 → 生命周期 → 干净机 | 不改变业务模块分母；通过后解除 Windows 正式发布阻塞 |
| P0 基础层 | 登录与创角 → 系统设置 → 主界面HUD等基础模块 | 规划顺序，不重复维护完成率 |
| P1 其他单人功能 | 玩法大厅、封神列传、法宝搜索、游历三界 | 规划顺序，不重复维护完成率 |
| P2 运营与商业化 | 无保留活动模块 | 规划顺序，不重复维护完成率 |
| P3 竞技/玩家依赖 | 当前无保留模块；竞技场保持屏蔽 | 规划顺序，不重复维护完成率 |
| P4 社交最后 | 好友、聊天、队伍、帮派/宗门全部排除；支付前置不计入16个业务模块，历史边界见`PAYMENT.md` | 规划顺序，不重复维护完成率 |
## 5. Steam版本范围待确认

| 建议 | 尚未正式完成的模块 | Steam判断依据 |
|---|---|---|
| 已确认排除 | 七日目标、全部基金、资源找回、福利（含体力领取）、好友（含好友赠送）、聊天、队伍、帮派/宗门、活动、决战昆仑、血战到底、竞技场 | Steam入口、路由、共享刷新、Runner按模块边界屏蔽；竞技场由用户于2026-08-31再次确认保持屏蔽 |
| 保留 | 法宝搜索、游历三界、封神列传 | 三项均为单人权威状态；法宝搜索`/319`和游历`/335`不属于战斗播放模块 |
## 6. 已知风险

- 流程只认 `MIGRATION_GUIDE.md`；配置扣款/奖励以服务端真实结果为准；Runner必须清旧结果、校验时间戳且同一隔离角色不得并发。
- Prefab优先运行时绑定；仓库多代UI和38组同名Prefab必须按当前入口调用链归属，禁止按名称或旧截图判断。
- 保留用户现有xlua `.meta`删除和`.vscode/`；Imod仍缺6整组资源及1个贴图，补齐原始美术前不得报100%。
## 7. 状态维护规则
- 每批只更新总进度、模块状态、最新验证和当前批次；协议与实现证据写入 `docs/unityclient/modules/`。
- 日期流水写入 `docs/unityclient/history/YYYY-MM.md`；默认读取顺序：`AGENTS.md → 本文件 → MIGRATION_GUIDE.md → modules/README.md → 目标模块文档/矩阵`。
