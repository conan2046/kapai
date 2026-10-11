# Unity 新版境界开发进度

目标：交付可从创角、挂机、离线收益、小阶升级到大境界渡劫正常体验的 Unity 境界系统。
工程：`E:\neiwang_kapai\Game`；Unity：`unityclient`。开始日期：2026-10-11。

## 范围与保护

- 仅修改 Unity 客户端、`unitydata`、`unityserver` 和 Unity 专用构建入口。
- `server/`、`client/ProjectX/src/`、`concept/data/excel/` 不修改；基线哈希：`.local/jingjie-rework/cocos-protected-baseline.json`。
- 保留用户手调 `JingjieLayer.prefab`；初始哈希：`.local/jingjie-rework/manual-prefab-baseline.sha256`。代码不覆盖角色挂点 Transform。
- 不提交、不推送；最终技术通过与用户画面验收分别记录。

## 开发清单

| 项 | 内容 | 状态 | 证据／说明 |
|---|---|---|---|
| 01 | Unity 独立服务端源码及编辑器／Steam构建入口 | 完成 | 独立kapai.exe构建成功；52个编译输入均属Unity；SQLite读写、Schema重复建库（182表/37索引）、方言检查通过；Unity刷新编译完成、Console错误0；1365个Cocos文件及手调Prefab哈希未变。日志`.local/jingjie-rework/unityserver-build.log`、`isolation-result.json`、`independent-smoke.log` |
| 02 | 正式550阶配置与完整客户端／服务端导出 | 完成 | 正式表550阶/7运行参数；8800字段与客户端源/运行、服务端中间/运行四份输出逐项一致；64位经验、54渡劫边界、属性递增、重复导出不重写通过。`config-result.json`、`jingjie-export.log`；旧表备份`.local/jingjie-rework/jingjie_config.before.xlsx` |
| 03 | 特效依赖导入及独立渡劫Prefab | 完成（资源与结构） | 69源资源/Meta保留GUID导入；29材质Shader错误0；原生Catalog与轻量引用登记；角色仅空SpineAnchor。`Assets/Prefabs/OneLevel/DuJieLayer.prefab`、`effects-dependencies.json`、`effects-import.json`、`prefab-result.json`。动态渲染/演出与最终视觉验收在10/12项，未宣称已完成 |
| 04 | 存档版本、初始化、旧档迁移、失败次数及结算时间 | 完成（服务端） | `unity_jingjie_state`版本2；创角开始计时；旧角色保留旧等级/境界/经验影子值并映射新阶。旧境界20→550、超过2^53经验精确、重登保持通过。证据`backend-probe-04/result.json` |
| 05 | 境界快照／经验／离线／渡劫序列协议与客户端状态 | 完成 | /306 op128精确字符串经验；真实创角/旧存档入口验证XLua接收、升级请求与通知确认。8项状态检查和158项红点规则检查通过；`client-state-tests.txt`、`client-acceptance-01/` |
| 06 | 在线5秒、离线48小时100%结算 | 完成（服务端） | 在线定时器50ms扫描、5秒边界结算；49小时离线夹具仅计48小时、100%、自动到账；登录/退出时间及小数余量保存通过。弹窗与进度表现归09项 |
| 07 | 小阶手动升级及属性、品质、外观更新 | 完成 | 真实入口一阶→二阶、连续手动升至十阶；属性/品质/14对外观与每阶光晕绑定正式配置。最终界面为左侧单角色、右侧合并属性提升表；表头显示当前/下一境界名，固定布局与颜色由Prefab维护 |
| 08 | 概率、失败保底和服务端雷劫序列 | 完成（服务端） | 自然失败>100%、每雷20～30%、雷数3～5、惩罚精确；累计15失败后下一次保底成功≤100%并清零；重登同一序列、确认不重复发奖通过。HP显示与演出在10项 |
| 09 | expect进度、每秒收益Num、境界限定提示和离线弹窗 | 完成 | 5秒进度与到账提示，最终复用通用RuntimeToast Prefab和位置；底框高8+字号×实际行数，默认单行。49小时离线仅计48小时；告知关闭只隐藏弹窗 |
| 10 | 3秒乌云、逐雷、持续护罩及成败结算 | 完成（技术） | 私有相机/透明RT承载真实粒子资源；自然成功70%、自然失败127%、保底成功63%均真实演出；护罩从首次命中至结束，失败到0仍完成全部雷数。成功100%显示1的边界检查通过。演出结束私有相机/RT清理，断线重放不重复结算；角色布局由用户调整 |
| 11 | 等级替代、入口、主HUD、红点和旧等级联动检查 | 完成 | Unity入口配置第1阶开启；HUD、系统、存档、战斗身份、功能/章节解锁显示境界名称；神将独立等级保留。最高境界使用已手调的当前面板，避免旧Panel_End默认倍率遮挡；550阶预览仅复用8行，可真实滚轮到第550阶 |
| 12 | 编译、定向回归、真实入口Play及最终体验 | 完成（技术）；画面待用户确认 | E盘Bootstrap真实Raycast输入；自建隔离Slot01，无用户存档修改。创角/5秒收益/离线告知/小阶/成功/失败/保底/重登重放/最高阶精确经验通过；Console错误0。所有自启kapai已退出、8711/8714无监听、SQLite完整且无写锁；`manualPassed=false` |

## 已确认规则

- 55个大境界，每境界10阶；小境界替代玩家等级，名称对应UI。每阶独立品质、累计属性、外观配置。
- 当前行`need_exp`用于升下一阶，`exp`为当前阶每秒经验。从创角开始，在线每5秒结算；经验无限积累，必须点击升级。
- 离线按100%速率，最多48小时；登录自动到账，弹窗点击只关闭。
- 小阶仅经验条件；跨大境界才使用概率、雷劫、失败惩罚和保底。删除旧等级、战力门槛和材料／金币消耗。
- `upgrade_probability`单位万分比；`fail_upgrade`单位当前等级经验万分比。
- `Threshold`是累计失败阈值，达到后下一次必成；不是第N次尝试必成。
- 雷数3～5，单雷伤害为最大气血的20%～30%；先判成败，再联合生成符合成功总伤害≤100%、失败>100%的雷劫序列。
- 渡劫满血开始；乌云出现滚动3秒后开始逐雷，首次命中出现护罩并持续到结束；每雷扣血，最后成败结算。
- 成功伤害等于100%仍成功，显示气血强制为1。
- `JingjieUI/Panel/expect`为Scrollbar；`Num`显示当前每秒经验；每轮结束用通用RuntimeToast显示实际到账经验，仅境界页可见。
- 离线收益用MessageBoxLayer；渡劫独立Prefab；角色只放挂点，位置／缩放由用户调整。

## 实施默认与边界

依照已获批准的开发清单实施：成功扣本阶所需经验并保留溢出；失败扣`need_exp×fail_upgrade/10000`最低0、不降阶；成功清零失败计数，失败计数重登保留；战斗／任务经验继续加入同一经验池但不自动升级。雷击间隔暂1秒、结算停留暂1.5秒，参数可调。
未获用户确认的画面效果和资源兼容性不能作为已验收；不把独立源码复制或静态检查作为最终完成。

## 当前检查点

- 命令cwd为E盘工程；Unity PID 42476 的projectPath为E盘`unityclient`，非C盘checkout。
- 初始仅JingjieLayer.prefab有用户修改。
- 第01项开始构建前，已切换EditorLocalServerBuildGuard、LocalServerSupervisor及SteamWindowsBuild；原Cocos构建脚本保留。
- 全部开发项和技术验收完成；当前为Bootstrap Edit Mode。后台9个真实协议用例、8项境界状态检查、158项红点规则检查及Unity实际入口体验均通过。未将技术验证冒充用户画面确认，`manualPassed=false`。
- 03资源发现旧材质_MainTex丢失GUID；已证实当前effect_Base_GJ仅使用_BaseMap，在Unity导入副本移除该无效旧属性，H盘源不改。
- 03预制体验证曾误把fx_ui_dujie禁用的根Renderer（无材质、无发射）当成错误；验证仅检查会渲染的Renderer，实际材料与Shader均通过，不填占位材质。
- 新C#脚本需显式AssetDatabase.Refresh/ImportAsset后确认MonoScript已索引、类型已加载；MCP refresh返回idle不能单独证明新脚本已导入。
- 服务端业务与存档在`unityserver/src/jingjie_unity.*`，Unity源码的CUser创建/读取/保存/经验/退出与定时器接入；元配置ID扩至uint16，累计属性不再重复累加。
- 04/06/08验证仅使用`.local/jingjie-rework/backend-probe-04/fresh.db`及8714端口，测试结束已关闭自启进程；未修改用户Slot。后台先判结果并原子保存后演出，未完成的渡劫记录可重登重放，前端演出完发op5确认；离线告知op6仅清除通知，不参与发奖。
- 旧存档迁移采用`max(原玩家数字等级,原20境界对应550阶锚点)`并限于1～550；旧经验原值保留；新角色初始化为1阶。Schema新增表，原Cocos schema不改。
- 验证失误修正：临时环境首次缺xml目录，已补依赖预检；失败经验断言此前误用发送时间代替累积时间，已按存档last_ms和小数余量精确对账。失败证据保留于`backend-probe/server.log`、`backend-probe-03.log`；正确对账`backend-probe-04/failure-penalty.json`。
- 编译与运行证据追加在本表对应项；大日志存`.local/jingjie-rework/`。

## 实际体验验收

使用`.local/jingjie-rework/client-acceptance-01/Saves/Slot01/projectx.db`自建角色，运行时只替换测试存档服务根路径，再通过标题按钮、创角InputField与EventSystem/Raycast进入游戏。没有修改生产启动参数或用户Slot。

| 路线 | 当前证据 |
|---|---|
| 创角→境界→手动升级 | `realm-income.png`、`manual-upgrade.png`；初始100经验/秒、每5秒500，一阶→二阶 |
| 离线收益 | `offline-credit.png`、`offline-before-close.json`；49小时夹具仅计48小时，自动到账25,920,000 |
| 普通渡劫成功 | `trial-natural-timeline.txt`；21/28/21，合计70%，结束确认不再扣经验 |
| 自然失败→阈值 | `failure-natural-after.json`、`trial-failure-natural-timeline.txt`；29/24/29/23/22，合计127%，第540阶不变，14失败→15失败 |
| 下一次保底 | `guaranteed-after.json`、`trial-guaranteed-timeline.txt`；22/21/20，合计63%，540→541，计数清零 |
| 断线期间演出未确认 | `replay-fixture.json`、`replay-after.json`；重放原服务端生成的同一序列，不生成新结果，不重复升级或扣经验 |
| 粒子与血条 | `trial-health-sprite-2.png`；乌云/闪电/持续护罩与逐雷血条可见；结束相机回到1个，私有舞台0个 |
| 最高境界与64位经验 | `maximum-panel-corrected.png`、`maximum-exact-display.txt`、`maximum-final-state.json`；第550阶经验超过2^53仍精确、继续积累，按钮隐藏，Num为27,550 |
| 预览与系统 | `preview-stage550.png`、`settings-realm-corrected.png`；8行复用、实际滚轮到550、系统显示完整名称 |

前端修复过程中发现并保留了粒子只写RGB导致透明RT不可见、无Sprite的Filled血条、旧系统等级标签过窄及未手调Panel_End倍率等证据。均已定向修正。后续获用户授权的Prefab布局修改已单独记录；历史整Prefab哈希不能代替当前布局保护基线。

## 交付与边界

- 在E盘`unityclient`打开`Bootstrap`并Play，通过新游戏/旧的回忆进入，再点击主角入口体验。
- 正式表：`unitydata/excel/jingjie_config.xlsx`；独立服务端：`unityserver/src/jingjie_unity.*`；渡劫Prefab：`unityclient/Assets/Prefabs/OneLevel/DuJieLayer.prefab`。
- 渡劫角色仍为空`RoleAnchor/SpineAnchor`，不自动适配或覆盖用户位置/缩放；具体构图留给用户调整和确认。
- 资源清单仅提供Wwise成功事件`au_ui_level_up`，没有独立雷击音效。本次未接入Wwise音频，不以其他声音冒充原资源。
- 未生成新的Unity Windows Player包；当前可在Unity Editor体验。未提交或推送。
- 最终保护检查：53个编译输入属Unity独立源码，1365个Cocos文件及用户原JingjieLayer哈希不变。

## HANDOFF

### 2026-10-11 布局迁回Prefab

- 已按用户要求改为Prefab维护固定布局：ExperienceRequirement、CultivationExperience、SmallStageAura、突破Animator、7行属性和8行预览均为序列化节点；删除运行时创建和硬编码字号/尺寸/锚点。原角色挂点不改。
- 初始位置、字号、尺寸可直接在JingjieLayer/Jingjieyulan编辑；飘字持续时间/上浮距离和预览行高/滚动步长在组件Inspector编辑。滚动和飘字仅改变动画偏移；小阶光效改变颜色/透明度。
- 原Prefab及meta备份：`.local/jingjie-rework/prefab-layout-before/`。新增一次性迁移工具不会在启动或Play时执行。PrefabAuthoredLayout阻止公共文字初始化改写这两个界面的尺寸。
- 检查入口：`ProjectX.Editor.JingJiePrefabLayoutChecks.Run()`；覆盖1/10/550阶、手改位置尺寸字号、550阶预览与重开复位、节点数量与序列化组件；通过证据见`.local/jingjie-rework/prefab-layout-checks.txt`。本次未做真实登录Play和用户画面验收。
- 旧整Prefab哈希是本次获授权修改之前的保护证据，不能继续作为新Prefab未变的判定。Cocos不在修改范围。未提交/推送。任务记录接近20MB；后续Play与画面调整另开任务，从本检查点续验。

### 2026-10-11 定向修复：旧档首次登录离线收益

- Slot01旧档首次升级到新版境界时，迁移分支把经验计时起点设为本次登录，遗漏旧档离线收益及告知。原实际存档仅只读检查，未修改。
- Unity独立服务端改为读取旧档`role_info.login_time`（实际为最近保存/退出时间）；缺失时使用记录的创角时间。按当前阶收益100%补算，最多48小时，先入账再生成现有MessageBoxLayer所需通知。
- 独立服务端Debug编译通过；隔离SQLite与真实协议验证6项：新角色无虚假通知、首次旧档48小时封顶与通知、关闭告知不发奖、重登不重复历史奖励、超过2^53的经验精确累加、缺退出时间回退创角时间。
- 证据：`.local/jingjie-rework/legacy-offline-probe-01/result.json`、`legacy-offline-build.log`、`inspect-offline-login.json`。本次未重新运行Unity画面验收；实际Slot01已完成迁移，下一次登录按新状态的退出时间结算。此次首次迁移已漏掉的历史收益未擅自补发。
- 修改仅限Unity独立服务端；Cocos源码/配置和用户手调Prefab保护检查通过。

技术开发和Editor实际入口验收完成；证据总索引`.local/jingjie-rework/final-acceptance.json`，定向问题台账`.local/jingjie-rework/operation-ledger.json`，所有记录均已解决。当前Unity保持E盘Bootstrap编辑状态，不运行测试服务器。后续只需用户调整DuJie角色挂点并确认构图；Wwise成功音效及Windows Player打包作为明确后续事项。当前任务记录已约18.4 MB，后续画面工作另开任务，不重做已有效的协议与业务验收。

### 2026-10-11 登录光效引用与Prefab文字颜色定向修复

- 登录异常根因：共享RoleCultivationAura改为依赖序列化glow后，MainHud仍动态AddComponent；正式Main/UImainLayer_new.prefab漏迁，协议306/321渲染时抛出`Realm prefab stage aura is missing`。
- 主界面补SmallStageAura节点和组件引用，复用境界Prefab已有光效；消费者只读取组件。主界面原有218个RectTransform的位置、尺寸、缩放、锚点均保留。新增回归覆盖主界面1个与境界3个光效消费者。
- 用户Prefab中的经验文字已是白色；旧代码修为不足时强制红色，足够时复用旧等级标签颜色。现删除境界及预览的全部Text.color赋值，文字颜色只由Prefab维护；经验条件只显示当前/所需修为，不显示成功率、失败次数或保底提示。渡劫内部规则保持原业务行为。
- 在同一现有Editor中使用实际Slot01隔离副本，进入Play后仅替换内存中的存档服务根目录，随后通过EventSystem/Raycast走“旧的回忆→存档进入→主界面”、离线告知确认、境界按钮、头像入口、预览开关。未调用Presenter入口或onClick.Invoke。最终这批路线在一次连续Play中完成。
- 实测70个境界Text和136个预览Text的颜色逐一与当前Prefab一致；在线5秒结算后经验仍白色。关闭离线通知前后经验/修订号一致。布局回归覆盖1/10/550阶、修为不足及保底状态、预览550阶与重开；Console无错误/警告。
- 有一次验证被异步编译域重载中断，保存错误并在最终程序集确认后重启Play续验；不是登录业务报错。原用户存档在隔离验证期间哈希未变；1365个Cocos保护文件未变；隔离SQLite完整性通过。
- 最新证据：`.local/jingjie-rework/login-repair-acceptance.json`；画面：`unityclient/Captures/Editor/JingJieLoginRepair/realm-authored-white.png`。旧整体验收仅作历史，本次手动画面确认仍为`manualPassed=false`。
- 收口：原Editor PID42476保留E盘Bootstrap编辑状态，Play与测试服务关闭；项目unityMCP覆盖恢复false。未提交/推送，既有脏工作保留；旧档此前漏掉的历史经验未补发。

### 2026-10-11 五秒经验提示统一为通用tips

- 按用户要求，境界可见时的五秒结算提示直接走既有`ShowToast/ToastPresenter`，位置、默认2秒时长、排队和淡出均复用通用提示。删除独立`CultivationExperience`节点及其上浮/透明度动画字段；JingJieIncomeView仅更新周期条和每秒收益。
- 原手调角色挂点及剩余境界RectTransform未改，文字仍沿用Prefab白色，成功率/失败次数/保底提示继续不显示。一次性布局迁移工具也停止创建独立飘字，未重跑整套迁移。
- 在现有E盘Editor、隔离Slot副本，通过真实菜单/存档/境界入口连续验证；两个实际结算间隔约4.995秒，均显示`+25,250经验`，同一RuntimeToast实例、通用锚点(0.25,0.68)至(0.75,0.78)、默认时长2秒；经验增加25,250。
- 初版临时观察器的委托类型和Editor帧采样问题已保存到台账；改为Canvas渲染边界观察后通过。游戏Console无错误/警告；布局及颜色回归通过，原用户存档哈希与1365个Cocos保护文件保持不变。
- 证据：`.local/jingjie-rework/shared-tips-acceptance.json`、`tips-render-observation.json`；截图：`unityclient/Captures/Editor/JingJieLoginRepair/shared-experience-tips.png`。画面最终确认仍由用户完成，`manualPassed=false`。
- 原Editor保留Bootstrap编辑状态，Play和测试服务关闭；项目MCP覆盖恢复false。未提交/推送。

### 2026-10-11 单角色与合并属性提升表

- 按用户要求修改`OneLevel/JingjieLayer.prefab`：只保留左侧当前角色，删除Panel_R、Panel_End以及旧的两个Attr_List/属性面板；右侧新增`AttributeComparison/Attr_List`，7行均使用装备强化Prefab的底纹、对比箭头、绿色上升图标和提升量文字样式。
- 用户补充的表头要求已落实：`CurrentStage`和`NextStage`直接显示当前/下一境界阶段名，例如“大乘十阶”“破虚一阶”；行内容为属性名、当前值、下一阶值、差值。最高境界显示“已达最高境界”，不显示下一阶箭头或虚假增量。
- 所有固定坐标、尺寸、字号和颜色写入Prefab；渲染只填内容及业务可见状态。左侧原角色挂点保留；Panel_L/bg_L、Panel_tupo、expect、effect_jingjietupo_1整子树序列化数据与本次备份完全一致，所以下方经验、周期条、突破按钮与效果未改。
- 回归覆盖1/10/100/550阶、修为不足及保底状态，验证单角色/单列表、境界名表头、攻击3262→3317提升55、百分比提升0.04%、最高阶箭头隐藏、文字颜色/布局不覆盖与预览550阶。旧布局迁移入口在新对比表存在时拒绝执行，防止恢复已退役结构。
- 现有E盘Editor中通过隔离存档、真实菜单/存档/境界按钮入口验证，实际只有1个可见SkeletonGraphic，7行属性内容正确；Console无错误/警告。首次进入Play的隔离检查/输入遇到启动未就绪，已保存证据并加强MCP响应失败处理，确认activeSlot=0后成功隔离并继续同一Play完成路线。
- 证据：`.local/jingjie-rework/attribute-comparison-acceptance.json`、`attribute-comparison-regression-final.json`、`attribute-runtime-state.json`；截图：`unityclient/Captures/Editor/JingJieLoginRepair/realm-attribute-comparison.png`；本次修改前Prefab备份：`.local/jingjie-rework/attribute-comparison-before/`。
- 原用户存档、1365个Cocos保护文件未变；原Editor保留Bootstrap编辑状态并选中境界Prefab，Play/测试服务关闭，项目MCP覆盖恢复false；未提交/推送，`manualPassed=false`，最终画面仍待用户确认。

### 2026-10-11 用户移动预览按钮后的路径报错

- 当前用户Play已在Failed状态：`JingJie imported node was not found: Layer/JingjieUI/Panel/Panel_L/title_bg/Btn_xiangxi`。实际 authored 按钮已移到`JingjieUI/Panel/Btn_xiangxi`；不是按钮缺失，而是代码绑定父节点路径过于固定。
- 改为在境界视图内绑定唯一`Btn_xiangxi`并缓存Button引用，PreviewControl复用该引用；换父节点不再影响绑定。未回改用户层级、位置、缩放、字号、颜色或隐藏状态。
- 保存错误/Play检查点后退出原失败Play编译；新增隔离实例回归，主动换预览按钮父节点再验证绑定、1/10/100/550渲染与预览。实际隔离Slot通过菜单、境界按钮、移动后的预览按钮、头像入口和预览重开；Console无错误/警告。
- 用户当前境界Prefab及meta、预览Prefab全文件哈希未变；隔离验证期间用户Slot哈希未变，1365个Cocos保护文件未变。修复仅涉及JingJieRenderBridge和既有PrefabLayoutChecks；未提交/推送。
- 证据：`.local/jingjie-rework/prefab-edit-bug-acceptance.json`；截图：`unityclient/Captures/Editor/JingJieLoginRepair/realm-user-layout-fixed.png`。原Editor保留E盘Bootstrap，验证Play/服务器已关闭，项目MCP覆盖恢复false；画面确认仍由用户完成。

### 2026-10-11 通用Toast迁入可编辑Prefab与按行高自适应

- 按用户要求新增`Assets/Prefabs/Common/RuntimeToast.prefab`，通过正式原生引用键`Prefabs/Common/RuntimeToast`加载实例，ToastPresenter不再动态创建底框/Text或写死位置、字号、文字颜色。
- 默认Prefab为单行：字号24、底框高度32，文本上下各4px；底框高度按`8 + Text.fontSize × 实际渲染行数`计算，显式换行、自动换行和富文本均计入。代码仅调整底框高度；位置/锚点/宽度、字体/颜色、背景、基础透明度和ToastView淡出时长可在Prefab手调。
- 一行/两行/三行验证高度32/56/80；长文本自动换行为4行、高度104；富文本两行高度56。手调位置、颜色、字号保持有效，队列接续通过。实际菜单→存档→境界连续两次五秒结算显示新Prefab，单行高度均32。
- 用户指出的`Destroy may not be called from edit mode`来源为本轮Edit Mode检查清理旧ToastPresenter：已改为只对实例根节点在Edit Mode使用DestroyImmediate，Play使用Destroy。重新验证Console无错误/警告。失败原文和修复证据保留台账。
- Native引用索引只追加新键，Resources只保存引用asset；不复制美术、不修改Catalog或用户境界/主界面Prefab。用户Slot与1365个Cocos保护文件未变。
- 证据：`.local/jingjie-rework/toast-prefab-acceptance.json`；截图：`unityclient/Captures/Editor/JingJieLoginRepair/toast-prefab-runtime.png`。本轮停止测试Play/服务器，保留原Editor并选中RuntimeToast Prefab；项目MCP覆盖恢复false。未提交/推送，画面最终确认仍待用户。

### 2026-10-11 主干提交整理

- 用户已授权将本轮境界相关内容提交并推送远端main。范围包括Unity独立服务端源码/构建、550阶正式Excel及双端导出、在线/离线收益与渡劫、境界属性对比及预览、关联入口/红点/等级显示、通用Toast Prefab，以及用户手调Prefab和实际引用的Sprite九宫格参数。
- Cocos源码/配置、用户Slot、`.local`验证日志与夹具、Excel临时锁文件不提交。使用逐文件允许清单暂存，不使用git add -A。
- 隔离检查工具不再默认要求旧布局哈希；通过`--prefab-baseline`显式指定当前批准布局，旧基线作为历史证据保留。正式表、独立服务端编译、源图/引用闭合、定向回归及既有实际入口证据按发布前当前文件核对。
- 仍需用户最终画面确认；本轮未新建Windows Player包，Wwise渡劫成功音效仍未接入。已迁移的实际Slot不会补发首次漏算历史离线经验。
- 发布前新验：550阶/54次突破正式表校验、独立服务端Debug编译与SQLite冒烟、53编译源归属、1365个Cocos文件保护、当前批准Prefab哈希保护通过；9个Prefab导入及原生索引闭合、8类境界状态、1/10/100/550布局/移动按钮、158项红点、Toast显式/自动换行与队列回归通过，Console无错误/警告。
- 发布回归发现Scrollbar.handleRect由进度驱动，已从固定几何保护中排除，仅固定节点受位置/尺寸/字体/颜色保护；未改用户Prefab。既有真实协议和实际入口证据继续保存于`.local/jingjie-rework/`，不把静态发布检查替代最终画面确认。
