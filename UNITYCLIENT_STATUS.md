# UnityClient 当前状态

> 最后更新：2026-07-27
> 本文件是迁移进度、当前批次和下一步的唯一状态源。
> 历史全文见 `docs/unityclient/history/`；唯一流程与标准见 `docs/unityclient/MIGRATION_GUIDE.md`。

## 1. 总进度

| 口径 | 当前值 | 说明 |
|---|---:|---|
| Static | `386 CSB 已审计` | 325 个同路径 CSD，61 个 CSB 兜底 IR；历史 356 Prefab 含跨目录同名混入，不再记作 100% |
| Functional | `待逐控件重审` | 旧“约56%”只统计页面/协议主链，未统计 Cocos 可达控件和真实点击覆盖，现已作废 |
| Validated | `3/29 = 10.3%` | 背包、神将/阵容、装备/法宝已按新标准完成 G0-G6、真实控件和双端视觉验收；这是当前唯一可审计的严格移植完成率 |

禁止在其他文档维护第二份完成率。历史“第一阶段完成”统一解释为 `legacy-unverified`，不代表功能完成；新标准见 `docs/unityclient/MIGRATION_GUIDE.md`。

## 2. 模块状态

| 模块 | 状态 | 已完成边界 | 后续 |
|---|---|---|---|
| 运行时/网络/xLua | 第一阶段完成 | App 状态、协议分发、错误边界、重连、返回栈 | 回放、发布配置、完整错误码 |
| 登录/主界面 | 第一阶段完成 | 当前代码链已通过：Logo/Windows 预载、真实 LoginBg/login/SeverList/RoleCreate、`Btn_Play`、隔离创角 `/1001→/1003→/1004`、当前 UImainLayer、`/88 NoticeLayer` | 正式登录服、维护公告、发布配置后置 |
| UI 通用层 | 第一阶段完成 | VirtualList、MessageBox、Loading、Toast、Reward | 通用 Tab、分页、红点树深化 |
| 迁移提速工具 | 第一阶段完成 | Manifest、模块脚手架、协议取证、功能验收、数据夹具、Bootstrap 幂等；已新增 Cocos↔Unity 1:1 证据门禁 | 补自动截图与差异生成 |
| 资源/时间/旧动画 | 第一阶段完成 | ResourceService、ServerTime `/206`、29 处 CSB Timeline；Imod 67 个构造入口/208 个调用已审计，885 个真实资源全动作验证 | 补回 6 个固定调用缺整组资源和 `skill_5_h_l` 缺图；Atlas、内存预算、异步加载 |
| 设置 | 第一阶段完成 | 音乐/音效/音量持久化 | 兑换码、公告等独立模块 |
| 背包 | `G0-G6 passed / 26/26 complete` | 固定隔离账号完成 Cocos/Unity 26/26 原生图、并排/叠加/差异、真实控件、`/8`/`/15`、使用/整理/增删改、重连/持久化/切号及 Bootstrap 幂等 | 当前模块收口；下一任务重新选择一个模块执行 G0 |
| 任务 | 第一阶段完成 | `/37、/39、/65` 列表/增量/追踪/红点/领奖 | 任务类型全覆盖 |
| 神将/阵容 | `G0-G6 passed / 16/16 complete` | 固定账号7200057全解锁；Cocos/Unity各16/16原图、并排/叠加/差异、真实Button自动链和人工视觉均16/16通过；14项硬缺陷已修复 | 当前模块收口；生成HANDOFF后另开任务再选下一模块 |
| 装备/法宝 | `G0-G6 passed / 33/33 complete` | 固定账号完成 20/20 双端视觉、33/33 真实控件、穿脱/强化/失败态/重连/持久化/切号及 Bootstrap 幂等 | 当前模块收口；新任务再选下一模块 |
| 邮件 | 第一阶段完成 | `/128` 列表、已读、附件、单封领取 | 红点、一键领取、删除、空态 |
| 基础商城 | 第一阶段完成 | `/221` 列表、限购、倒计时、货币、确认、单次购买 | 手动刷新、错误/空态 |
| 将魂/竞技场/血战商店 | `logic-validated-visual-deferred` | `function_id=15/16/17`、`/221 type=2..8` 七页、74 条权威商品、页签/价格/限购/货币/刷新信息、入口与返回 | 购买/刷新写操作、Cocos 同状态基准与视觉细调 |
| 好友 | 第一阶段完成 | `/27` 列表、申请、添加、同意、拒绝、删除、增量重拉、空态 | 赠送/推荐/搜索/黑名单 |
| 聊天 | 第一阶段完成 | `/26` 世界发送、私聊真实回包、频道/错误态、确定性去重 | 历史、未读、语音、跨服、合规过滤 |
| 队伍 | 第一阶段完成 | `/29、/30` 状态、成员/宠物、创建、邀请/接受、离队、推送重拉 | 申请/踢人/移交队长/阵法/暂离 |
| 帮派 | 第一阶段完成 | `/54` 空态、列表、状态、成员、创建、退出/单人解散 | 申请批准/自动加入、邀请、职位、捐献、任务、红点深化 |
| 世界/战斗/副本 | 第一阶段完成 | `/320` 世界/章节/关卡/详情/阵容与奖励预览、隔离 PvE 结算和三星持久化 | 扫荡/重置/宝箱、支线、完整战斗表现 |
| 福利 | 第一阶段完成 | `/199、/222、/223` 签到、在线奖励、阶段目标边界/空态、单次签到领取；`/321 op=2` 体力领取三档权威状态 | 在线领取、体力实际领取、七日登录、等级礼包、阶段目标服务端恢复 |
| 活动 | 第一阶段完成 | 当前入口 `ButtonGroup5/btn_huodong → WelfareActivityFormerUI`；`/222 op=0xFF` 列表、Tab/红点/倒计时、`op=18/1` 每日首充状态与奖励、真实未迁移 Tab 空边界通过 | 累计充值/消费、节日、排行、砸蛋、七日充值、神将折扣、领取与充值 SDK |
| 抽卡 | 第一阶段完成 | 当前 `btn_zhaomu → HappyDrawUI`；`/224` 三池、免费次数/倒计时/红点、真实免费单抽、权威奖励与结果 Timeline | 十连正向、奖励预览、重复神将转换、券不足联动 |
| 玩法大厅及首批子页 | `logic-validated-visual-deferred` | 大厅真实布局、游历、封神列传、竞技场、决战昆仑 `/213`、血战 `/323`、法宝搜索 `/319`、七日目标 `/37`、三类玩法商店 `/221`、体力领取 `/321`、资源找回 `/52`、成长/活跃基金 `/222` 均已跑通 | 好友赠送与组队统一后置；继续下一个非社交模块 |
| 充值/VIP/渠道 | 后置 | 未开始 | 单独处理支付、SDK和合规 |
| 发布/热更/性能 | 后置 | 未开始 | Windows、Android、资源和发布门禁 |

## 3. 最新验证基线
- 背包 G0-G6 收口（2026-07-27）：固定隔离账号 `7200057 / roleId=1000115`、Windows 100%、双端原生 `1334×750`。矩阵 `26/26 complete`；Cocos/Unity 原图、并排、50% 叠加、增强差异、真实控件自动化和人工视觉均 `26/26 passed`。真实 `/8`、`/15` 覆盖全量、增量新增/更新/删除、整理、批量/礼包/直接使用、无效/重复拒绝、重拉、断线重连、持久化和切号清理；严重异常 0，Python UI `16/16`。正式 `BootstrapSceneBuilder.BuildBatch` 两次 SHA-256 均为 `B27460DB36051DA396630CFF66EDED1115F3C3CB8148388F9574AA60A92D19AE`。测试数据只来自可逆本地隔离夹具，不是正式服/生产数据；来源目标模块未迁移时保持 Bag 并记录不可用目标，不再打开无数据神将空壳。证据 `.local/ui-fidelity/Bag/compare/g5-live-20260727/manual-acceptance.json`、`.local/unity-validation/bag-latest.json`。
- 装备/法宝 G0-G6收口（2026-07-27）：固定账号 `7200057 / roleId=1000115`、原生 `1334×750`；Cocos/Unity 原图、并排/叠加/差异和人工视觉均 `20/20 passed`，控件矩阵 `33/33`。Unity MCP 真实 Button 覆盖主入口、六槽、背包/碎片、帮助、详情/更换、筛选、强化和关闭；G4穿脱、失败态、断服重连、持久化与切号清理继续有效。强化页补齐真实主角头像，单次强化 UID `2121072641` 本轮 `8→10→12`；缺图0、严重异常0、Console最终0 error/0 warning。正式 `BuildBatch` 经 Unity MCP 连续两次 SHA-256 均为 `188BFD6307DFB0B0F195596D94E95ACE2E103343B8C28057F8AD5A13F580CACB`。证据 `.local/ui-fidelity/HeroEquip/compare/g5-live-20260726/manual-acceptance.json`、`.local/unity-validation/hero-equip-g6-control-runner.json`。
- 神将/阵容 G0-G6收口（2026-07-26）：固定账号 `7200057 / roleId=1000115`、同数据、原生 `1334×750` 的 Cocos/Unity 原图、并排/叠加/差异、真实 Button 自动化和人工视觉均 `16/16 passed`。修复范围包括主界面公共层与圆形头像、阵容装备/法宝真实图标、候选页残留、养成页内容与经验条、强化大师、四装备/两法宝独立详情和完整属性弹窗。最终 Runner `build/ui-migration/bootstrap-app-result.json` 于 `2026-07-26T14:31:28.6502368Z` 成功，严重异常0；纳入 `ChatLayer` 后正式 Bootstrap 双批处理幂等 SHA-256 为 `408E3FF9E994AA681B9805AF28F598F2023126E44B00EF55D0BFCACB0C49FEDC`；G5、G6门禁已通过。证据 `.local/ui-fidelity/Hero/compare/g5-live-20260726/manual-acceptance.md`。
- 神将/阵容 G6机器回归（2026-07-26，门禁仍pending）：用户明确授权在 G5 pending 时先执行机器回归。固定账号 `7200057` 由 Unity MCP 菜单触发真实入口 Runner，16项真实 Button 链和阵位 `1→2→1` 权威恢复通过；本次结果 `build/ui-migration/bootstrap-app-result.json`，截图 `bootstrap-hero.png` 为 `1334×750`，严重异常 `0`，Python UI `16/16`，文档 `29` 模块一致，Git范围 `unexpected=0`。修复 `BootstrapSceneBuilder` 中阵容子 Prefab 深度遍历顺序误判后，双次幂等 SHA-256 均为 `ECD2CBBF048917252DDC852CEEC7F7F87A184832C7AD1CEB9DACCFE3F6980559`。因 G5双端视觉证据缺失且矩阵 `manualPassed=0/16`，机器门禁仍为 G0-G4 passed、G5-G6 pending。
- 神将/阵容 G4通过、G5待后台补证（2026-07-26）：同账号 `7200057` 的16项真实 Button 主链、等级1锁定阵位、服务端非法 hero `65535` 拒绝及阵位 `1→2→1` 权威恢复均通过。随后真实停止 `kapai`、观察断线、重启服务、手动触发重连、重新登录并从真实阵容入口恢复 `/24 op=1 → /48 op=1` 快照，第二轮16控件链再次通过；证据 `.local/unity-validation/hero-g4-reconnect-user7200057.json`。Unity 16/16 `1334×750` 原图已生成。现有 Cocos G1 组内数据不一致，旧差异报告无效；按用户确认模式只允许后台 Cocos 自动化，当前客户端无可用顶层窗口，故机器门禁为 G0-G4 passed、G5-G6 pending。
- 神将/阵容 G3（2026-07-26）：6个真实 Prefab 已进入 Bootstrap 场景，16/16项真实控件完成静态绑定；修复空阵位选择被 `Render()` 重置的问题。Unity 2022.3.62f3c1 编译、场景重建、Console 0 error、文档门禁通过；机器门禁 G0-G3 passed。因G4-G6尚未执行，迁移完成仍为 `0/16`。
- 装备/法宝 G3（2026-07-26）：收口自动详情、隐藏已穿戴、回收、养成入口、法宝碎片、公共帮助、更换筛选、强化装备选择、空槽候选及排除培养区。Unity MCP 强制刷新编译、重建 Bootstrap，六个 HeroEquip View 节点数 `41/99/40/49/34/36`；PlayMode 六引用、Presenter 初始化和装备/法宝/碎片打开通过，Console 0 error / 0 warning。机器门禁 G0-G3 passed。
- 装备/法宝 G4（2026-07-26）：固定账号 `7200057/1000115` 经 Unity MCP 触发真实 Button，装备强化 `3→5`、穿脱恢复、法宝穿脱恢复、金币不足、非法 UID、重复卸下、断服重启重连、正常断开持久化及切号清理全部通过。修复普通强化误入自动化卸下链、法宝失败包错读 `replacedUid` 两个根因；重启权威回读装备阵位 1/强化 5、法宝阵位 1，缺图 0。
- 神将/阵容 G0-G2（2026-07-26）：隔离账号 `7200057` 取得原生客户区 `1334×750` 的16/16当前 Cocos真实点击证据；等级1夹具 `7200260` 补齐2/5/11/15级锁定阵位及拒绝提示。协议 `/24 op=1`、`/48 op=1/4`、6个Prefab、3份配置、Lua权威/C#渲染镜像边界、断线重拉和切号清理已冻结，机器门禁 G0-G2 passed。
- 完成口径纠正（2026-07-19）：用户人工检查确认 Unity 阵容页面大量 Cocos 原有操作按钮无效果。代码复核显示 Cocos `PetZhenRongUI` 已绑定养成、强化大师、替换、空位上阵、`EquipIcon1..6`、详细属性、布阵等回调，而 Unity `HeroPresenter` 仅绑定阵位卡/背包卡选择；旧 Runner 还存在直接调用内部弹窗绕过真实按钮的问题。旧 Functional `约56%`、阵容 `visual-1to1-complete` 及对应 G0-G6 结论全部撤销，Validated 归零。
- 装备/法宝 G0-G2（2026-07-19）：冻结 `userId=7200057`、`roleId=1000078/U00057`、Windows `100%`、原生 `1334×750`；确认真实链为神将详情 `EquipIcon1..6`、独立装备/法宝背包入口、共享更换/详情 CSB 与 `/319`。隔离角色持久化装备 5、法宝 3、碎片 `4701..4706` 各 10；18 张有效 Cocos 图覆盖全部冻结页面、弹窗、成功/失败及重连状态；`op2/3/4/16/18/19`、非法/重复与卸下恢复回读完成。失败态临时夹具已用 binlog 操作前镜像回滚，源码/EXE/角色状态恢复并独立重连通过。状态升级为 `g2-complete`，允许进入 G3。
- 阵容历史试点（2026-07-19，完成结论已撤销）：曾完成五组截图和 `/24、/48` 自动化换位，但未覆盖全部 Cocos 可达控件且部分流程绕过真实按钮；仅保留为数据、视觉和协议历史证据，不再作为完成证明。
- 阵容 Lua 权威状态试点（2026-07-18）：真实入口 `ButtonGroup1/btn_zhenrong → EMID_KAPAI_SHENJIANG → KaPaiPet.PetZhenRongUI`；Unity 改为 `HeroController → LegacyFormationModel → /24、/48 → C# render mirror`。隔离 `userId=7200057`，神将 57 阵位 `1→2→1`、服务端快照、Imod 动作 1、16/16 Python UI、编译及严重异常扫描通过。仅算逻辑通过：当前 Unity 图仍有武器/法宝/技能占位文字、错误图文、顶部公共层遮挡等问题，且缺有效 Cocos 同状态截图与差异报告，状态保持 `logic-validated-visual-pending`。
- 全部基金首期（2026-07-18）：`function_id=25/26 → WelfareActivityUI → ChengZhangLayer/HuoyueLayer → /222 op=83/94`，成长/活跃各返回 2 档权威计划；共用真实 `huodong_bg`、四页签和货币栏，双回包、入口/返回及 `1334×750` 截图通过。购买/领取禁用；本地最小库仅在 `local_test=1` 且活动配置为空时返回只读样例。
- 资源找回首期（2026-07-18）：`function_id=19 → WelfareActivityUI/FindOfflineExp → huodong_bg + ziyuanzhaohui → /52 op=1` 返回 7 条权威记录；真实公共背景/双页签/货币栏、可滚动列表、成本/次数、入口/返回、`1334×750` 截图、16/16 测试、严重异常 0 均通过。`op=2` 找回首期禁用。
- 体力领取背景修复（2026-07-18）：确认 Cocos 为 `huodong_bg` 父层 + `tililingquLayer` 子层；Unity 已恢复背景框、双页签和顶部货币栏并重新通过 `/321 op=2` 门禁。
- 体力领取首期（2026-07-18）：`function_id=18 → WelfareActivityUI/ReceiveTiliUI → huodong/tililingquLayer → /321 op=2` 返回三档权威状态；真实人物/餐桌/时段布局、入口/返回、`1334×750` 截图、16/16 测试、严重异常 0 均通过。`op=3` 领取首期禁用。
- 将魂/竞技场/血战商店首期（2026-07-18）：`function_id=15/16/17 → JiangHunShop/WanFaShopMainUI → /221 type=2..8` 七页全部返回，共 74 条权威商品；真实 Prefab、商品图标、页签、价格/限购/货币、入口/返回、三张 `1334×750` 截图、16/16 测试、严重异常 0 均通过。购买与刷新首期禁用。
- 七日目标首期（2026-07-18）：`function_id=11 → OperationalActivity.SevenDay → QiriLayer → /37 op=4` 返回 130 条权威任务；真实左右布局、七天/分类页签、进度区、任务列表、关闭/Esc 返回、16/16 测试、严重异常 0 均通过，截图 `bootstrap-seven-day.png`。领取、前往和折扣购买首期禁用。
- 玩法子页快速移植（2026-07-18）：游历 `/335 op=1`、封神列传 `/320 op=24`、竞技场 `/161 op=0` 均已改为真实 Prefab 主布局并通过模块门禁；动态模型容器与字体/装饰细节按用户要求延后人工调整。
- 玩法大厅公共层（2026-07-18）：真实 `ui_shenjiang_tips.png` 底部公告与扇子装饰已接入；最终 `userId=7200047`、16/16 测试、严重异常 0，Bootstrap SHA-256 两次一致为 `8A160A8F17CAA1B2A45AD623F941C81E9EB2A39DE119262F540AB9F30A9F0519`。
- 玩法大厅视觉修复基线（2026-07-18）：`btn_wanfa → shop/shop_bg + WanFaEntranceUI/common/ActivityLayer → WanFaInfoUI/TaskPopupLayer`；最终 `userId=7200039`，13 项与 `/65` 三类隐藏态通过。Cocos/Unity 列表与详情均为 `1334×750`，流程、节点映射、四份差异报告位于 `.local/ui-fidelity/Gameplay/`。列表全屏差异率 `12.08%`、详情 `10.70%`，因公共装饰/公告层与字体采样差异仍未通过，状态保持 `visual-fixing`。
- Bootstrap 七日目标接线幂等（2026-07-18）：连续两次 SHA-256 `E546A076DA6A3D391F0A73ABA327D1623A0737DCF3967F55F3882F9474C112A0`，语义签名一致；脚本只阻止同一 Unity 项目，不误伤用户同时打开的其他项目。
- 神将招募第一阶段（2026-07-18）：当前链为 `UImainLayer_new/ButtonGroup3/btn_zhaomu → EMID_KAPAI_CHOUKA → HappyDrawUI → csd/chouka/shenjiangzhaomu → /224`；最终 `userId=7200024`、`roleId=1000038`，op=1 返回 3 池，op=2 完成一次免费基础单抽并显示 `陈奇神魂×1`，截图 `1334×750`，严重异常 0。旧 `EMID_CHOUKA/LuckyDrawUI` 与未注册的另一套 `CPetDrawCfgMgr` 不计当前版本。
- 活动第一阶段（2026-07-18）：当前真实链为 `UImainLayer_new/ButtonGroup5/btn_huodong → WelfareActivityFormerUI → csd/huodong/ActivityRankingLayer + ActivityLevelLayer → /222 op=0xFF`；首个子页为 `tag=1 DailyRechargeUI → csd/DailyChargeLayer → /222 op=18/subOp=1`。最终 `userId=7200020`、`roleId=1000034`，列表 2 条、奖励 1 条，三张 `1334×750` 截图，严重异常 0，夹具与备份表残留 0。
- `.ani` 专项（2026-07-18）：活动 Lua 共 67 个构造入口、208 个调用、38 个动态加载表达式；886/886 ANI 可解析。Unity 逐项通过 885 个可播放资源、1327 个动作、10264 个动作序列帧，PNG/ANI 分离、附加层、翻转、颜色、透明度、旧速度倍率均通过；固定 UI 24 路径中 18 个真实播放、6 个源包缺整组资源，另有 `Skill/skill_5_h_l.ani` 缺 PNG。视觉联系表 `.local/validation/imod-static-ui-contact-sheet.png`。
- CSB Timeline 专项（2026-07-18）：29 处有效调用展开为 27 个唯一资源/Prefab；22 个有真实轨道、5 个源文件本身为空时间轴。累计导入 461 条轨道、2478 帧、34 个命名片段；唯一 CSB-only `FengShenLayer.csb` 已逐帧解码。Unity 实例化播放 27/27、命名片段 34/34、非空 FrameEvent 3/3，视觉抽样见 `.local/validation/timeline-*.png`。
- 真实资源：`LoginBgLayer.csb、loginLayer.csb、SeverListLayer.csb、RoleCreateLayer.csb`；登录背景 `res2/animation/effect_chuangjue_1` 动作 0 循环。
- Unity 门禁：依次断言 Logo 0.5 秒、Windows 六组资源预载态、本地服按钮与登录动画、`RoleCreateLayer` 男女动作、当前 `UImainLayer`，最后发送 `/88` 并渲染真实 `NoticeLayer` 标题/正文。
- 最终隔离账号：`userId=7300109`、`roleId=1000046`；公告验证数据由脚本临时写入并在退出路径精确清理。
- 结果：`build/ui-migration/bootstrap-app-result.json`，`success=true`；`bootstrap-login.png`、`bootstrap-login-notice.png` 均为 `1334×750`；严重异常 `0`。
- 活动旧版 `/209 + ActivityLayer` 结果已判为错误版本证据，不再计入完成率，也不得提交。

## 4. 当前批次
背包 Bag 当前只推进到 G1：G0 26/26 控件闭包、G1 当前 Cocos `1334×750` 基准已通过，G2-G6 pending。本任务不进入 G2；下一步只冻结 `/8`、`/15` 字段、全量/增量/删除/整理/使用规则及 26 控件生命周期设计。固定账号 `7200057 / roleId=1000115` 的原始包备份为 `.local/ui-fidelity/Bag/cocos/g1-20260727/fixture-baseline.json`，27 项同域夹具暂保留供 G2-G5 同数据验证，模块结束后精确恢复；G1 未执行有效 `/15` 消耗。

## 5. 已知风险

- 路线、流程、功能/视觉标准已合并到 `docs/unityclient/MIGRATION_GUIDE.md`，禁止新建平行文档。
- 配置含义不一定等于服务端真实扣款/奖励语义，必须以真实结果为准。
- Unity GUI 可异步返回；自动化必须用 `Start-Process -Wait`，同一隔离角色禁止并发。
- Runner 必须删除旧结果并校验本次时间戳，不能继承旧 `COMPLETE`。
- 手工 Prefab 默认只读，优先运行时绑定，不使用重建脚本覆盖设计结构。
- 当前工作区存在用户自己的 xlua `.meta` 删除和 `unityclient/.vscode/`，处理 Unity 任务时继续保留。
- 历史 Prefab 清单由 333 CSD + 23 basename 兜底生成，存在 38 组跨目录同名风险；不得按 Prefab 名称判断所属游戏。
- 仓库同时保留多代代码/UI；模块归属必须由当前启动入口的实际调用链确认，禁止用文件名、目录名或截图反推版本。
- Imod 固定调用有 6 条在桌面运行包缺整组 ANI/PNG，另有 1 个 ANI 缺可解码贴图；取得当前游戏原始美术前不能声称 100% 资源播放闭环。
## 6. 状态维护规则

- 每批只更新：总进度、模块状态、最新验证、当前批次。
- 协议和实现证据写入 `docs/unityclient/modules/`。
- 日期流水写入 `docs/unityclient/history/YYYY-MM.md` 或完整快照，不写回本文件。
- 默认读取顺序：`AGENTS.md → 本文件 → MIGRATION_GUIDE.md → modules/README.md → 目标模块文档/矩阵`。
