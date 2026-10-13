# 聚灵阵与五行灵根交接

日期：2026-10-13。工程：E:\neiwang_kapai\Game；Unity：unityclient；基线main/b19962da。用户已确认当前版本并授权整体提交、推送至远程main，发布结果以Git记录为准。隔离Slot04已归档清理，原Slot01–03与灵田Prefab哈希检查通过，测试服务已关闭。以下采用用户最新Excel及确认规则，取代此前next_id、每秒无上限方案。

## 当前规则与正式源

正式源：unitydata/excel/dongfu_config.xlsx（12张表）；unitydata/excel/item.xlsx新增60054“灵气”，type=13、use_type=3、pic=3008。灵气作为独立资源保存，不进普通背包；自动产出、灵根消耗与60054奖励共用同一余额。

| 表 | 字段 | 当前合同 |
|---|---|---|
| dongfu_spirit_level | id / level | 记录ID与等级；按level+1查找下一等级，ID无须连续 |
| 同上 | storage | 灵气存储上限；满仓停止产出，不积攒溢出收益 |
| 同上 | spirit_per_second | 保留用户字段名，含义为每5秒产量；在线、离线均累计整周期，保留不足5秒的时间 |
| 同上 | cost_items | [[道具ID,数量]]；金币60000、元宝60001/60003、灵气60054及背包材料；留空或[]表示满级 |
| 同上 | enabled | 1启用、0停用；空白导出为0，不改写Excel启用值 |
| dongfu_spirit_root_level | root_type / level | 1金2木3水4火5土；各根独立按level+1升级；等级不得超过聚灵阵等级 |
| 同上 | name | 当前等级名称；绑定对应Icon_1..5中的RootName文字 |
| 同上 | spirit_cost | Excel填60054;数量，导出[60054,数量]；空白导出null并表示满级；填写60054;0仍可升级 |
| 同上 | cost_items | 额外材料；灵气不能在此与spirit_cost重复配置 |
| 同上 | growth_reduction_bp / yield_bonus_bp | 各根当前等级总值，五根相加；两项加成在种植时存快照，已有作物不追改 |
| 同上 | combat_attributes / target_positions | 每级新增属性及该级受益站位；已达等级持续保留，按配置累加，多根汇总；没有奇偶规则硬编码 |
| 同上 | enabled | 0停用、1启用 |

已修正聚灵阵501格材料数组缺逗号；只更改对应工作表XML，其他工作簿部件字节相同，证据.local/dongfu-roots/comma-fix-preservation.json。灵根spirit_cost类型说明行由long更正为string，匹配60054;数量文本格式；只改类型元数据，值与样式未改，见.local/dongfu-revised/type-metadata-preservation.json。保留用户正式数值与布局。本轮按用户要求启用正式聚灵阵501行、五根2505行，补聚灵阵建筑记录ID2、open_level=1；聚灵阵500级cost_items设[]以标记满级，其他数值保留。所有根500级spirit_cost已经留空。源表定点修改及保护验证见.local/dongfu-visual-fix/formal-preservation.json，双端导出49份通过ValidateOnly。初始0级产量/储量为0，需升到1级开始产出。

导出：unitydata/tools/Export-UnityOwnedTables.ps1 -Root E:/neiwang_kapai/Game -Group DongFu -Mode Both。SpiritItems组仅从正式item表同步60054；既有GardenItems保持原范围。生成JSON不手改，使用页签名定位，支持用户调整工作表顺序。

## 当前预制体、特效和通用弹窗

主Prefab：unityclient/Assets/Prefabs/DongFu/DongFuSpirit.prefab，原GUID b310f91bc876c25488db780568f9b9ad不变。用户星空背景、五行图标Transform、资源引用及灵田Prefab均保留。

- DonationLayout/D/Donate/LoadingBg/LegacyEffectsViewport：中心特效为红色底图的第一个子节点，在底图之后、等级文字之前绘制，保持世界四角不变。LoadingBg内五个LegacyEffectsViewport_Jin/Mu/Shui/Huo/Tu仍分别与Icon_1..5同级，排在对应图标之前；RootName显示配置name。
- Icon_1..5的Button Transition设为None。原Color Tint的Disabled Color alpha=0.502，正式配置未启用时按钮禁用导致运行图标变淡；保留禁用逻辑，只取消状态染色，运行图标alpha=1。
- UpgradeConfirmation、RootUpgradeDialog：均为游戏公共Assets/Prefabs/Login/MessageBoxLayer.prefab的嵌套实例；文字区、按钮宽度及全屏点击遮罩保存在聚灵阵Prefab中。公共源Prefab未修改。
- CombatAttributes：按用户截图改用Assets/Prefabs/OneLevel/Jingjieyulan.prefab的嵌套实例；标题“站位加成”，Content/Position_1..5为五张卡。无属性时显示NoBonus“暂无加成”，有属性后显示三列Attributes/Attribute_1..33；Value在各自数值区MiddleCenter。GridLayoutGroup、VerticalLayoutGroup及ContentSizeFitter全部在Prefab序列化，超过3行时自动扩充卡片。代码只刷新文字与显隐，默认不显示七项零值。原境界预览源未修改。
- SpiritProductionInfo按用户要求删除。灵气余额与储量在Progress内整条居中显示，秒数字段隐藏；升级材料在确认弹窗显示。
- DonationLayout/D/Donate/Progress：绑定用户已放置的Components/Progress.prefab实例，保留其位置/大小；删除本轮重复新增的第二份Progress。LoadingBar显示服务端production_elapsed_ms对应的5秒进度。页面进入同步一次，随后仅在生产进度满时同步，升级返回权威结果；取消2秒轮询。0级仍显示5秒循环但收益为0，满仓停止生产同步，超时仍可自动重试。Donate/Times（含TimesBg）及Donate/Refresh已删除，手动刷新绑定也已删除；公共弹窗同名Times保留。5秒查询不锁定升级按钮，真实升级请求才进入等待状态；用户升级可覆盖尚在返回的只读查询，旧查询按request_id忽略。
- UiPrefabEffectStage只控制效果实例生命周期；位置、大小、Camera、RenderTexture和效果引用均在Prefab/资产中配置。一个特效Camera与共享768×512纹理驱动六个显示区，不拦截按钮。
- 原六组特效：Assets/Prefabs/DongFu/Effects/fx_ui_JuLingZhen_{Da,Jin,Mu,Shui,Huo,Tu}.prefab；材质、贴图、模型复用Assets/Art/Effects现有迁入资源，保留旧GUID。
- 运行舞台：Assets/Prefabs/DongFu/Effects/DongFuSpiritEffectStage.prefab；纹理：Assets/Art/Effects/SpiritFx.renderTexture。舞台六个固定区域与UI显示区分离；手调时同时调整图片及其同级特效显示节点，运行时代码不重新排版。本次改层级保持全部特效世界四角、图标Transform和Sprite不变。
- 中心透明混合修正：仅舞台Da的5个加法材质使用SpiritStage专用变体；RGB沿用旧材质，Alpha不写入加法面的覆盖度。LegacyEffectsViewport复用现有DuJieComposite预乘合成，消除暗色半透明方块。旧材质、共享shader及五根特效不改；没有用裁切或新图片隐藏问题。
- 资源限制：两段旧Animation（248e32c39f429534aab5640aaf245935、016630c8d65ed6c4bb43a8b531284643）在H:/xiuxian及当前工程均未找到。旧引用保留，舞台实例的Animation关闭；现有粒子、模型与材质可播放，不能声称完整恢复旧动画。未生图或伪造动画。

## 技术与验收

协议325：查询、升阵、指定根升级。SQLite unity_spirit / unity_spirit_root / unity_spirit_request保存资源、生产时钟/上限、等级、revision与防重记录。已存旧周期会先按旧周期结算，再切换5000ms。金币、元宝、灵气、材料及等级在同一事务内保存，失败恢复缓存和客户端权威状态。

生产收益延续灵田快照；战斗属性延续神将当前站位过滤，并保留各级新增属性。

| 检查 | 结果与边界 |
|---|---|
| 编译 / 数学 | kapai与Unity编译通过；garden_growth、spirit_bonus两项通过，包括5秒整周期、满仓不囤积、在线离线等价、极长离线与64位边界 |
| 正式数据 | 12张双端表一致，28项非法配置拒绝；自动等级、空白满级、零消耗、姓名与资源格式检查通过 |
| 新规则真实UI | 隔离Slot04聚灵阵0→1→2、五根独立0→1→2，等级上限、名称变化、当前级生产总值与逐级站位属性通过；灵气60054客户端资源余额同步 |
| 扣费 / 回滚 | 金币与元宝材料、灵气均正确扣除；注入聚灵阵写失败时等级、revision、请求记录、金币1100、元宝100、灵气30均恢复 |
| 防重 / 满级 | 原请求重放、旧revision、根满级、阵满级均不重复扣费 |
| 离线 | 保存余额2、部分周期3000ms、产量7/5秒、上限100；重登按精确时间结算至上限，等级及成功请求不变 |
| 资源未启用 | 正式配置未启用时保留已有灵气余额；首次启用自动初始化阵等级，20灵气在两种状态间保持；客户端资源同步 |
| 公共弹窗 | 更换后真实入口完成升阵确认、升根确认、站位切换与关闭。源框原点偏移已修复；按钮字号、正文位置与遮罩在Prefab配置 |
| 特效 | 六个局部显示区、一个Camera、原34个粒子系统运行；不拦截图标输入；旧Animation缺口单独保留 |
| 既有灵田 | 上一阶段已完成生产快照实测：60秒→46800ms，旧收获快照+195、新快照+202；此次新表/表现修改没有重跑全部灵田路线 |
| 验收与边界 | 2026-10-13用户已实机测试并确认当前版本；正式表已启用。换阵后的真实战斗伤害及全面数值平衡仍未覆盖；本轮定向修正与发布不修改迁移门禁状态 |

证据：.local/dongfu-revised/与.local/dongfu-roots/；失败台账.local/unity-validation/dongfu-spirit-operation-ledger.json。首次重载错用正式配置仅影响隔离登录预检，未执行业务操作，已改为Play重载后创建并核实fixture owner；用户Slot01进度不回滚。

截图（隔离数据）：unityclient/Captures/Editor/DongFuSpirit/Revised/legacy-six-effects-final.png、common-root-popup-verified.png、common-array-popup-final.png、common-position-popup-accepted.png。用户以最终Prefab和实机画面验收。不要运行旧生成器覆盖手调布局。

当前用户Play的透明度与层级修正截图：unityclient/Captures/Editor/DongFuSpirit/Revised/opaque-icons-fx-behind.png；五根运行alpha均为1，按钮禁用状态保留，Console无错误/警告。证据.local/dongfu-visual-fix/fix-report.json；灵田Prefab及聚灵阵.meta哈希未变。按用户要求保持Play并停在聚灵阵，未切存档或修改数据库。

本轮正式数据实机：使用原Slot01，通过真实按钮将阵0→1（金币1、元宝1），五根仍0级；未注入测试数值或回滚进度。1级每5秒产1灵气、上限180。连续观察130→131→132，后两次同步间隔5.020秒、4.921秒；Progress连续填充并清零，进度与收益证据.local/dongfu-visual-fix/progress-runtime.json。当前已自然满仓180，按正式规则停止产出。空站位卡、滚动至第5卡及关闭通过真实EventSystem/Raycast；4行属性卡静态布局高度148，较3行自动扩充，支持33项属性。最终截图position-cards-empty-accepted.png、formal-resource-centered-final.png；Console无错误/警告，保持Play停在聚灵阵。最终画面仍由用户确认。

后续手调与定向修正：以用户最新Prefab为准，Progress位于Donate下；删除Donate/Times与Refresh，其余RectTransform逐项保持。中心特效原正常播放但被红底覆盖，改为底图之后、文字之前，并保持世界四角。只读生产查询不再调用SetPending，真实升级才锁按钮；可覆盖尚在返回的只读请求，旧回包按ID忽略。用户已试升至3级；复测从3→4消耗金币1、元宝1，未修改正式数值或注入存档。16秒观察4次只读请求、177个请求等待帧，按钮禁用帧0、最小alpha=1，灵气700→716。证据.local/dongfu-node-cleanup/；截图center-fx-alpha-fixed.png、center-fx-query-state-final.png。Console无错误/警告；保持当前Play聚灵阵，画面仍待用户最终确认。

本轮结束时用户自行退出Play并打开DongFuSpirit Prefab Stage，保留其最新编辑状态；Stage内Progress父节点Donate、Times/Refresh已删除、中心材质与新层级均再次核对，未恢复旧布局。

## 超时对话续接：顶部问号与最新节点（2026-10-13）

- 续接旧对话 `01a13079-5a10-7462-ab47-205d4197d68f`；目标工程仍为 E:/neiwang_kapai/Game，Unity MCP 当前实例与该工程一致。本段为最新状态，优先于上文旧层级说明。
- 用户已删除 TipsBg；SpiritScreen 已移除 notice 绑定，错误转到通用弹窗。RestoreSpiritFrame 已传入 ShowSpiritHelp，顶部 TitleName/Button_1 显示并使用公共帮助弹窗。
- 用户删除 D 后，Progress 位于 DonationLayout/Donate 下；Reset 合并显示聚灵阵等级与灵气余额/上限。LoadingBg 下旧 LoadingBar、NumBg、SpiritLevel 已删除，Progress 内生产进度条保留。
- cancel、rootClose 已绑定各自公共弹窗的 MessageBoxUI/bg/Btn_close；本次 MCP 检查生产进度、升级、确认、详情与关闭等必需绑定均非空。用户手调 Prefab 未再改写。
- 当前 Play 通过 EventSystem/Raycast 点击顶部问号，确认说明文本显示；关闭公共弹窗、返回洞府、点击 Building1/Enter 再进入后，问号仍 activeInHierarchy=true 且可点击，TipsBg 数量为0，Reset 显示“聚灵阵 4级  灵气 936 / 936”。未执行升级或注入存档。
- 证据：.local/dongfu-help-resume/；1334×750 截图：unityclient/Captures/Editor/DongFuSpirit/spirit-help-button-popup.png 与 spirit-help-button-reentry.png。末次 Console 无错误/警告。
- 保持当前 Play 停在聚灵阵供用户确认画面；未提交、未推送。本次复用既有 Unity/MCP 进程，未新增常驻服务或修改全局配置。

## 最终修正与用户验收（2026-10-13）

- 灵根升级弹窗 Title 只显示“金灵根升级”等名称，删除“ · 配置等级名称”；各灵根图标内的 RootName 继续显示正式配置名称。
- RootUpgradeDialog/MessageBoxUI/Btn_Confirm2/Text 已在聚灵阵嵌套实例启用；仅修改该节点 m_IsActive，677 个 RectTransform 保持不变，公共弹窗源未修改。证据：.local/dongfu-root-dialog-label/。
- 用户在最后修改后明确反馈“我测试了，没问题”，并授权将本地聚灵阵全部相关内容整体提交、推送远程主干。以此为当前版本玩家画面验收；上文各阶段“待确认”“未提交”均为历史状态。
- 发布范围包含客户端与服务端、协议325及SQLite持久化、正式Excel及双端导出、五行资源与特效、预制体和配套验证。两份无聚灵阵引用的公共图片.meta改动保留在本地，不纳入本次提交。
- 已知边界保留：旧源缺两段Animation，当前粒子表现已验收；未重跑全部灵田路线、换阵后真实战斗伤害与全面数值平衡。发布目标为origin/main；版本号以本文件所属Git提交及远端main记录为准。
