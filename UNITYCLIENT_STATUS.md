# UnityClient 当前状态

> 最后更新：2026-07-18
> 本文件是迁移进度、当前批次和下一步的唯一状态源。
> 历史全文见 `docs/unityclient/history/`；长期路线见 `UNITYCLIENT_MIGRATION_PLAN.md`。

## 1. 总进度

| 口径 | 当前值 | 说明 |
|---|---:|---|
| Static | `386 CSB 已审计` | 325 个同路径 CSD，61 个 CSB 兜底 IR；历史 356 Prefab 含跨目录同名混入，不再记作 100% |
| Functional | `约49%` | 当前活动、神将招募、玩法大厅、决战昆仑、血战、法宝搜索、七日目标及三类玩法商店只读首期已计入；旧 `/209`、旧 LuckyDraw 误版本均不计完成口径 |
| Validated | `0 个界面通过视觉 1:1 门禁` | 既有结果仅证明功能/协议与 Unity 单端可见；均缺 Cocos 同状态基准、节点映射和差异报告 |

禁止在其他文档维护第二份完成率；下表“第一阶段完成”仅指旧功能口径，全部可见界面统一视为视觉 1:1 待重验。

## 2. 模块状态

| 模块 | 状态 | 已完成边界 | 后续 |
|---|---|---|---|
| 运行时/网络/xLua | 第一阶段完成 | App 状态、协议分发、错误边界、重连、返回栈 | 回放、发布配置、完整错误码 |
| 登录/主界面 | 第一阶段完成 | 当前代码链已通过：Logo/Windows 预载、真实 LoginBg/login/SeverList/RoleCreate、`Btn_Play`、隔离创角 `/1001→/1003→/1004`、当前 UImainLayer、`/88 NoticeLayer` | 正式登录服、维护公告、发布配置后置 |
| UI 通用层 | 第一阶段完成 | VirtualList、MessageBox、Loading、Toast、Reward | 通用 Tab、分页、红点树深化 |
| 迁移提速工具 | 第一阶段完成 | Manifest、模块脚手架、协议取证、功能验收、数据夹具、Bootstrap 幂等；已新增 Cocos↔Unity 1:1 证据门禁 | 补自动截图与差异生成 |
| 资源/时间/旧动画 | 第一阶段完成 | ResourceService、ServerTime `/206`、29 处 CSB Timeline；Imod 67 个构造入口/208 个调用已审计，885 个真实资源全动作验证 | 补回 6 个固定调用缺整组资源和 `skill_5_h_l` 缺图；Atlas、内存预算、异步加载 |
| 设置 | 第一阶段完成 | 音乐/音效/音量持久化 | 兑换码、公告等独立模块 |
| 背包 | 第一阶段完成 | `/8、/15` 全量/增量/整理/使用/持久化 | 更多物品类型和批量操作 |
| 任务 | 第一阶段完成 | `/37、/39、/65` 列表/增量/追踪/红点/领奖 | 任务类型全覆盖 |
| 神将/阵容 | 第一阶段完成 | `/24、/48` 列表、详情、阵位变更/恢复 | 培养、技能、图鉴 |
| 装备/法宝 | 第一阶段完成 | `/319` 列表、增量、穿脱、装备强化 | 精炼/觉醒/神铸/法宝培养/回收 |
| 邮件 | 第一阶段完成 | `/128` 列表、已读、附件、单封领取 | 红点、一键领取、删除、空态 |
| 基础商城 | 第一阶段完成 | `/221` 列表、限购、倒计时、货币、确认、单次购买 | 手动刷新、错误/空态 |
| 将魂/竞技场/血战商店 | `logic-validated-visual-deferred` | `function_id=15/16/17`、`/221 type=2..8` 七页、74 条权威商品、页签/价格/限购/货币/刷新信息、入口与返回 | 购买/刷新写操作、Cocos 同状态基准与视觉细调 |
| 好友 | 第一阶段完成 | `/27` 列表、申请、添加、同意、拒绝、删除、增量重拉、空态 | 赠送/推荐/搜索/黑名单 |
| 聊天 | 第一阶段完成 | `/26` 世界发送、私聊真实回包、频道/错误态、确定性去重 | 历史、未读、语音、跨服、合规过滤 |
| 队伍 | 第一阶段完成 | `/29、/30` 状态、成员/宠物、创建、邀请/接受、离队、推送重拉 | 申请/踢人/移交队长/阵法/暂离 |
| 帮派 | 第一阶段完成 | `/54` 空态、列表、状态、成员、创建、退出/单人解散 | 申请批准/自动加入、邀请、职位、捐献、任务、红点深化 |
| 世界/战斗/副本 | 第一阶段完成 | `/320` 世界/章节/关卡/详情/阵容与奖励预览、隔离 PvE 结算和三星持久化 | 扫荡/重置/宝箱、支线、完整战斗表现 |
| 福利 | 第一阶段完成 | `/199、/222、/223` 签到、在线奖励、阶段目标边界/空态、单次签到领取 | 在线领取、七日登录、等级礼包、阶段目标服务端恢复 |
| 活动 | 第一阶段完成 | 当前入口 `ButtonGroup5/btn_huodong → WelfareActivityFormerUI`；`/222 op=0xFF` 列表、Tab/红点/倒计时、`op=18/1` 每日首充状态与奖励、真实未迁移 Tab 空边界通过 | 累计充值/消费、节日、排行、砸蛋、七日充值、神将折扣、领取与充值 SDK |
| 抽卡 | 第一阶段完成 | 当前 `btn_zhaomu → HappyDrawUI`；`/224` 三池、免费次数/倒计时/红点、真实免费单抽、权威奖励与结果 Timeline | 十连正向、奖励预览、重复神将转换、券不足联动 |
| 玩法大厅及首批子页 | `logic-validated-visual-deferred` | 大厅真实布局、游历、封神列传、竞技场、决战昆仑 `/213`、血战 `/323`、法宝搜索 `/319`、七日目标 `/37`、三类玩法商店 `/221` 均已跑通 | 好友赠送与组队统一后置；下一未完成模块为体力领取 |
| 充值/VIP/渠道 | 后置 | 未开始 | 单独处理支付、SDK和合规 |
| 发布/热更/性能 | 后置 | 未开始 | Windows、Android、资源和发布门禁 |

## 3. 最新验证基线
- 将魂/竞技场/血战商店首期（2026-07-18）：`function_id=15/16/17 → JiangHunShop/WanFaShopMainUI → /221 type=2..8` 七页全部返回，共 74 条权威商品；真实 Prefab、商品图标、页签、价格/限购/货币、入口/返回、三张 `1334×750` 截图、16/16 测试、严重异常 0 均通过。购买与刷新首期禁用。
- 七日目标首期（2026-07-18）：`function_id=11 → OperationalActivity.SevenDay → QiriLayer → /37 op=4` 返回 130 条权威任务；真实左右布局、七天/分类页签、进度区、任务列表、关闭/Esc 返回、16/16 测试、严重异常 0 均通过，截图 `bootstrap-seven-day.png`。领取、前往和折扣购买首期禁用。
- 玩法子页快速移植（2026-07-18）：游历 `/335 op=1`、封神列传 `/320 op=24`、竞技场 `/161 op=0` 均已改为真实 Prefab 主布局并通过模块门禁；动态模型容器与字体/装饰细节按用户要求延后人工调整。
- 玩法大厅公共层（2026-07-18）：真实 `ui_shenjiang_tips.png` 底部公告与扇子装饰已接入；最终 `userId=7200047`、16/16 测试、严重异常 0，Bootstrap SHA-256 两次一致为 `8A160A8F17CAA1B2A45AD623F941C81E9EB2A39DE119262F540AB9F30A9F0519`。
- 玩法大厅视觉修复基线（2026-07-18）：`btn_wanfa → shop/shop_bg + WanFaEntranceUI/common/ActivityLayer → WanFaInfoUI/TaskPopupLayer`；最终 `userId=7200039`，13 项与 `/65` 三类隐藏态通过。Cocos/Unity 列表与详情均为 `1334×750`，流程、节点映射、四份差异报告位于 `.local/ui-fidelity/Gameplay/`。列表全屏差异率 `12.08%`、详情 `10.70%`，因公共装饰/公告层与字体采样差异仍未通过，状态保持 `visual-fixing`。
- Bootstrap 七日目标接线幂等（2026-07-18）：连续两次 SHA-256 `E546A076DA6A3D391F0A73ABA327D1623A0737DCF3967F55F3882F9474C112A0`，语义签名一致；脚本只阻止同一 Unity 项目，不误伤用户同时打开的其他项目。
- 神将招募第一阶段（2026-07-18）：当前链为 `UImainLayer_new/ButtonGroup3/btn_zhaomu → EMID_KAPAI_CHOUKA → HappyDrawUI → csd/chouka/shenjiangzhaomu → /224`；最终 `userId=7200024`、`roleId=1000038`，op=1 返回 3 池，op=2 完成一次免费基础单抽并显示 `陈奇神魂×1`，截图 `1334×750`，严重异常 0。旧 `EMID_CHOUKA/LuckyDrawUI` 与未注册的另一套 `CPetDrawCfgMgr` 不计当前版本。
- Bootstrap 招募接线幂等（2026-07-18）：清理场景 YAML 尾空格后连续两次 SHA-256 `D15CC67DFF4E594AEFB05F9EBD15F91619C7EE601E7CFA9042B0D20C890E499C`，第二次输出 `semantic signature unchanged`。
- 活动第一阶段（2026-07-18）：当前真实链为 `UImainLayer_new/ButtonGroup5/btn_huodong → WelfareActivityFormerUI → csd/huodong/ActivityRankingLayer + ActivityLevelLayer → /222 op=0xFF`；首个子页为 `tag=1 DailyRechargeUI → csd/DailyChargeLayer → /222 op=18/subOp=1`。最终 `userId=7200020`、`roleId=1000034`，列表 2 条、奖励 1 条，三张 `1334×750` 截图，严重异常 0，夹具与备份表残留 0。
- Bootstrap 活动接线幂等（2026-07-18）：清理 YAML 尾空格后连续两次 SHA-256 `C0F24A7AC9BA351AD65E0D51D29E7A4AF15E528D9D9B12336077873607D550E5`，两次均输出 `semantic signature unchanged`。
- 资源专项（2026-07-18）：运行包 386 个 CSB，完整路径匹配 325、CSB 兜底 61、同名冲突 38 组；福利 scope 27 条源码引用中 26 个运行资源存在。
- `.ani` 专项（2026-07-18）：活动 Lua 共 67 个构造入口、208 个调用、38 个动态加载表达式；886/886 ANI 可解析。Unity 逐项通过 885 个可播放资源、1327 个动作、10264 个动作序列帧，PNG/ANI 分离、附加层、翻转、颜色、透明度、旧速度倍率均通过；固定 UI 24 路径中 18 个真实播放、6 个源包缺整组资源，另有 `Skill/skill_5_h_l.ani` 缺 PNG。视觉联系表 `.local/validation/imod-static-ui-contact-sheet.png`。
- CSB Timeline 专项（2026-07-18）：29 处有效调用展开为 27 个唯一资源/Prefab；22 个有真实轨道、5 个源文件本身为空时间轴。累计导入 461 条轨道、2478 帧、34 个命名片段；唯一 CSB-only `FengShenLayer.csb` 已逐帧解码。Unity 实例化播放 27/27、命名片段 34/34、非空 FrameEvent 3/3，视觉抽样见 `.local/validation/timeline-*.png`。
- 真实资源：`LoginBgLayer.csb、loginLayer.csb、SeverListLayer.csb、RoleCreateLayer.csb`；登录背景 `res2/animation/effect_chuangjue_1` 动作 0 循环。
- Unity 门禁：依次断言 Logo 0.5 秒、Windows 六组资源预载态、本地服按钮与登录动画、`RoleCreateLayer` 男女动作、当前 `UImainLayer`，最后发送 `/88` 并渲染真实 `NoticeLayer` 标题/正文。
- 最终隔离账号：`userId=7300109`、`roleId=1000046`；公告验证数据由脚本临时写入并在退出路径精确清理。
- 结果：`build/ui-migration/bootstrap-app-result.json`，`success=true`；`bootstrap-login.png`、`bootstrap-login-notice.png` 均为 `1334×750`；严重异常 `0`。
- 活动旧版 `/209 + ActivityLayer` 结果已判为错误版本证据，不再计入完成率，也不得提交。

## 4. 当前批次
迁移提速工具已完成，入口为 `tools/unity-migration/README.md`。

本批按用户最新要求改为“可运行优先”：主布局和位置基本一致、真实 Prefab/资源、入口、返回、只读协议和模块门禁通过即可推进；字体、动态模型、动画和像素级装饰不阻塞下一模块，也不记作视觉 1:1 完成。

固定顺序：

1. 记录 Cocos 当前 Lua/Controller/View、完整 CSB、动态节点、协议和服务端分支。
2. 固定 `1334×750`，按同账号/数据/步骤捕获 Cocos 各状态基准并记录 SHA-256。
3. 建立 Cocos 节点 ↔ Unity Transform、资源、字体、动画、交互逐项映射。
4. 修复 Unity 后用同数据/步骤/稳定帧截图，生成叠加图与差异报告；未解释差异必须继续修。
5. 功能 Runner、Bootstrap 幂等、Python UI、文档和严重异常门禁全部通过后，才可标记 `visual-1to1-complete`。
6. 大厅、游历、封神列传、竞技场已完成真实主布局快速移植；细节 UI 和动态模型统一延后。
7. 决战昆仑、血战、法宝搜索、七日目标及将魂/竞技场/血战商店已完成只读首期并通过门禁；好友赠送、好友深化、组队深化统一放到末尾，下一项为体力领取。

暂不并行：商城第二阶段、邮件第二阶段、装备深度培养。

## 5. 已知风险

- `UNITYCLIENT_MIGRATION_PLAN.md` 不再保存实时百分比，避免状态漂移。
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
- 默认读取顺序：`AGENTS.md → 本文件 → UNITYCLIENT_HANDOFF.md → 目标模块文档 → 计划对应章节`。
