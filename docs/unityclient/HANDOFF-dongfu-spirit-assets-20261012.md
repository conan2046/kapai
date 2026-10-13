# 聚灵阵：资源与手拼预制体交接

2026-10-12。工程：`E:\neiwang_kapai\Game`；Unity：`unityclient`。基线`main / b19962da`。只准备资源和Prefab；用户手拼、确认后再开发。未提交、未推送。

## 编辑入口

- **正式内容**：`unityclient/Assets/Prefabs/DongFu/DongFuSpirit.prefab`，MCP已打开。原GUID `b310f91bc876c25488db780568f9b9ad`、既有节点ID与RectTransform保留。
- **整页参考**：`unityclient/Assets/Prefabs/DongFu/Authoring/DongFuSpiritAssembly.prefab`。嵌套既有`Shared/OneLevelLayer.prefab`和正式Spirit，未注册运行时Catalog。只覆盖顶部实例的标题/显隐，不修改公共源Prefab。
- 优先编辑正式Spirit。在参考组合里修改内容时须Apply回嵌套的Spirit，否则运行页面不会获得修改。不要把参考组合注册为业务页，不要将顶部再复制进正式内容。
- 当前Catalog的`parentKey: OneLevelLayer`和`ConfigureDongFuSharedFrame`保持不变；实际入口继续使用同一`DynamicUi_OneLevelLayer`及货币链。

```text
DongFuSpirit
├─ LevelPanel
│  ├─ Title / ArrayArt / Level
│  ├─ Cost (Icon / Count) / CostText
│  └─ Upgrade / Label                  暂不可交互
├─ BonusPanel
│  ├─ ProductionTitle / Growth / Yield
│  ├─ CombatTitle / Attribute0..3
│  └─ EffectNotice
├─ States / Loading / Locked / Error   状态窗口默认关闭
└─ AuthoringParts                      新增备选零件，默认关闭
   ├─ ArrayFxAnchor / fx_ui_JuLingZhen_Da  原特效关闭，缺动画
   ├─ MaterialSlots / Material1..3     嵌套已有ItemSlot
   └─ UpgradeButtonTemplate            嵌套已有ActionButton

DongFuSpiritAssembly                    仅参考组合
└─ DynamicUi_OneLevelLayer              嵌套Shared/OneLevelLayer
   ├─ DongFuSpirit                     嵌套正式内容
   ├─ Panel_12 / Title                 标题/返回
   └─ GoldCheck                        既有货币区域
```

备选三个材料槽不代表已确认要三种材料；四行属性也不是最终属性数量。原有底板、阵图、颜色、字体、位置及大小保留，供用户调整。后续布局/资源引用放Prefab，代码只刷新内容、状态、显隐和必要进度。

## 旧布局与资源

旧窗口：`H:/xiuxian/XiuXian/Assets/GameProject/XiuXian/GameRes/UIWindow/JuLingZhenWindow.prefab`。同根`UIComponent`有`JuLingBtnComp`、`CommonPriceComp`、`CommonConfirmBtnComp`及`RedPoint`。

旧布局包含`main`、`Txt_Level`、`Txt_Product`、`Tran_TypeGroup`、五个灵根组件、`Tran_CostGroup`、`Tran_Max`、`Tran_Tips`和返回/说明/确认按钮。中心为主阵与灵气，外围为五行灵根，下部为升级材料；可参考布局，不直接采用旧业务结构。

追踪旧窗口71项依赖，选择51项视觉资源：44项新增、7项复用，新增约4.6MiB。复制原`.meta`保留GUID及Sprite合同；现有文件未覆盖。旧窗口、脚本、公共字体、图集和整屏背景未导入。

| 内容 | 当前资源位置（相对Unity） | 处理 |
|---|---|---|
| 备选小面板 | `Assets/Art/UI/ui_dongfu/df_ys_22.png`、`df_ys_31.png` | 不替换现有底板 |
| 五行条底 | 同目录`df_ys_32..36.png` | 黄/绿/蓝/红/棕 |
| 五行图标 | 同目录`df_ys_37..41.png` | 金/木/水/火/土，仅美术候选 |
| 六组特效 | `Assets/Prefabs/DongFu/Effects/fx_ui_JuLingZhen_{Da,Jin,Mu,Shui,Huo,Tu}.prefab` | 保留粒子/模型语义，待补动画 |
| 特效依赖 | `Assets/Art/Effects/Materials/`、`Textures/`、`Models/` | 新增11材质、12贴图、3模型 |
| 复用模型 | `Assets/Art/Effects/Models/fx_yuanpian_001.FBX` | 已有同GUID/同内容 |
| 复用贴图 | 同Textures目录`fx_glow_01.png`、`fx_wenli_007.tga`、`fx_wenli_015.png` | 已有同GUID/同内容 |
| 复用着色器 | `Assets/Shaders/Effects/`中的`effect_Base_GJ.shader`、`Particle Add.shader`、`Particle Alpha Blend.shader` | 已有同GUID/同内容 |
| 公共顶部 | `Assets/Prefabs/Shared/OneLevelLayer.prefab` | 唯一顶部来源 |
| 公共零件 | `Assets/Prefabs/DongFu/Components/ItemSlot.prefab`、`ActionButton.prefab` | 保留嵌套引用，不搬旧公共件 |

本轮是Prefab静态引用与候选资源准备，未新增动态加载键或重建全工程图集。后续确定动态资源后，按现有`ProjectXAssetReferences.json`、`UnityAssetReference`与原生图集规则登记，不复制美术进Resources。未生图。

**资源缺口：** 六组特效的Animation均引用缺失的两段动画：`248e32c39f429534aab5640aaf245935`、`016630c8d65ed6c4bb43a8b531284643`。旧Assets、扩展的`H:/xiuxian`和当前Assets均未检索到对应`.meta`。保留原引用，未伪造动画或删除组件，特效默认不启用；不宣称完整效果可用。其余模型/材质/贴图的GUID和fileID检查通过。

## 规则及正式字段

正式源：`unitydata/excel/dongfu_config.xlsx`的`dongfu_spirit_level`；客户端导出：`Assets/Resources/ProjectXData/Configs/dongfu_spirit_level.json`。源与导出均只有一条`enabled=0`示例，没有有效生产配置。本轮只读，未改表或导出。

| 字段 | 正式含义/当前需求 |
|---|---|
| `id / level / next_id` | 等级记录/阵法等级/下级记录，0满级 |
| `cost_items` | 升级`[[item_id,数量]]`，材料待定 |
| `growth_reduction_bp` | 成长时长缩短万分比，对应已确认成长加速；不是速度增加百分比 |
| `yield_bonus_bp` | 额外产量万分比，对应已确认增加收获 |
| `combat_attributes` | 本级累计`[[现有属性ID,值]]`；不逐级重复累加，不造属性ID |
| `target_scope` | 固定`lineup`，对应已确认上阵神将 |
| `enabled` | 0未启用/1启用，本轮保留0 |

| 旧资料 | 与当前需求的差异 |
|---|---|
| `J-聚灵阵_JuLingZhen.xlsx` | `Id / Level / storage / Cost / Spiritual`；每5秒产灵气、满仓停产，缺三类当前加成字段 |
| `L-灵根表_LingGen.xlsx` | `Id / type / Level / name / Cost / BattleData / BattleSkillAdd`；五行分别升级、属性和技能伤害，不能直接等同当前上阵属性 |
| 旧《洞府功能》 | 四资源场地→升阵→产灵气→培养角色五行灵根，与当前种子/作物模式不同 |
| V1.3《洞府生产系统策划案》 | 动态浓度、全生产/修为增益、离线8h/70%、月卡上限等未获本轮采用 |

后续开发前需冻结：升级是否影响已种下作物、产量取整及金币直接产出的增益方式、具体属性及单位、等级/解锁/成本。浓度、离线效率、丹器加速和五行灵根不因旧文档存在就自动实现。本轮未新增规则。

## 截图与验证

截图位于`unityclient/Captures/Editor/DongFuSpirit/`：

- `prepared-assembly.png`：本轮MCP在Edit模式渲染1334×750整页参考，无业务数据，正文颜色和布局仍为原Prefab。
- `legacy-juling-layout.png`：旧《洞府功能.docx》内`word/media/image29.png`原图；旧纵版布局参考，不是运行验收。
- `legacy-assets.png`：旧聚灵专用12张PNG一览。
- `concept-v1.3.png`：`D:/氪金模拟器/Outputs/洞府/UI/聚灵阵.png`工程内参考副本，整图不能当拆分资源。

MCP核对正确E盘工程、Editor非Play及无未保存Prefab编辑后执行；检查现有Home/Spirit/OneLevelLayer和Catalog。Spirit既有RectTransform前后逐项一致，原GUID不变，两份Prefab无缺脚本，Console错误/警告0条；旧特效缺动画仍独立列为资源缺口。灵田、Home、共享顶部、源码、协议、配置和存档未修改，既有两处用户`.meta`修改保留。

本地证据：`.local/dongfu-spirit/import-plan.json`、`resource-audit.json`、`import-validation.json`、`fields-and-rules.txt`、`hierarchy.txt`及MCP响应。后续从用户手拼后的正式Spirit及本交接继续，不重建灵田。
