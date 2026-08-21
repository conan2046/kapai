# 背包模块

## 当前结论

- 当前门禁：`G0-G6 passed / 26/26 complete`。
- 固定账号：`userId=7200057 / roleId=1000115`，Windows 100%，原生客户区 `1334×750`。
- 控件唯一事实：`docs/unityclient/matrices/BAG_CONTROLS.json`，共 26 项。
- 2026-08-21 已按当前源码、入口、账号、夹具和 hard-gate v2 从 G0 逐门禁重验；旧 2026-07-27 Runner、构建 SHA 与完成结论仍只作问题追溯。
- 当前源码提交基线：`6e968f1598249c541d3a908eb70c012434f2df53`；入口必须从 `Layer/Main_UI/ButtonGroup1/btn_Bag` 重新取证。

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
- G5：按 G1 冻结的 10 个代表性视觉状态采集同账号同数据 Unity 原图，生成逐状态并排、50%叠加、增强差异，并对矩阵 26 个控件逐项人工验收。
- G6：矩阵 26/26 的 `realEntryClick/automationPassed/manualPassed/status` 全部达标；真实入口 Runner、严重异常、16/16 Python UI、两次正式 `BuildBatch` 幂等、文档与 Git 范围检查通过。

## 2026-08-21 当前重验

- 当前前端、服务端、配置与资源审计：`.local/unity-validation/bag-g0-source-audit-20260821.md`。
- 当前协议证据：`.local/protocol-evidence/bag-g0-8-20260821.md`、`.local/protocol-evidence/bag-g0-15-20260821.md`。
- 固定账号夹具：`tools/unity-migration/Invoke-BagCocosFixture.ps1`，准备不可用、跳转、直接使用、批量使用、任选礼包、重复槽聚合和超过一屏状态。
- 数据恢复合同：Setup 前完整快照 `role_info` 与所属 `user_info` 分片行；真实使用允许改变 `package`、`user_spirit`、贵族经验等账号状态；finally 整行恢复、重登录哈希一致、备份表残留0。
- 当前已确认的 Unity 缺口：旧入口、同 itemId 未聚合、页签与详情图标 Runner 只查节点不点按钮、来源动作统一关闭并显示开发占位、G4/G5 输出目录硬编码旧日期。
- 当前配置差异：Cocos `item_dat.lua` 把 `1111` 定义为八选一 `type=6`，服务端 `item.json` 仍为 `type=5`；本地测试路径在 `pack_deal.cpp` 对 `1111..1113` 做了受控目标奖励兼容。Unity 必须按 Cocos 显示候选、按服务端权威回包刷新，禁止客户端预测奖励。
- 当前 G1 证据：`.local/unity-validation/bag-cocos-baseline-latest.json` 已冻结 10/10 状态；其中 7 张为用户批准且 SHA/可见输入等价的 2026-07-27 原图复用，3 张为 2026-08-21 新拍的断线、重连、关闭重进。复用与失效清单见 `.local/ui-fidelity/Bag/cocos/g1-20260821/reuse-manifest.json`。
- G2：入口闭包、共享协议所有权、配置到资源闭包、运行时 Transform/缩放/锚点均已冻结；已知差异仅保留可追溯模块级处理。
- G3-G4：固定账号 Runner 成功，26/26 真实控件、14/14 语义断言通过；覆盖 `/8`、`/15` 全量/增量/整理/使用、错误分支、关闭重进、断线重连、持久化、切号和精确恢复，Fixture 残留 0，严重异常 0。
- G5：当前报告 `.local/ui-fidelity/Bag/compare/g5-20260821/report.json` 完成 10/10 状态对照；人工验收 `.local/ui-fidelity/Bag/compare/g5-20260821/manual-acceptance.json` 完成 26/26。允许差异仅为 Cocos 同 `sort_priority` 项的非稳定次序、Cocos 旧长列表基准未实际滚动而 Unity 按冻结矩阵实现真实 ScrollRect、以及 Bag 边界外的 PlayerHud 重连提示。
- G6：矩阵 26/26 complete；两次正式 `BuildBatch` SHA-256 均为 `090ABA5905E35B4E965C16F044DD19F0D7A3F2E4E7C9DE131E6E2ABC8B426CA4`；自动复盘 52/52 已解决，待诊断 0、未解决 0；Computer Use 运行时和固定账号夹具残留均为 0。

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

- 本模块 G0-G6 已完成；后续若 Cocos/Unity 源码、资源、固定身份、夹具、步骤、分辨率或稳定帧输入变化，按门禁输入哈希只失效并重验受影响阶段。
- 下一任务重新从 `UNITYCLIENT_STATUS.md` 选择模块执行 G0；不得把本模块证据外推为其他模块完成证明。
