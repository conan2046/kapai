# 背包模块

## 2026-08-24 门禁重开

- 当前状态：`G0-G6 passed / 26/26 complete`。
- 逃逸根因：旧G0只登记 `btn_Bag`、`/8`、`/15`，未把客户端 `type=5/use_type=2` 随机盒候选生成进业务分母。
- 当前分母：23个客户端候选；仅510-514具备当前服务端通用闭包；对应80510-80514与4605-4644共40个最终碎片。其余18个候选均在 `BAG_COVERAGE.json` 内带产品证据排除。
- Unity用户测试数据只使用 `Application.persistentDataPath/LocalServer/projectx.db`，固定身份 `userId=1 / roleId=1000001`；MySQL仅作离线对照。
- 512/513/514必须逐盒证明源盒真实减少、碎片落入各自范围、完整“开启获得”弹窗与重登录保持；旧视觉、Runner、人工确认和26/26结论全部失效。

## 当前结论

- 当前门禁：`G0-G6 passed / 26/26 complete`。2026-08-27 已按当前输入完成标准SQLite G4、中央G5及最后相关变更后的G6真人确认；`manualPassed=26/26`。
- 固定账号：`userId=1 / roleId=1000001`，Windows 100%，原生客户区 `1334×750`。
- 控件唯一事实：`docs/unityclient/matrices/BAG_CONTROLS.json`，共 26 项。
- 2026-08-21 已按当前源码、入口、账号、夹具和 hard-gate v2 从 G0 逐门禁重验；旧 2026-07-27 Runner、构建 SHA 与完成结论仍只作问题追溯。
- 当前G3源码合同指纹：`0C9A15C34B327E3B294FA7F03066764A009167DC037ECDEFB7871EF2BD1D7B95`；入口从 `Layer/Main_UI/ButtonGroup1/btn_Bag` 取证。

## 2026-08-21 数字输入回归

- 用户实测：体力丹批量使用弹窗中，数字按钮会改变内部 `quantity`，但 `EnterNumLayer` 输入框没有可见数字，导致无法可靠确认使用数量。
- 根因：`BagFlowPresenter` 的旧 Runner 只断言内部数量；画面显示仍依赖 Prefab 导入后禁用的 `InputField.textComponent`，没有验证最终可见文本。
- 修复：输入框改用独立置顶的只读 `RuntimeInputDisplay`，数字、删除和清空均直接刷新该文本；Runner 同时断言内部值与显示文本 `10 -> 1 -> 请输入数量`。
- 当前验证：Unity 2022.3.62f3c1 同版 Roslyn静态编译通过；固定账号 DataPreflight 5/5、26/26 控件、15/15 语义、数字/删除/确认、真实 `/15`、体力变化、重连、切号与精确恢复全部通过。
- 当前画面：`.local/ui-fidelity/Bag/unity/g5-20260821/BAG-08-INPUT-DIGITS.png` 中输入框明确显示 `10`；Runner 同时断言 `10 -> 1 -> 请输入数量`，不再仅检查内部变量。
- 自动复盘：149 条操作记录，61 条历史失败全部具备唯一解决记录，待诊断 0、未解决 0。

## 2026-08-21 道具跳转与来源商店回归

- 招募券 `1000`、高级招募券 `1001` 均按 Cocos `use_jump=1010` 执行纯跳转：先关闭并移除 Bag，再打开当前 `HappyDraw`；不发送 `/15`，不消耗道具；关闭招募页后回到主界面，不能重新露出 Bag。
- `/224 op=1` 延迟回包只刷新权威招募池，不再拥有页面导航权，避免玩家已关闭招募页后被回包重新打开。
- 装备碎片来源 `functionId=17` 打开玩法商店时，隐藏 Bag 根页、获取途径、装备详情和共用 `OneLevelLayer`；关闭商店后只恢复 Bag 及其标题框。
- 固定账号 Runner 等待 `/221 type=5` 商品实际渲染后再截图，并断言商店打开/返回两侧的页面可见性；当前图 `.local/ui-fidelity/Bag/unity/g5-20260821/BAG-24-SOURCE-ACTION.png` 已显示完整商品且无背包叠层。

## 2026-08-21 随机装备盒奖励反馈回归

- Cocos `/15` 增量处理会对新增或堆叠增加的物品触发 `ShowFlyItems`；Unity 原实现仅更新 `BagStore`，玩家无法确认随机盒实际产出。
- 橙色盒 `512 → 80512 → 4621..4628`、红色盒 `513 → 80513 → 4629..4636` 的服务器配置完整；金色盒 514 原先缺少掉落匹配、等级奖励和权重池三段配置。
- 当前补齐 `514 → 80514 → 4637..4644`，沿用同档八种攻防部位等权、单次数量 1 的现有连续规则。
- Unity 在实际使用 `itemType=5` 随机盒或 `itemType=6` 可选宝箱后采集服务器 `/15` 正向背包增量，按 itemId 合并数量并显示“开启获得”；超过四种时，其余奖励以“道具名×数量”文本完整列出。禁止客户端预测或预发奖励。
- 当前 JSON 结构、三档掉落闭包、Unity 编译与程序集重载已通过；2026-08-27 用户实测发现可选宝箱缺奖励材料弹窗，修复 `ItemType=6` 捕获条件后复测“OK，通过”。该确认只关闭G3早测阻塞项，G4-G6仍按当前输入重新执行。

## 范围

背包全量、增量、整理、普通道具列表/选择/滚动、真实道具使用、批量数量、任选礼包、道具来源、奖励与持久化。

G0 所属边界：

- 包含主入口、一级页关闭/页签、动态物品格、滚动、使用按钮全部分支、数字输入、任选礼包、道具来源及来源图标打开的嵌套装备信息。
- FirstClassBg 顶部货币/体力加号属于 Foundation；跳转后的商城、副本、养成内部控件属于目标模块。
- 当前 Cocos Bag 无出售、合成、批量出售和独立扩容入口；Unity 禁止新增空壳。

## 三方证据

- 全量：`PRO_PACKAGE/8`。
- 增量/操作：`PRO_PACKAGE_UPDATE/15`。
- 旧客户端配置：`item_dat.lua`。
- 当前入口：`MainUI:BagTouchCallback -> OpenFunction(EMID_BEIBAO=111) -> Role.KaPaiBagMainUI(1)`。
- 当前节点：`Layer/Main_UI/ButtonGroup1/btn_Bag`；旧 `ButtonGroup5/btn_beibao` 禁止继续作为证据或自动化目标。
- 页面链：`KaPaiBagMainUI -> KaPaiBagSubUI -> csd/zhujue/beibao.csb`。
- 动态分支：`InputNumUI -> EnterNumLayer.csb`、`GiftChooseUI -> OpenBox_1Layer.csb`、`ItemSourceUI -> huoqutujing.csb`、装备碎片来源图标 `-> PetEquip.EquipInfoUI -> zhuangbeiInfo.csb`。
- 本地隔离注入仅用于自动化，不替代正式使用协议。

## 实现

- `BagStore` 是唯一背包状态源，Lua 不保存临时物品字典。
- `BagPresenter`、`BagFlowPresenter` 复用真实背包、数量输入、任选礼包、来源和装备信息 Prefab。
- 图标统一走 ResourceService：`ItemIcons/equip{pic} → MonsterBust/{pic} → placeholder`。
- `/15` 支持全量整理及单格新增、更新、删除。
- 使用按钮按旧协议发送 slot、数量和 target。
- 礼包候选、普通物品、装备碎片及套装信息读取真实 `item_dat`、`pet_equip`、`suit` 配置；没有可靠资源映射的来源图标隐藏，不显示空白占位。
- 来源动作只负责 Bag 所属分派；目标模块未迁移时保持 Bag 可用并记录目标不可用，不打开神将或其他模块空壳。

## G2 迁移设计冻结

### 协议与权威状态

| 流向 | 字段顺序 | 当前语义 |
|---|---|---|
| C→S `/8` | 无 payload | 请求当前角色完整背包 |
| S→C `/8` | `count:u16`，重复 `slot0:u16,itemId:u16,num:u16`，尾部 `have625:u8,ext647:u8` | 清空并替换 `BagStore`；slot 转为 Unity 1-based |
| C→S `/15 op=1` | `op:u8=1,slot0:u16,num:u8,target:u8` | 普通/批量使用；任选礼包 target 为候选索引 |
| C→S `/15 op=6` | `op:u8=6` | 整理并请求权威全量返回 |
| S→C `/15 op=6` | `op:u8,success:u8`，成功后接 `/8` 同结构但无两个尾标记 | 成功时整体替换 Store；失败不改本地状态 |
| S→C `/15 op=1/2` | `op:u8,slot0:u16,itemId:u16,num:u16`，再接 `MakeItemInfo` | add/update/delete；`MakeItemInfo.itemId=0` 表示删除 |
| S→C `/15 op=0/7` | `op:u8,slot0:u16,num:u16,success:u8,[error:string]` | 当前 Bag 无丢弃/出售入口，只解析失败反馈，不暴露控件 |

服务端证据：

- `protocol.h`：`PRO_ROLE_PACKAGE=8`、`PRO_UPDATE_PACK=15`。
- `pack_deal.cpp`：`GetPackage`、`UpdatePackage`；使用字段为 slot、num、target，整理 op=6。
- `user.cpp`：`MakePack` 全量和 `MakePack(item,pos)` 增量；新增 op=1，更新/删除 op=2。

Cocos 证据：

- `LuaNetSendMsg:SendItemUseReq` 写入 `op=1,slot0,num,target`。
- `LuaNetRecvdMsg.DealMsgPackageList` 解析 `/8`。
- `LuaNetRecvdMsg.DealMsgUpdatePackage` 解析整理、失败与单格增量。
- `KaPaiBagSubUI:UseBtnClicked` 按 `NXuanYiBox/use_type/use_jump` 分派。

Unity 边界：

- Lua `BagController` 唯一负责发包、解析 `/8`/`/15`、等待权威回包和清除 pending。
- C# `BagStore` 只保存已确认物品；不得在点击后预测扣除。
- C# `BagPresenter` 和弹窗 Presenter 只渲染配置并把真实 Button 事件回调给 Lua/C#入口。
- 断线、返回、重连、切号统一关闭 Bag 全部弹窗、清 pending 和选择；重连/重新登录后必须重新请求 `/8`。

### 控件与页面实现

- `BAG-01..07`：真实主入口、一级关闭/页签、五列动态格、可滚动列表、详情和按类型分派的唯一使用按钮。
- `BAG-08..11`：复用 `EnterNumLayer.prefab`，数字 0..9、删除、确认、关闭；最大值 `min(持有数,200)`，0 确认不发包。
- `BAG-12..20`：复用 `OpenBox_1Layer.prefab`，动态候选单选、列表滚动、±1/±10、确认、关闭、候选图标详情；数量范围 `1..min(持有数,100)`。
- `BAG-21..24`：复用 `huoqutujing.prefab`，关闭、按物品类型详情、来源列表和来源动作；目标模块内部控件不计 Bag。
- `BAG-25..26`：复用 `zhuangbeiInfo.prefab`，嵌套关闭和详情纵向滚动；关闭只退一层。
- FirstClassBg 顶部货币/体力加号继续由 Foundation 负责。
- 出售、合成、批量出售、扩容继续隐藏，不生成空壳。

### 资源语义

- 普通物品/礼包候选使用当前 `item_dat.lua` 的 `pic/quality/name/des` 和真实 ItemIcon Sprite。
- 装备碎片来源图标按配置目标打开真实装备信息 Prefab，不用普通道具说明或静态占位替代。
- Bag 当前无 Imod/CSB Timeline 播放调用；本模块不新增伪动画。
- 列表统一 `ScrollRect -> Viewport(RectMask2D) -> Content`，刷新后夹紧 offset，拖动不得误选。

### G3-G6 验证设计

- G3：26 个路径全部绑定真实 Prefab；编译、实例化、滚动结构、排除项隐藏、Console 严重异常通过。
- G4：真实 Button 覆盖全量、增量新增/更新/删除、整理、普通/批量/任选使用、无选择、空数量、非法/重复、断线、重拉、重连、返回、持久化和切号清理。
- G5：按 G1 冻结的 16 个代表性视觉状态采集同账号同数据 Unity 原图，生成逐状态并排、50%叠加、增强差异，并由代理逐图复核；G6真人验收独立进行。
- G6：矩阵 26/26 的 `realEntryClick/automationPassed/manualPassed/status` 全部达标；真实入口 Runner、严重异常、16/16 Python UI、两次正式 `BuildBatch` 幂等、文档与 Git 范围检查通过。

## 2026-08-27 当前 G4-G5

- G0-G3及早期真人Play已在本轮前序通过；以下G4-G5均来自当前修复后的最终输入。
- G3：标准 `Run-UnityFixedAccountValidation.ps1 -Module Bag -G3RuntimeOnly` batch通过；固定账号`1/1000001`，原生`1334×750`，28项、28按钮、26控件绑定、3/3滚动与奖励弹窗生命周期通过。证据：`.local/unity-validation/bag-g3-runtime-latest.json`。
- G3实现未改任何Prefab；已删除 `RewardPresenter` 对导入 `ItemList` 的运行时anchor/pivot/anchoredPosition覆盖，用户布局保持资源原值。
- 早期真人Play：`.local/unity-validation/bag-early-user-play-latest.json`记录`userParticipated=true`、反馈“通过”；该记录仅满足G3早测，不替代G6最终确认。
- G4：标准Full通过26控件、18语义，明确断言1111初始3、真实使用2后剩1且4621增加2；ItemType=6弹窗精确验证仅含权威选择奖励`4621×2`并由真实EventSystem关闭；512/513/514真实扣除、权威奖励与完整弹窗通过。
- G4网络与数据：覆盖异常、断线重连、重登持久化、切号清理；背包哈希保持精确，体力只归一化合法的360秒被动恢复；整库恢复到基线SHA，Fixture残留0。
- G5：中央16状态证据通过；最终三张联系表逐图复核完成，`agentAccepted=true/userParticipated=false`。三种Unity完整奖励弹窗是用户要求的intentional delta；证据目录`.local/ui-fidelity/Bag/compare/g5-20260827/`。该代理审图不是G6真人确认。
- G6首次最终真人Play反馈“礼包无法所有滑动，其他OK”。根因是运行时ListView虽有8项溢出，但视口无raycastTarget拖拽表面，旧G4只程序设置横向normalizedPosition。现已增加透明拖拽表面，并把G4升级为真实EventSystem横拖且Content必须位移；修复后G4 Full与G5受影响状态均通过，用户单点复测“测试通过”。
- 两次真实`BootstrapSceneBuilder.BuildBatch` SHA-256均为`7F2EAE1CF7959AF29A59A610816EEA96698A001CDF630E6DB4DD9B5CC008326E`；操作账本未解决0，Fixture残留0。

## 2026-08-21 已失效重验（仅用于问题追溯）

- 当前前端、服务端、配置与资源审计：`.local/unity-validation/bag-g0-source-audit-20260821.md`。
- 当前协议证据：`.local/protocol-evidence/bag-g0-8-20260821.md`、`.local/protocol-evidence/bag-g0-15-20260821.md`。
- 当前Unity固定账号夹具：`tools/unity-migration/Invoke-BagSqliteFixture.ps1`，整库快照/恢复并准备不可用、跳转、直接使用、批量使用、任选礼包、重复槽聚合、510-514及超过一屏状态；旧MySQL Cocos夹具只保留为历史对照。
- 数据恢复合同：Setup 前完整快照 `role_info` 与所属 `user_info` 分片行；Fixture同时将`package`与`user_spirit=50/当前时间戳`冻结，保证体力丹10个真实使用不受用户原体力漂移影响；重登录时`package`逐字节一致，`user_spirit`只允许按360秒周期合法被动恢复；finally整库恢复、重登录业务哈希一致、备份残留0。
- 当前已确认的 Unity 缺口：旧入口、同 itemId 未聚合、页签与详情图标 Runner 只查节点不点按钮、来源动作统一关闭并显示开发占位、G4/G5 输出目录硬编码旧日期。
- 当前配置差异：Cocos `item_dat.lua` 把 `1111` 定义为八选一 `type=6`，服务端 `item.json` 仍为 `type=5`；本地测试路径在 `pack_deal.cpp` 对 `1111..1113` 做了受控目标奖励兼容。Unity 必须按 Cocos 显示候选、按服务端权威回包刷新，禁止客户端预测奖励。
- 当前 G1 证据：`.local/unity-validation/bag-cocos-baseline-latest.json` 已冻结16个状态；复用与失效清单见当前manifest及`.local/ui-fidelity/Bag/cocos/g1-20260821/reuse-manifest.json`。
- G2：入口闭包、共享协议所有权、配置到资源闭包、运行时 Transform/缩放/锚点均已冻结；已知差异仅保留可追溯模块级处理。
- 旧G3-G4固定账号Runner、15/15语义与事务结论未覆盖当前随机装备盒分母，不能作为当前G4证据。
- 旧G5报告与26/26人工验收不能作为当前视觉或真人确认；当前G5只认`.local/ui-fidelity/Bag/compare/g5-20260827/`。
- 旧G6构建SHA、矩阵完成态与复盘只能用于诊断；当前唯一待办是最后相关变更后的G6用户真人确认。

## 已失效历史（仅用于问题追溯）

- 以下逻辑、Unity 运行与完成结论均来自 2026-07-27 或更早，不能作为本轮 G2-G6 通过证据。Cocos 原生截图中与当前源码、资源、账号、可见夹具和分辨率指纹一致的状态，经 2026-08-21 用户明确批准后可作为本轮 G1/G5 视觉基准复用；复用清单见 `.local/ui-fidelity/Bag/cocos/g1-20260821/reuse-manifest.json`。
- Steam SQLite S5 曾记录协议字节一致，但不代表当前 Unity UI、真实按钮、当前入口或当前构建通过。
- G0 静态闭包经 G1 反向审计补齐为 26 项真实控件，矩阵覆盖入口、页面、弹窗、列表/滑动、嵌套装备信息、成功/失败和生命周期计划。
- G1 使用固定账号从真实主界面入口采集当前 Cocos 原生 `1334×750`：29 张原始图，26 个接受状态，3 张诊断图排除。
- 当前可达链覆盖一级 Bag、空包/非空包、唯一页签、物品选择、批量数字输入、任选礼包、道具来源、来源跳转及嵌套装备信息。
- G1 未执行有效 `/15` 消耗；成功/失败、增量、整理、重拉、重连、持久化和切号留到 G4。
- 完整证据与逐控件映射：`.local/ui-fidelity/Bag/cocos/g1-20260727/G1_COCOS_EVIDENCE.md`。
- G2 已核对服务端、Cocos、Unity三方字段、配置、Prefab、Lua/C#边界及26控件实现/验证设计；协议草稿为 `.local/protocol-evidence/8.md`、`.local/protocol-evidence/15.md`。
- 非空隔离角色真实渲染 2 组物品。
- `/15 op=6` 整理后 Store 和 UI 保持一致。
- 隔离角色注入 `3201×1` 后使用，收到固定奖励并从背包删除。
- 重新登录确认消耗持久化，缺图 `0`。
- G4 固定隔离账号完成真实 `/8`、`/15`：全量、增量新增/更新/删除、整理、批量/礼包/直接使用、无选择/空数量/非法/重复拒绝、关闭重开、断线重连、持久化和切号清理均通过。
- G5 Cocos/Unity 原图、逐控件并排、50% 叠加、增强差异和人工验收均 `26/26 passed`；证据 `.local/ui-fidelity/Bag/compare/g5-live-20260727/`。
- G6 矩阵 `26/26 complete`，严重异常 `0`，Python UI `16/16`，文档 `29` 模块一致；正式 `BuildBatch` 两次 SHA-256 均为 `B27460DB36051DA396630CFF66EDED1115F3C3CB8148388F9574AA60A92D19AE`。
- 本轮使用的是可逆本地隔离夹具，不是正式服或生产数据；G6 后恢复固定角色的原背包与体力基线。

## 当前收口

- 本模块当前G0-G6通过。G4标准SQLite Full完成26/26控件、18/18语义、真实`/8`与`/15`、ItemType 5/6奖励弹窗、网络/持久化/切号及精确恢复；G5当前16/16视觉通过；G6由用户在滑动修复后最终确认。
- Bag已收口；下一模块必须重新读取当前状态、矩阵、manifest和操作复盘，从G0串行推进。
