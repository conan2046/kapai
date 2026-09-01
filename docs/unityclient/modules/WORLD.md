# 世界/战斗/副本模块

> 状态：V0 产品边界已收口；A=`16,19`，`47–53`确认移除；2026-09-01修复详情自动弹出、关卡点击错位、锁定节点假战斗及孤立星级夹具后，目标10023真实`op=8`结算、连续进度、两级返回与重登恢复重新通过标准G3；用户确认本轮早测通过，G4-G6保持pending。列传19的BattleFengShenStory子模块仍为G0-G6通过。

## V0 当前 Cocos 产品边界（产品决策已确认）

- 2026-08-31 从正常登录使用唯一原生 `ProjectX.exe / Cocos Simulator` 黑盒闭合：主界面副本 → 第3章 → 3-3 → 挑战 → `EFT_GuanQia=16` → 跳过后返回地图。固定 Cocos MySQL 身份实际为 `7200057/1000115`，不是 Unity SQLite 的 `7200057/1000003`。
- 本轮服务端日志明确记录挑战后发送 `/38` 1653 bytes、`/320` 60/16 bytes、`/321`、`/18`、`/15`；当前源码将 `/38 op5`内嵌流交给 `/21-/23 → LBattleLogic → FirstFightResultUI`。
- A：`EFT_GuanQia=16`与`EFTLieZhuanFight=19`。B：共享`/38`、`/21-/23`、FightLayer、LBattleLogic、Imod等。19已闭合当前入口、op25、战斗、真实跳过和直接返回地图。
- 当前枚举实际为59项；旧“52项已逐项审计”只覆盖52项并漏分47-53七类。用户确认 `47–53` 均不保留，现转 D：Steam/当前产品不迁移、不验收，后端及源码仅保留追溯。
- 用户于2026-08-31确认的“跳过后直接返回地图”仅适用于主动跳过。2026-09-01早测确认自然结束仍必须进入权威结算；Unity已按自然结束/主动跳过两条生命周期分流。
- 机器清单：`.local/unity-validation/cocos-current-version-boundary-v0-latest.json`；本轮窗口证据：`.local/unity-validation/v0-cocos-current-boundary/`；可逆MySQL快照：`.local/unity-validation/v0-world-mysql-snapshot.json`。
- 列传19当前动态证据：`.local/unity-validation/v0-battlefengshenstory-runtime-latest.json`；两次精确恢复、重登与零残留：`.local/unity-validation/v0-battlefengshenstory-cleanup-latest.json`。
- Unity列传19已完成G6：SQLite固定身份`7200057/1000003`，真实EventSystem 9/9、`fightType=19`、10单位；自然播放进入权威结算、统计、回放、关闭与返回奖励，主动跳过隐藏播放层并重拉op24直回列传地图且不生成结算。用户确认神将朝向修复；标准batch、十态G5、两次BuildBatch及自动复盘均通过。证据`.local/unity-validation/battlefengshenstory-fixed-account-latest.json`、`.local/ui-fidelity/BattleFengShenStory/compare/g5/report.json`、`.local/unity-validation/battlefengshenstory-retrospective-latest.json`。

- 本轮范围只处理世界/副本战斗表现；封神剧情保持 G0-G3 等待用户早期 Play，寻宝与公共货币栏暂停。
- 当前 `cocosBaselineInputs` 已冻结入口、`/320`、`/38` 内嵌 `/21-/23`、`LBattleLogic`、战斗单位/技能/飘字、FightLayer、Imod语义、服务端战报和结算输入；当前指纹由标准 G5 preflight 生成。
- G1 已在 Cocos MySQL 固定身份 `7200057/1000115`、关卡 `10023`、原生 `1334×750` 下重新取得普攻、技能、受击、死亡、伤害飘字、血条、站位、镜头、前后摇、回合节奏、结算、回放二次结算与继续返回；Unity验证使用独立SQLite身份`7200057/1000003`。当前目录 `.local/ui-fidelity/World/cocos/g1-current-battle/`，输入指纹 `F0468C3D6B8645884BE529BEB0B4CAABF12C0CC1C0AE5A399FE482771590D327`。
- 用户当前不在电脑旁，并于 2026-08-30 明确委托代理全权测试。代理早测必须保持 `userParticipated=false`、`userDelegatedAgentPlay=true`，使用真实 Unity Editor/GameView/EventSystem 与 persistentDataPath SQLite；最终 G6 用户确认仍保留。

## 2026-09-01 当前 G3-G5 结果

### 2026-09-01 用户早测阻塞修复

- 当前最终G3证据：`.local/unity-validation/world-stage-progression-runtime.log`、`.local/unity-validation/world-g3-runtime-latest.json`、`.local/unity-validation/world-fixed-account-runner-latest.json`。目标节点10023生成权威`guanqia-result`，普通宝箱及确认按钮走真实EventSystem射线点击；连续节点星级、详情打开时机、两级返回、重登哈希、精确恢复和残留清理全部通过。

- 普通关卡宝箱：接入当前 `reward_fixed_dat.lua`，弹窗渲染真实物品名、图标、品质和数量；可领取态显示“领取”并继续使用权威 `/320 op=4`，未解锁/已领取态保留奖励预览。
- 两级返回：`DadituuiLayer/Title/CloseBtn` 使用独立真实射线面；在`kapaiguaiwuLayer`点击先返回`WorldMapNewLayer`，再从`WorldMapNewLayer`点击返回`UImainLayer_new`，标准G3以连续两次EventSystem点击验证该逆向层级。
- 详情打开时机：普通`/320 op=2`只显示`kapaiguaiwuLayer`并清空待消费的`requestedStageId`；不再自动发送`op=27`。只有玩家真实点击关卡节点后才请求`op=27`并显示`guanqiaxiangxiLayer`。
- 关卡点击与星级：移除覆盖原生非线性节点的等宽透明按钮，真实点击改为对应`Node_N/touchLayer`；服务端同时修复未解锁节点判断，禁止“点击2-3却挑战相邻锁定节点、战斗胜利但没有`/320 op=8`结算”的假成功。权威`op=8`仍按`foughtStageId`更新节点星级并由后续`op=2`持久化回读。
- 固定账号进度：旧SQLite夹具只写`3-3=3星`并强制章节总星数为10，造成前置节点0星的孤立状态。现改为连续链`3-1=3、3-2=3、3-3=3、3-4=1、3-5=0（已解锁）`，并强制`sumStar`等于所有节点星数之和；夹具断言拒绝再次生成跳关数据。
- 三个入口按Cocos语义拆分：`duiwu`打开直接布阵弹窗，`btn_zhenrong`打开神将阵容页，`Button_zhuxianchengjiu`打开导入的主线成就页；成就页接入 `/320 op=11`查询和`op=12`领取，并读取`map_achievement_dat.lua`渲染六档奖励。
- 布阵模型：`duiwu`不再直接显示空数据预制体，先通过现有Lua权威链请求`/24`神将和`/48`阵容快照，再显示`shenjiangzhenxingLayer`；固定账号出战神将57已加载`Monster/btm103_zd`并按Cocos动作1循环，G3断言实际模型数等于权威出战数。
- 星数进度：`DadituuiLayer/Panel_1/jindutiao.fillAmount`改为`OwnedStars/MaximumStars`，不再保留Prefab默认0.66。
- 固定账号`7200057/1000003`重新完成G3：真实EventSystem三入口与返回、布阵模型、编译预检、重登稳定哈希、整库精确恢复、Cleanup和残留0通过。用户于2026-09-01确认本轮早测通过；星数排行按用户明确要求暂不处理，后续允许从G4继续。

- G0-G2 已按当前源码、资源、协议、固定身份与动态证据重新通过；旧 World G3-G6 未复用。
- G3 固定账号 batch 已通过：真实 `/38 op=5` 内嵌 `/21-/23`、5 个单位、18 组动作、多目标 HP/飘字/受击/死亡、结算、统计、关闭统计均执行。真实点击 `Button_Replay` 后先显示章节地图，约 `0.5` 秒后调用缓存战报重播并再次进入结算；第二次结算真实点击继续后返回章节地图。共享战报层不再丢弃召唤、逃跑、被动加扣血和喊话，并按当前 `LBattleLogic.lua` 保留闪避、保护者、反震和反击字段；基础闪避字样、保护者承伤、反震/反击回伤已接入播放层。
- 战斗表现已从固定 `gj/sf1 + 42%` 近似播放改为共享配置驱动：Unity按当前Cocos原始 `skill_client.dat / skill_attack_client.dat / skill_effect_client.dat / skill_behit_client.dat` 解析动作片段、延迟、动作号、移动类型/时长、技能Imod方向/缩放/挂点与被击时点；动作片段按 `LBattleLogic:PlayNextActionClip` 的允许重叠语义调度，不再错误串行；运行日志记录每组动作实际配置链。
- `skill_camerashock.dat` 已按 Cocos 的播放时长×延迟比例、震动时长和强度接入；当前真实包触发6/7号震屏并生成 `build/ui-migration/world-battle-shake-01.png`。技能配置引用的32个 battle MP3 已从当前Cocos运行资源精确水合，运行日志实际记录 `beiji / baozha / waterdragon`，无 `WORLD_BATTLE_AUDIO_MISSING`。
- `stateStruct` 不再只读首字节后丢弃数组：初始单位、攻击/治疗/Buff目标、保护者、来源和被动状态均保留Buff ID。`buff_client.dat` 的56张当前 `Buff_tips` 图标已水合；图标型Buff按血条上下位置渲染，特效型Buff按脚/腰/头打击点加载对应Skill Imod。当前固定包未覆盖每个Buff ID，因此全Buff视觉仍需后续类型夹具逐项验证。
- Cocos `skill_name` 的 `dodgetext / injurytext / beatbacktext` 已替代Unity文字近似：闪避显示原图，反震在反震方显示受伤反弹提示，反击方显示原反击提示并播放攻击动作；保护者按 `CheckAttackProtecters` 语义先移动至受击目标前方，承伤后在动作结束复位。当前固定包不含保护/反震/反击组合，动态时序仍保留为后续专用夹具必验项。
- 资源水合缺口已关闭：Bootstrap实际读取的72张副本地图、3张章节图、1张战斗背景、59张技能图、`hit_monster.dat`、`zhenfa_config_dat.lua`、`num_lan.png`、`ui_pk_num.png`和6张阵法图标，共145个Cocos源文件及对应Unity运行资源均已从本机LFS对象库定向水合。中央固定账号预检现在逐个检查这145个源文件；`BootstrapSceneBuilder.CopyResourceIfChanged` 在源内容为LFS指针时直接失败，禁止再以“BuildBatch返回0”掩盖资源被指针覆盖。

### 全战斗类型边界清单

- 当前 `server/src/fight.h::CFight::EFightType` 权威枚举共 `59` 种：按源码注释初分为 `44` 种PVE、`14` 种PVP/竞技、`1` 种跨服雪莲混合待核；机器清单 `.local/unity-validation/battle-type-inventory-latest.json`，SHA-256 `616E03774AD191A59CD179A4B6A8EF89A339E8F81E7679A9E6F1075D83FB3F99`。
- 2026-08-31已对当前源码52个`EFightType`逐项执行产品范围审计。现行Steam战斗分母只有`EFT_GuanQia=16`与`EFTLieZhuanFight=19`；World只证明前者，列传战斗模块独立证明后者。其余50种均为用户排除、平台排除、当前正式入口不可达或CG/测试类型，未来产品范围变化时才从G0重新启动，不能以共享播放器支持冒充通过。
- `EFTXunBaoFight=21`属于`MSG_CHUANG_GUAN/213`的大富翁小贼战斗，不是当前法宝搜索`/319`；`EFTXiuXian=46`属于旧场景/队伍战斗，不是当前游历`/335`。竞技场`44`已由用户确认保持屏蔽。冻结证据`.local/unity-validation/battle-current-denominator-latest.json`。
- 运行时通过 `UiPrefabLoader` 复用导入的 `common/FightLayer`，已显示原版顶部栏、18个阵位圈、X1加速和跳过按钮；不修改源Prefab。顶部双方名称按Cocos左右阵营语义显示，当前神将技能名取权威 `HeroCatalog`。
- 交互：统计、统计关闭、回放、第二次结算继续均使用真实 EventSystem raycast。当前 Cocos 的 `LBattleLogic → LRoleDataMgr:GetFightDatum → FightDatumUI` 使用播放期逐单位战报；Unity 现按同一 `/38` 数据渲染双方单位伤害、承伤与治疗，不再错误要求“/320 无单位战报”的边界弹窗。
- 数据：仅使用 `Application.persistentDataPath/LocalServer/projectx.db`；快照、Setup/Assert、Restore、重登稳定哈希、Fixture残留0和精确哈希恢复通过。
- 原固定30秒结算等待在动作集扩充后提前超时，现已按权威 `/22` 动作数增加播放额度；失败与解决记录均保留在 World operation ledger。当前G3为5单位、18动作组并捕获真实type-1普攻；九态固定文件为 `world-battle-entry/normal-attack/skill/hurt-damage/death/round-rhythm/settlement/replay/return.png`，另保留回放瞬时章节图。当前 Cocos 与 Unity 服务器指纹一致：seed `20260830`、replay FNV1a32 `1970000362`、result FNV1a32 `3942185584`；当前 G3 源合同指纹 `C6993BCF26AD28F8346ECF2FDA22E2471B39D1FDCC97D78164CF9FEF4DAAC7E5`；摘要 `.local/unity-validation/world-g3-runtime-latest.json`。
- Cocos角色的等级99、经验0、战力17240、神将57/64、出战57及pet/zhenfa/pet_equip已冻结到Unity SQLite夹具。G3战斗视觉路径不再先执行5次扫荡，结算经验由旧流程的5940修正为与Cocos一致的`990/419760`；跳过按钮按Cocos合同保持可见，`packetCanSkip=false`只阻止跳过动作。伤害飘字已使用原始 `ui_pk_num.png` 字模及Cocos缩放/停留/上移/淡出时序；胜利结算恢复CSB静态标题与 `effect_zhandoujiesuan_2` 动作0叠加。
- 动作状态机已按当前 `LBattleLogic` 收敛：移动类型1-12使用当前节点、固定60/35或60/60偏移、行列/阵营中心阵位，位移改为线性`MoveTo`且0.2秒配置不再被钳到0.5秒；零位移模型/特效读取真实Imod帧时长，动作尾部保留Cocos的0.1秒回位间隔，X倍速同步应用到单位Imod。静止`ActSrcPos/TgtSrcPos`特效改为挂在施法者/目标节点，取证从固定45%改为每个动作计算出的命中点；敌方姓名改蓝、己方姓名改紫并缩小取消粗体。
- 模型挂点与血条已按当前Cocos源闭合：从模拟器有效二进制`hit_monster.dat`解析158组怪物`LBTHitCfg`脚/腰/头/HP坐标，玩家使用当前6组`HeroHitData`职业坐标；服务器单位缩放参与模型与挂点缩放，血条改用导入的原版80×9 `HPNode.prefab`红/绿填充图，不再使用胸前手绘条。单位名恢复`BattleUnitNode.lua`的本地`Y=-20`、字号20；Pet按当前quality映射显示A/S/SS/SSS/SSSS，HP根节点保持Cocos的高层级，使A标覆盖同位的type-3护盾状态图。
- 回合/阵法HUD已按当前Cocos源闭合：`/21`的`currentTurn`和双方阵法ID/等级不再丢弃，`00/30`通过原`num_lan.png`的60×75位图字渲染，两侧使用6张有效`zhenfa`图标；阵位圈严格执行`LBattleLogic`的“占用位255、阵法有效空位100、无效位隐藏”，并去除导入Unity按钮根节点产生的白色占位底图。
- 当前委托代理早期Play已通过：真实Unity Editor/GameView/EventSystem完成主界面→副本→第3章→3-3→挑战→`fightType=16`自然三星结算→继续返回，次数`5/10→4/10`；记录保持`userParticipated=false`、`userDelegatedAgentPlay=true`、`manualPassed=false`。当前G4固定账号完整batch、重登稳定哈希、整库精确恢复、Cleanup与零残留均通过，证据`.local/unity-validation/world-early-user-play-latest.json`、`.local/unity-validation/world-fixed-account-latest.json`。
- 当前G5九态双端视觉报告已通过：ENTRY MAE=`4.8311`，其余稳定战斗态无阻塞差异；结算/回放与返回的较高差值来自同一非循环结算Timeline和地图Imod站立相位。证据`.local/ui-fidelity/World/compare/g5-current-battle/report.json`、`.local/unity-validation/world-g5-visual-assessment-latest.json`及两张contact sheet。
- 当前G3-G5夹具只使用persistentDataPath SQLite；`Setup/AssertSetup → Restore/AssertRestored → 重登稳定哈希 → Cleanup/AssertCleanup`全部通过，WAL/SHM/备份与隔离账号残留为0。BattleFengShenStory也已在共享战斗修改后完成9/9完整batch回归。当前产品战斗分母仅`16/19`，其余50种不进入当前验收；World只剩G6用户最终确认，禁止代理冒充通过。

### 当前代理早期 Play（2026-09-01）

- 用户明确委托代理全权测试；授权证据 `.local/unity-validation/world-agent-test-delegation-20260830.json`，当前早测记录 `.local/unity-validation/world-early-user-play-latest.json`。记录明确保持 `userParticipated=false`、`userDelegatedAgentPlay=true`、`manualPassed=false`，未冒充用户真人参与；该轮已用于关闭G3早测前置并推进G4，不能替代G6用户最终确认。
- 固定身份：Unity persistentDataPath SQLite `userId=7200057 / roleId=1000003`；从Bootstrap真实登录进入，不使用Runner内部完成方法。
- 5–15分钟主路径：世界入口 → 第3章/章节下拉 → 3-3详情 → 布阵并返回同一详情 → 扫荡/再次扫荡/关闭 → 重置确认 → 挑战 → 普攻/技能/受击/死亡/飘字/血条/站位/震屏/音效/回合节奏 → 胜利结算 → 统计/关闭 → 回放 → 再次结算并返回章节地图。
- 代理使用真实 Unity Editor/GameView、Computer Use 与 EventSystem 点击完成副本入口、挑战、战斗、结算、回放、再次结算和继续返回；停止后执行 `AssertSetup → Restore → 重登哈希 → AssertRestored → Cleanup → AssertCleanup`。最终数据库SHA-256恢复为 `7445FEEC27B2BED88164FFBD9CEF426B3559E58AFB6F51A357258AF51701E669`，WAL/SHM/备份、隔离账号和进程残留均为0。

## 2026-08-28 真人反馈与门禁降级

- 实际缺陷一：点击挑战后 Unity 未消费服务端 `/38 op=5` 内嵌的 `/21` 进入、`/22` 战斗过程和 `/23` 战斗结束，直接使用 `/320 op=8` 弹出结算，导致完整战斗被跳过。
- 实际缺陷二：结算继续仅给 `Layer/Panel` 动态添加 `Button`，Panel 本体没有全屏 `raycastTarget`；旧 Runner 又直接执行 `continueButton.onClick.Invoke()`，因此假通过了玩家鼠标无法关闭的控件。
- 状态处理：撤销 World G4-G6 和 `25/25 complete`；`WORLD-14/21/22` 及新增 `WORLD-28..31` 等待当前证据。旧截图和自动化只能作为定位线索。
- 初版修复：`LegacyTcpMessage` 已支持读取嵌套战报；`WorldBattleReplayStore` 解析真实参战单位、动作组和胜负；`WorldBattlePlaybackPresenter` 仅依据真实战报显示单位/动作进度，完成后才放行 `/320 op=8`；结算 Panel 已补透明全屏射线图形，回归改用 `InvokeEventSystemRaycastClick`。
- 当前结果：当前 Cocos 战斗基准已补齐。Unity G3 使用 persistentDataPath SQLite 固定账号 `7200057/1000003`，真实完成章节切换、下拉/动态节点、布阵返回、详情关闭、扫荡/再次扫荡、重置确认、挑战、完整战斗、结算统计和回放返回；所有可见操作均走 EventSystem 射线。DataPreflight、编译、G3、重登稳定哈希、整库精确恢复和残留 0 通过，中央工具链 `266/266`，当前源码合同指纹 `3BA5E5058854C3E35CEC1BD0A214491E4BFA2B35591A6BF0726030F3D0A87D67`。G5-G6 仍待早期用户 Play 后重做，禁止提前设置受影响控件 `manualPassed=true`。

## G0 范围冻结

- 唯一入口：`UImainLayer_new/Layer/Main_UI/btn_fuben → MainUI:FuBenTouchCallback → Utils:OpenFunction(EMID_KAPAI_ZHUXIANFUBEN) → FuBenMap.NormalFuBenUI`。
- 本轮包含：世界章节地图、章节关卡地图、关卡详情、主线 `/320 op=1/2/4/5/6/7/8/27`、挑战、扫荡、次数重置、普通/星级宝箱、战斗结算与其可达弹窗。
- 本轮状态：正常、未解锁、体力不足、次数用尽、重置次数用尽、宝箱不可领/可领/已领、挑战成功/失败、重拉、重进、断线重连、切号和精确恢复。
- 冻结 `31` 项源码审计对象：`29` 个实际控件进入当前 G4 自动验收，另 `WORLD-07-WORLD-CLOSE`、`WORLD-24-BATTLE-REVIVE` 两项经源码证明不属于独立 World 控件；完整矩阵：`docs/unityclient/matrices/WORLD_CONTROLS.json`。
- 排除但必须在 Unity 明确隐藏/禁用：支线、帮派副本、封神试炼、排行榜、主线成就、商城加币、体力补给、非 `/320` PvP；`/21-/23` 只允许作为当前 `/38 op=5` 内嵌权威战报消费，不得用假数据或静态图替代。
- Unity 固定验证账号冻结为 `Application.persistentDataPath/LocalServer/projectx.db` 内的 `userId=7200057 / roleId=1000003`，夹具临时创建隔离账号 `userId=705213 / roleId=1000006`；Fixture 必须整库快照、精确恢复并检查 WAL/SHM/备份零残留，G3 启动 Unity 前执行 `Run-UnityFixedAccountValidation.ps1 -Module World -DataPreflightOnly`。
- 当前环境：Cocos、`kapai.exe`、Unity 和工作区 MySQL 均已停止；固定账号已精确恢复。

## G1 Cocos 运行取证（passed）

- 2026-08-28 当前轮使用 Computer Use 对唯一原生 `ProjectX.exe / Cocos Simulator` 执行真实路径：`主界面 → 副本 → 第3章 → 3-3挑战并观察战败 → 3-1挑战 → 胜利结算 → 回放 → 再次结算 → 点击屏幕关闭`。全部点击使用同控件一像素拖动作为该原生窗口当前可用的 press/release 手势。
- 当前战斗画面确认：`30` 回合上限、18 个 `FightLayer.csb` 权威阵位、单位 Imod、进场特效、普攻字样、受击/伤害数字、血条、死亡姿态、三倍速和跳过；单位脚底只显示一行阵营/品质色名称，不显示等级或原始 HP 调试堆叠。
- 当前结算行为确认：胜利后显示三星、奖励、经验、统计、回放和“点击屏幕继续”；回放会重新进入完整战斗，第二次结算后真实点击空白区域关闭并返回同一章节地图。
- 当前 `1334×750` 裁切证据：`.local/ui-fidelity/World/cocos/g1-20260828-battle/02-battle-start.png`、`03-battle-round4.png`、`04-victory-settlement.png`、`05-after-close.png`。原始 `FightLayer.csb` SHA-256 为 `45B119F59AFAA85B9DBFFDAA7AA7875C5001D1ED031DCCC4BB3BF23C16BB0898`，解码证据 `.local/unity-validation/fightlayer-csb-raw.json`。
- 本轮操作前快照哈希为 `a469dc2e6acfc416bfcdc18bc57e7fa42e08c1d92269abc8d43bbf9eba3e8809`。首次误在 Setup 前挑战的单行 `role_info` 变更已由 MySQL ROW/FULL binlog 的 53 列 before-image 精确恢复；正式取证轮 Setup/cleanup 后再次通过同哈希与 Fixture 残留 `0`，证据 `.local/unity-validation/world-cocos-binlog-recovery-latest.json`。
- G1 当前结论：新增 `WORLD-28..31` 的 Cocos 进入战斗、单位/阵位、动作序列、胜利结算、回放和关闭行为图谱齐全；Unity 对照与自动化状态仍保持 pending，不用本轮 Cocos 通过冒充后续门禁。

- 电脑操作已切换为用户指定的 Computer Use 链路；不再使用项目窗口脚本驱动 Cocos。该链路实际完成：`主界面 → btn_fuben → 世界地图 → 第3章解救妲己 → 3-3 黄飞虎详情 → 返回`。
- 当前原生证据均由该工具取得、再裁去窗口边框为 `1334×750`：`WORLD-00` 主界面、`01` 世界地图、`02` 第三章、`03` 3-3 详情、`05` 章节下拉、`06/09` 宝箱领取前后、`07` 真实扫荡、`08` 三星结算、`10` 次数重置确认；目录 `.local/ui-fidelity/World/cocos/g1-20260731-cua/`，`capture-manifest.json` 记录固定账号、窗口和裁切边界。
- 服务端同一会话实际触发 `/320 op=1/2/4/5/6/7/8/27`；`op=6` 扣 25 体力并产出五次扫荡奖励，`op=7` 消耗 50 元宝重置，`op=5→8` 进入真实 PvE 后返回三星结算，`op=4` 后宝箱打开。协议静态提取为 `.local/protocol-evidence/320.md`。
- 可逆数据面：`Invoke-WorldCocosFixture.ps1` 快照 `guan_qia/package/save_data/save_val/user_spirit/mission/角色与账户货币`；两轮操作后均恢复 `1fe6274907b6aef8f631994fa0a7c4d9b17e19fe30e7a5b54ae2a6aca0eca11d`，Fixture 表残留 `0`。启动期 `rank_list_save` 缺列已在本地最小 schema 修复并以固定账号协议 smoke 回归，无该 SQL 错误。
- 前次项目窗口脚本的后台/前台点击失败仅作为工具选择错误，不构成本轮 G1 结论，也不作为证据。
- G1 结论：入口、列表、详情、扫荡、重置、战斗与宝箱的当前 Cocos 证据及 Lua→`/320` 链路齐全。断线重连、切号和异常分支保留 G4 的真实 Unity 验收，不用旧 Runner 或 Unity 假数据替代。

## 历史第一阶段范围（非本轮证据）

- 已完成：世界地图入口、章节列表、章节关卡列表、关卡状态、详情、挑战次数/体力、阵容摘要、奖励预览、一次本地主线挑战、结算奖励、刷新后星级持久化。
- 复用：`HeroStore`、`FormationStore`、`RewardRecord/RewardStore/RewardPresenter`、`ResourceService`、`VirtualList`、`UiStack` 和通用弹窗。
- 不包含：PvP、完整战斗表现、技能特效、自动战斗、数值平衡、扫荡、重置和宝箱领取。

## G0 静态链路（已由 G1/G2 复核）

### 协议与服务端

- 操作码：`server/src/protocol.h` 的 `MSG_GUANQIA = 320`。
- 注册：`server/src/pack_deal.cpp` 将 `/320` 注册到 `CPackageDeal::DealGuanQia`。
- 处理：`DealGuanQia` 分派 `CUserGuanQia`；本阶段锁定 `op=1/2/5/8/27`。

| op | 方向 | 字段与用途 |
|---:|---|---|
| 1 | C→S→C | 请求 `type:u8`；响应章节数量、章节 `id/name/openLv/maxStars`、当前章/关及各章星数/宝箱状态 |
| 2 | C→S→C | 请求 `type:u8,mapId:u32`；响应关卡 `id/name/stars/remainingAttempts/spirit/resets/resetCost/next/box`、货币/物品奖励、星级宝箱 |
| 27 | C→S→C | 查询 `type,mapId,nodeId`；响应 `stars/fightCnt/resetCnt`，`stars=255` 表示未开启 |
| 4 | C→S→C | 领取普通/星级宝箱 `type,mapId,fixId`；状态 `1→2` 后按 `MUT_GuanQiaFix` 发权威奖励 |
| 5 | C→S→C | 挑战 `type,mapId,nodeId`；服务端进入本地 PvE 处理 |
| 6 | C→S→C | 扫荡 `type,mapId,nodeId`；按当前体力及剩余次数取 `0..5` 次，发多段奖励并写次数 |
| 7 | C→S→C | 重置 `nodeId`；按 50/50/100/100/200 元宝梯度扣款、清挑战次数、递增重置次数 |
| 8 | S→C | 结算推送：`alreadyFightTimes,stageId,unlockedChapter,unlockedStage,box,starBox,stars,rewardCount,rewards` |

- 通用奖励三元组为 `type:u16,id:u32,amount:u32`。货币奖励可使用 `type=600xx,id=0`；显示层保留权威 `id=0`，仅用 `type` 查询现有 `ItemCatalog`。
- `/21-23` 属于旧战斗表现流，当前服务端分发表未形成可验证闭环；本阶段不做无证据旁路。
- `/195` 是场景传送，不等同于卡牌副本 `/320`。

### 旧客户端与真实 Prefab

- 请求：`client/ProjectX/src/NetWork/LuaNetSendMsg.lua` 的 `QueryDituInfo`、`QueryStageInfo`、`QueryFightSatge`、`QueryFuBenInfo`。
- 解析：`client/ProjectX/src/NetWork/LuaNetRecvdMsg.lua` 的 `DealBigMapMsg`、`ReadBattleResult`。
- 入口：旧 `MainUI.lua`，Unity 节点 `Layer/Main_UI/btn_fuben`。
- 页面：旧 `View/FuBenMap/NormalFuBenUI.lua`、`FuBenDetailUI.lua`、`StageInfoUI.lua`。
- Prefab：`fuben/WorldMapNewLayer`、`fuben/DadituuiLayer`、`fuben/guanqiaxiangxiLayer`；结算复用 `common/tanchuangjiangli`，`common/zhandoujiesuanLayer` 只保留为后续战斗表现证据。
- 取证草稿：`.local/protocol-evidence/320.md`。

## G2 迁移设计（passed）

- 2026-08-28 当前源码审计补齐完整战斗闭包：`StageInfoUI:challengeEvent → /320 op=5 → /38 op=5 内嵌 /21,/22,/23 → LBattleLogic → FirstFightResultUI`；Unity 只在 World 打开时接管该回放包，结算仍只消费 `/320 op=8` 权威奖励。
- `common/FightLayer.csb` 已用仓库中央 CSB 解码器直接读取；18 个 `Image_N` 坐标、`1334×750` 坐标系、回合 HUD、三倍速和跳过均有当前源证据。玩家源位置 `1..9` 按 Cocos `m_bIsFlipPos` 映射到屏幕右侧 `10..18`，敌方 `10..18` 映射到左侧 `1..9`。
- 单位资源语义闭合为 `Monster/btm{picture}_{zd,gj,sf1,bj,sw}` 和 `res2/fx/zhandoukaishi`；不再用半身像或静态结算代替战斗动作。按当前用户验收隐藏所有常驻脚底名称，仅保留血条、回合/控制文本和瞬时伤害；等级与原始 HP 调试文本明确禁止。
- G2 当前结论：入口、共享协议所有权、配置到资源、运行时 Transform/翻转、文字语义均已写入 `WORLD_CONTROLS.json.sourceAudit`；G3 可继续当前实现与编译，后续门禁仍需实际 Unity 证据。

- 权威边界：`LuaNetSendMsg → /320 → CPackageDeal::DealGuanQia → CUserGuanQia` 是唯一数据和扣费边界；Unity `WorldStore` 只能在 `WorldController.lua.txt` 收到完整成功包后渲染，禁止先写本地扣体力、次数、宝箱或奖励。
- 资源语义：`WorldMapNewLayer` 是世界底图，`DadituuiLayer` 是章节地图（含动态关卡/宝箱和 Timeline），`guanqiaxiangxiLayer` 是关卡详情；扫荡结果为 `FuBenMap.SaoDangResultUI`，战斗结算是当前 Cocos 战斗流结果页，不能用静态奖励弹窗替代。
- 现有 Unity 缺口：`WorldPresenter` 只绑定章节、关闭、详情关闭和挑战，且主动隐藏 `Button_1/Button_3`；`WorldController` 只解析 `op=1/2/5/8/27`。G3 必须补齐 `op=4/6/7`、普通/星级箱状态、扫荡结果、重置确认/失败、真实阵容入口、返回栈、断线重拉与切号清理；排除入口（封神试炼、排行榜、主线成就、商城加币）必须隐藏，不可留空壳。
- 可逆策略：`Invoke-WorldCocosFixture.ps1` 仅接受 `Application.persistentDataPath/LocalServer/projectx.db`。服务端/Unity/Cocos 全停时对 SQLite 整库 checkpoint+快照，临时注入第2/3章、3-3关`10023`、普通箱`10031`和十星箱`20031`，并临时创建隔离账号；最终以数据库文件 SHA-256、恢复后重登稳定字段哈希、备份/WAL/SHM 和隔离账号零残留断言。G3 前必须先跑 `Run-UnityFixedAccountValidation.ps1 -Module World -DataPreflightOnly`。

- G2 结论：控件矩阵、`/320` 全操作码、服务端实现、资源语义、固定账号与恢复合同已对齐；静态实现只可消费服务端成功包。

## G3 静态实现（passed）

- `/320 op=4/6/7` 的请求与成功/失败包解析已接入；章节、详情、宝箱、扫荡、重置和布阵已连接到现有导入 Prefab。
- 扫荡结果 `fuben/saodangLayer`、战斗结算 `common/zhandoujiesuanLayer`、统计页 `common/zhandoutongji` 已由 `WorldOutcomePresenter` 接入 Bootstrap；结算页只消费 `/320` 成功包，通用 `RewardPresenter` 不再替代 World 结算。
- 继续通过结算页真实 `Panel` 控件触发 `/320 op=1` 重拉；回放通过真实 `Button_Replay` 重新发送 `/320 op=5`。统计来自 `/38` 播放期逐单位数据；`/320 op=8` 只负责结算奖励。复活仍因协议未定义而保持明确不可用边界，未写入本地假数据。
- 重置成功后立即 `/320 op=2` 重拉权威次数，未再假设最大次数。扫荡可见性遵循当前 Cocos `stars > 0`，而不是自行提高到三星。
- Unity 编译预检通过；固定账号 `-DataPreflightOnly` 通过4项前置，当前G3 batch通过真实入口、真实权威协议、真实EventSystem、战斗播放和结算/回放生命周期。恢复前后 SQLite SHA-256 均为 `7445FEEC27B2BED88164FFBD9CEF426B3559E58AFB6F51A357258AF51701E669`，重登稳定哈希通过，备份/WAL/SHM/隔离账号残留为0。
- 回合/阵法HUD及原始伤害字模接入后执行正式 `BootstrapSceneBuilder.BuildBatch`：返回码0、严重错误0；145个必需Cocos源文件未解析LFS指针为0。伤害字模构建证据 `.local/unity-validation/world-g3-buildbatch-battle-number.log`。
- 结算页已按当前 `FirstFightResultUI.lua` 与 `zhandoujiesuanLayer.csb` 收敛：货币为35px图标加纯数量；主角经验使用86px方形头像框、80px头像、460px经验底条；物品奖励为横排88px品质格、右下数量与下方名称；胜利徽章及星级恢复为高-低-高排列。最终截图 `build/ui-migration/world-battle-settlement.png` SHA-256=`6E38FAFE0A095AE71B6B890490996C233E25D655560567C9273CE4D80BE3C2A7`；正式BuildBatch证据 `.local/unity-validation/world-g3-buildbatch-settlement-final2.log`，返回码0、严重错误0、场景SHA不变；工具链268/268。
- G3 结论：World当前源码合同、SQLite数据合同、29项控件路由和共享战斗播放内核已达到可运行早测版本；当前产品战斗分母已收敛为`16/19`两类，World完成`16`，列传战斗模块完成`19`。其余50个枚举不进入当前分母，范围证据见`.local/unity-validation/battle-current-denominator-latest.json`。

## 历史 G4 固定账号动态验收（已由2026-09-01当前证据替代）

- 旧MySQL账号、旧29/29控件、5/5语义、6张截图和旧恢复哈希全部只作定位线索，不得计入当前门禁。
- 当前代理早期Play记录已生成且G4已通过；该记录保持`manualPassed=false`，只满足受委托早测前置，不替代G6用户最终确认。
- 当前G3-G4机器证据：`.local/unity-validation/world-g3-runtime-latest.json`、`.local/unity-validation/world-fixed-account-data-preflight-latest.json`、`.local/unity-validation/world-fixed-account-timings-latest.json`和`.local/unity-validation/world-fixed-account-latest.json`。

## 历史 G5 双端视觉验收（已由2026-09-01九态报告替代）

- 世界地图、关卡详情、扫荡、重置确认、战斗结算、宝箱状态共 `6/6` 当前双端原图、并排、叠加和差异报告通过人工验收；证据 `.local/ui-fidelity/World/compare/g5-20260731-cua/`。
- Cocos `FuBenDetailUI` 对 `MapPanel` 使用 `750/1080` 缩放；Unity 补齐同一语义后，详情和宝箱布局恢复到同一坐标体系。
- 按用户 2026-08-01 最终要求，扫荡页不按每次战斗分组，而展示“扫荡 N 次收益汇总”，以协议 `{type,id}` 合并所有次数的同类收益；标题和再次扫荡按钮均显示实际 `N`。
- 服务端当前可返回 `type=4603,id=0`，共享 `item_dat.lua/item.json` 缺少 `4601–4604`。World 展示层依据 `equip_dat.lua` 的 `1001–1004` 素心装备和紧邻的 `4605–4608` 青罗碎片连续编号，受控显示“碎片素心衣”及 `petequip_2103` 图标；共享掉落配置未修改。

## 历史 G6 收口（当前已失效）

- `WORLD_CONTROLS.json`：25/25 控件 `complete`，逐控件关联当前 Cocos/Unity `1334×750` 证据；占位、重复 UID、严重异常均为 0。
- `Test-UnityMigrationHardGates.ps1 -Module World -Phase G6` 通过；固定摘要与终态隔离身份分别校验，不再错误要求同一账号。
- `BootstrapSceneBuilder.BuildBatch` 连续执行两次，均报告语义签名未变化并跳过重建；两次 Bootstrap SHA-256 均为 `6A476349E892BF29E845CCA9F37D2292FB0853ADA1868415CAAF982FCD20660C`。
- 该历史 G6 曾登记到 `tools/unity-migration/migration-gates.json`，但已失效；World当前正式状态为G0-G3 passed、早测通过、G4-G6 pending。

## G0 前既有 Unity 实现（历史基线）

- `WorldStore.cs`：章节、关卡、星级宝箱、选中态、挑战状态和结算合并；奖励直接使用 `RewardRecord`。
- `WorldPresenter.cs`：运行时绑定三个只读导入 Prefab；`VirtualList` 渲染关卡，详情复用现有阵容与资源能力。
- `WorldController.lua.txt`：严格解析 `/320 op=1/2/5/8/27`，检查剩余字节并驱动刷新/验证状态机。
- `GameServices/ProjectXApp/ProtocolRegistry/BootstrapSceneBuilder/BootstrapAppRunner`：服务注入、入口、协议登记、场景装配和批处理验收。
- `RewardPresenter`：运行时修正导入 `ItemList` 的异常锚点；未修改导入 Prefab。

## Steam SQLite S5（passed，2026-08-20）

- 双端均从新隔离角色出发，生产路径覆盖`/320 op=1/2/4/5/6/7/8/27`：挑战`10001/10002`、普通箱`10000`领取及重复拒绝、六星箱`20011`、关卡`10001`剩余4次扫荡、首次50元宝重置。
- 运行态SQLite/MySQL分别收到133/135个响应，拥有`/320`均17包且长度一致；12个确定性查询/领取/拒绝/重置包逐包字节一致。两次战斗结算和扫荡使用生产随机奖励，按关卡、星级、宝箱、4轮且每轮`1`组货币+`2`组物品做语义等价，所有原始包保留。
- 重启后两端`/320`各4包全部字节一致：`10001`星级保留、挑战次数归零、剩余重置4；`10002`星级与挑战次数1保留。
- 数据库`guan_qia/save_data/mission`、角色金币/经验/等级、账号元宝/绑定元宝精确一致；体力均为70，仅`lastSpiritTime`因真实执行时刻不同而不同；背包仅随机扫荡掉落不同，确定性奖励更新包一致。
- 只删除隔离MySQL库`fxl_game_world_s5_v1`；正式`fxl_game_local`、MySQL源码/驱动/构建/Schema/脚本/回归继续保留，直到全部模块完成且用户明确通知删除。证据：`.local/unity-validation/steam-sqlite-s5-world-latest.json`。

## 历史验证（非本轮证据）

- 命令：`pwsh -File tools/unity-migration/Run-UnityModuleValidation.ps1 -Module World`。
- 最终隔离账号：`userId=7200008`；阶段账号不再复用。`7200004-7200007` 为启动失败、门禁修正或视觉修正过程账号，不作为最终证据。
- 闭环：入口 → 127 章/第 1001 章 6 关 → 第 10001 关详情 → 阵容/3 项预览奖励 → `op=5` → `op=8` 六项结算 → 重新请求 `op=1/2/27` → 星级 `3` 持久化。
- 服务端真实回包的 `alreadyFightTimes/fightCnt` 在首次本地战斗后仍为 `0`；不伪造该字段，以结算奖励和刷新后三星作为成功证据。
- 截图：`bootstrap-world.png`、`bootstrap-world-detail.png`、`bootstrap-world-result.png`、`bootstrap-world-final.png`，均为 `1334×750`。
- Unity BatchMode 编译/运行通过；严重日志匹配 `0`；UI 转换测试 `10/10`；迁移文档门禁通过。
- 数据边界：变更只落在一次性账号 `7200008`，不复用 Team/Guild 账号，不领取章节/星级宝箱，不执行扫荡或重置。

## 本轮已执行门禁

1. G0-G2 已复核服务端 `/320`、配置、Cocos 动态节点和 Unity Transform，并冻结固定账号、重连/切号合同。
2. G3 已按矩阵绑定真实 Prefab、Lua Controller 与 C# Render Bridge，排除入口保持隐藏。
3. 当前G3代理早期Play、G4固定账号验收与G5九态双端视觉均已通过；G6未执行，等待用户在当前变更后最终Play确认。

## 历史遗留

- 支线、帮派副本、封神试炼、排行榜、主线成就按独立模块从 G0 开始，不并入本次 World 结论。
- `/21-23` 服务端分发、资源和共享战斗场景已在当前G3-G5闭合；后续只在产品分母变化时按新类型从G0补专用夹具。
- 本地服务首次挑战计数字段仍可能为 `0`；若后续独立战斗模块依赖该字段，应先修复并补服务端语义证据。
