# 神将重生模块

> 当前结论：G0-G6全部通过；固定SQLite标准Full完成24/24控件、10/10语义和11个运行态，当前G5后最终真实Play已由用户确认“测试通过”。

## 范围

- 当前Cocos入口一：`MainUI btn_huishou → EMID_HUISHOU(410) → HuiShouMainUI tab=1 → ShengJiangChongShengUI`。
- 当前Cocos入口二：`btn_shenjiangbeibao → PetBagPetSubUI recycle → EMID_HUISHOU(410)`，与入口一汇合。
- 包含空态、候选选择/更换、`/24 op=8`返还预览、50绑定元宝成本、确认/取消/关闭、`/24 op=9`重生、失败与生命周期。
- 不包含装备/法宝重生与分解；神将图鉴必须在本模块收口后另开独立任务。

## 三方证据

- 入口与路由：`client/ProjectX/src/View/MainUI.lua`、`client/ProjectX/src/View/KaPaiPet/PetBagPetSubUI.lua`、`client/ProjectX/src/core/AppDef.lua`。
- Cocos View：`HuiShouMainUI.lua`、`ShengJiangChongShengUI.lua`、`ShengJiangChooseUI.lua`、`ChongShengConfirmUI.lua`。
- 协议：`PRO_PET=/24`；查询`op=8 + uint32 petId`，执行`op=9 + uint32 petId`；接收端按op分发返还预览与成功事件。
- 服务端：`CPackageDeal::PetOption`路由op8/op9到`CUser::HeroCChongSheng/HeroChongSheng`；目标不存在或在出战阵位时拒绝。
- 返还算法：`SPet::GetChongShengCost`合并英雄经验丹`834..837`、突破资源`60000/851`和修炼资源`853`。
- 成本：客户端`config.json id=18=[60001,0,50]`；服务端检查并扣除50绑定元宝。
- Prefab：`shenjiangchongsheng.prefab`、`Choose.prefab`、`Popup_Confirm.prefab`与两类公共框架。

## G0冻结

- 控件矩阵：`docs/unityclient/matrices/HEROREBIRTH_CONTROLS.json`，24项。
- 配置/业务ID覆盖：`docs/unityclient/matrices/HEROREBIRTH_COVERAGE.json`，覆盖49个hero记录（id=0有产品证据排除）、100级经验、15级突破、20级修炼、7种返还资源、固定成本60001及op8/op9。
- 固定身份：Cocos MySQL `7200057/1000115`；Unity `Application.persistentDataPath/LocalServer/projectx.db`的`7200057/1000003`。
- 原生客户区：`1334×750`、Windows 100%缩放。
- 用户调整的`shenjiangchongsheng.prefab`为只读布局基线，SHA-256=`7E210120B232144840C62DAE3B323E48E82D4C0CE3D5CB682C7F761FFF5EA4B9`。

## 实现边界

- 旧Lua/服务端继续拥有协议、返还算法、成功/失败和持久状态；Unity只绑定现有Prefab、真实控件、Imod模型与权威结果。
- 两条入口只允许创建一个重生实例；退出、切号和延迟回包必须清理选择、pending、监听与弹窗。
- G3前补齐SQLite可逆Fixture、DataPreflight合同、batch场景、截图状态和源码锚点。
- 不覆盖、不回退、不重新设计只读Prefab；仅允许在代码中补业务、导航、显隐与数据绑定。

## G1-G4 当前证据

- G1：固定Cocos身份`7200057/1000115`，8个当前原生`1334×750`状态已冻结；每张图同目录保留`-ui-resource-map.md`。
- G2：两条入口、`/24 op=8/9`、返还配置/资源、Imod与运行时Transform闭包通过；服务端返还列表变量遮蔽已按当前源码修复。
- 数据前置：Unity仅使用`Application.persistentDataPath/LocalServer/projectx.db`的`7200057/1000003`；夹具含10名神将、7名未上阵候选、2名上阵拒绝对象、1名初始态对象及足额/不足额货币档。
- G3：标准固定账号batch通过，结果为`controls=True; candidates=5; fixedProfiles=True; boundPremium=100000`；数据库恢复SHA=`6658D9F4970D515B577B055B1E6DC392661DA7FE3D32D7F2A276C5B14C28EBB7`，工具链`319/319`，Bootstrap双次幂等SHA=`C013DB0676E409CDBEA07604B86CACB1142F77C7E7FF3DB57731EE72A6D5E1D1`。
- 早期Play：用户连续选择并重生2名神将，返还预览、实际返还及重生后等级1均确认通过；3项阻塞反馈均已修复并记录于`.local/unity-validation/hero-rebirth-early-user-play-latest.json`。
- G4：标准固定账号batch通过24/24真实控件、10/10语义和11个运行态；覆盖`/24 op=8/op=9`、不足货币、上阵拒绝、确认/取消/详情、主动断线重连、账号隔离和重登持久化。成功态SQLite额外验证50绑定元宝扣除、目标神将等级/突破/修炼归零、星级保留、返还入库及其他神将/阵位不变。
- 恢复：恢复动作当下数据库文件SHA精确等于`6658D9F4970D515B577B055B1E6DC392661DA7FE3D32D7F2A276C5B14C28EBB7`；恢复后真实登录按业务语义哈希复核，再次精确恢复并清理夹具，残留0。
- 用户Prefab保持只读，当前SHA仍为`7E210120B232144840C62DAE3B323E48E82D4C0CE3D5CB682C7F761FFF5EA4B9`。

## 已识别边界

- `CUser::HeroChongSheng`内部`MultiCost allCost`变量遮蔽与绑定元宝检查/扣除分路已修复，并由真实op9及成功态SQLite断言验证。
- 服务端不足50绑定元宝分支不写`PRO_ERROR`；Unity在发送op9前按权威货币快照拦截并提示，G4已验证不打开确认、不发送写请求且状态不变。
- Cocos候选表达式可能把已上阵且已突破神将列入候选；Unity候选列表严格排除上阵神将，同时保留真实op8/op9权威拒绝覆盖。
- 切换神将后的预览、确认与不足货币状态均由新请求和生命周期清理重置，G4已覆盖无旧状态污染。

## G5-G6

- G5：用Computer Use在当前源码/配置/夹具下重采8个Cocos状态，冻结最终清理后的输入指纹；双端8/8原图、并排、叠加、增强差异和逐项视觉复核通过。证据：`.local/ui-fidelity/HeroRebirth/compare/g5/report.json`、`.local/unity-validation/herorebirth-g5-visual-assessment-latest.json`。
- G5收敛：空态恢复Cocos五行重生规则；返还项真实点击改用完整`common/huoqutujing`详情页并移除空白来源图标；不足反馈统一为`元宝不足`。返还预览显示且默认`Image1`隐藏；`shenjiangchongsheng.prefab`与用户修改的`Choose.prefab`全程只读。
- G6自动化：最终标准Full再次通过；工具链319/319、文档35模块通过；Computer Use运行时已清理；两次`BootstrapSceneBuilder.BuildBatch`得到一致SHA=`C013DB0676E409CDBEA07604B86CACB1142F77C7E7FF3DB57731EE72A6D5E1D1`。
- G6 hard-gate v3：19个直接控件登记当前双端图并保持真实点击合同，5个场景态以`scenarioStateControlIds/scenarioStateContracts`登记且`realEntryClick=false`；24/24均为`automationPassed=true/manualPassed=true/status=complete`。
- G6用户门禁：用户使用固定身份`7200057/1000003`完成当前G5后真实Play并反馈“测试通过”；错误默认身份`1/1000001`已由`-projectXUserId=7200057`修复并写入失败/解决账本。
- G6复盘：79条失败或阻塞均有唯一解决记录，2条历史编译证据已补充为可持久复验文件；待诊断0、未解决0。证据：`.local/unity-validation/herorebirth-final-user-play-latest.json`、`.local/unity-validation/herorebirth-retrospective-latest.json`。
