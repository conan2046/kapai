# 神将与阵容

## 当前结论

- 状态：`G0-G3 passed / early user Play feedback repaired, retest pending / G4-G6 pending / 16 controls retained`。
- 2026-08-23按当前源码重新冻结原16项阵容控件。`btn_zhenrong → MainUI:PetTouchCallback → EMID_KAPAI_SHENJIANG=1030 → KaPaiPet.PetZhenRongUI`入口闭包、`/24 op1`与`/48 op1/2/3/4/5`权威所有权、配置资源和运行时Transform闭包仍成立。
- 旧G6提交`9baa53fa`之后，`server/src/pack_deal.cpp`、`server/src/user.cpp`、Unity Hero Lua桥和`ProjectXApp.cs`均发生变化；当前24项输入综合SHA-256为`01B1B953CFA8163D8C72BB3905CAA57E5A523F58F955645F2BCA1DFCD2A35FE3`。因此旧Cocos/Unity原图、Runner、人工视觉、固定账号结果和BuildBatch哈希全部只作诊断线索。
- 当前控件矩阵：`../matrices/HERO_CONTROLS.json`，分母保持16项；HERO-16布阵复合控件已补五模型和阵法学习/升级/切换。当前审计证据：`.local/unity-validation/hero-g0-current-source-audit.json`。
- 当前G1：固定账号`7200057 / roleId=1000115`、唯一原生`ProjectX.exe / Cocos Simulator`窗口；16项均由Computer Use采集并裁切为`1334×750`。阵容页当前态为1个已上阵神将、4个空阵位，养成/强化大师/换将、装备槽1-4、法宝槽1-2、详细属性和布阵入口同时可见；关闭按钮已真实返回主界面。冻结证据：`.local/unity-validation/hero-cocos-baseline-latest.json`、`.local/unity-validation/hero-cocos-automation-ledger.json`。
- 当前G2：入口、`/24 op1`、`/48 op1/2/3/4/5`、`/319`与`/320 op27`兄弟边界、8个Prefab（含共享`OneLevelLayer`）、3份配置、动态`PetTableView`以及Lua/C#生命周期均已按当前文件哈希关闭；中央场景已移除误挂的HeroEquip产物并登记8项Hero语义、16控件视觉契约及可逆固定账号夹具。证据：`.local/unity-validation/hero-g2-source-audit.json`。
- 当前G3：固定账号数据预检已完成真实登录、整行恢复和备份表残留0；Unity编译指纹`7B96EF64207ABC598CE20493D9A3F2887D93234F8C09F43ABB867FAA628917BD`通过，当前8个Prefab、Lua协议桥、Hero/Formation Presenter和Bootstrap场景构成可运行初版。证据：`.local/unity-validation/hero-g3-initial-playable.json`。
- 完整神将培养属于后续独立模块；神将背包/碎片属于再后一个独立模块。本轮只回归阵容及其兄弟入口边界，不提前扩展业务分母。当前 Unity 仅有“升级”页初版；“升星/突破/修炼/信息”及共享框架真实页签均未迁移完成。

## 范围

- 阵容入口、5个阵位状态、神将选择。
- 空位上阵、锁定阵位、替换、养成、强化大师、详细属性。
- 装备槽1-4、法宝槽1-2的阵容页入口。
- 布阵弹窗、阵位变更、重拉、重连和切号清理。

神将完整培养、进阶、技能培养和图鉴不在当前阵容修复批次；入口可见时仍必须登记并明确隐藏或后置，不能保留空壳。

### 早期 Play 纠偏（2026-08-23）

- 布阵互换服务端按主角等级校验五个逻辑阵位，实际门槛为 `1/6/15/25/30`。固定 SQLite 角色原为 15 级，点击第4/5位会被 `CUser::ZhenFa_ChangeUnitPos` 拒绝并提示“该阵位未开启”；当前夹具已改为30级，且只更新 `projectx.db`，未修改 MySQL。
- Cocos 养成主界面有五个真实页签：升级、升星、突破、修炼、信息；通过共享框架 `AddTabBtn/SelectTab` 切换。`Button_l/Button_r` 的真实语义是切换前后上阵神将，不是切换培养页。
- Unity 当前左右箭头仍是提示占位，除升级外四个养成页未迁移，因此养成模块不能标记完整。审计证据：`.local/unity-validation/hero-swap-level-cultivation-audit-latest.json`。

## Cocos调用链

```text
UImainLayer_new/ButtonGroup1/btn_zhenrong
  → MainUI:PetTouchCallback
  → OpenFunction(EMID_KAPAI_SHENJIANG=1030)
  → KaPaiPet.PetZhenRongUI
  → yingxiongListLayer.csb + yingxiongInfoLayer.csb
```

布阵：

```text
btn_buzhen → PetZhenRongUI:FormationClicked
  → EMID_SJBUZHEN=1040
  → Pet.PetFormationSubUI
  → shenjiangzhenxingLayer.csb
```

## 权威数据与协议

| 功能 | 请求 | 服务端 | 回包/失败 |
|---|---|---|---|
| 神将列表/详情 | `/24 op=1` | `CPackageDeal::PetOption → CUser::MakePet` | Lua按旧字段顺序解析完整神将列表；未读字节直接失败 |
| 阵容查询 | `/48 op=1` | `CPackageDeal::ZhenFaOption → CUser::MakeZhenFaMsg` | 当前阵法、已学阵法、展示位、战斗位完整快照 |
| 阵法学习/升级 | `/48 op=2 + uint16 zhenfaId` | `CUser::ZhenFaLevelUp` | 服务端校验阵法书与铜钱，成功回传等级；Lua更新权威阵法模型 |
| 阵法切换 | `/48 op=3 + uint16 zhenfaId` | `CUser::SwitchZhenFa` | 仅已学习阵法可切换；成功回传当前阵法ID |
| 阵位变更 | `/48 op=4 + uint16 petId + uint8 pos` | `CHECK_SYSTEM_OPEN(SOT_1030+pos) → ZhenFa_SetPetState` | 先处理成功/失败响应，再强制 `/48 op=1`；禁止本地乐观改位 |
| 布阵互换 | `/48 op=5 + uint8 srcPos + uint8 tarPos` | `CUser::ZhenFa_ChangeUnitPos` | 服务端成功响应后重拉 `/48 op=1`，按权威战斗位快照刷新五个模型；失败保持原位 |
| 装备槽开放条件 | `/320 op=27 + uint16 mapType + uint16 stageId` | 世界关卡查询 | 旧协议回包会消耗 `op=27`，Lua兼容按剩余11字节解析；槽1-4以服务端关卡状态决定锁定 |
| 装备/法宝入口 | `/319` 子流程 | 既有装备/法宝处理 | 本模块只接真实槽位入口，穿脱与失败仍由 `EquipmentController` 权威回包驱动 |

协议草稿：`.local/protocol-evidence/Hero-24.md`、`.local/protocol-evidence/Hero-48.md`。人工核对依据包括 `server/src/pack_deal.cpp`、旧 `LuaNetSendMsg/LuaNetRecvdMsg` 和 Unity `HeroController.lua.txt`，搜索草稿本身不代替字段确认。

Unity数据链固定为：

```text
真实入口 → HeroController.lua.txt
  → /24 op=1 → LegacyFormationModel:ReplaceHeroes
  → /48 op=1 → LegacyFormationModel:ReplaceFormation
  → Bridge发布只读快照 → HeroStore/FormationStore → Presenter渲染
```

旧 Lua/服务端结果是权威，C# Store 只做渲染镜像；选择态可以本地变化，阵位、装备、法宝状态不得提前写入或伪造成功。

## G2资源与 Transform 映射

| 页面 | Cocos资源 | Unity Prefab | 关键节点 |
|---|---|---|---|
| 阵容列表 | `csd/shenjiangyangcheng/yingxiongListLayer.csb` | `.../yingxiongListLayer.prefab` | `PetTableView/Item`、`btn_buzhen` |
| 神将详情 | `csd/shenjiangyangcheng/yingxiongInfoLayer.csb` | `.../yingxiongInfoLayer.prefab` | `Panel_new/addnew`、`Btn_3_1_0`、`Button1/2`、`EquipIcon1..6`、`Btn_xiangxi` |
| 布阵弹窗 | `csd/shenjiangyangcheng/shenjiangzhenxingLayer.csb` | `.../shenjiangzhenxingLayer.prefab` | 阵法列表、阵位网格、关闭与升级区 |
| 详细属性 | `csd/shenjiangyangcheng/shenjiangxiangxishuxing.csb` | `.../shenjiangxiangxishuxing.prefab` | 属性文本、Mask关闭 |
| 获取途径 | `csd/common/huoqutujing.csb` | `.../common/huoqutujing.prefab` | 装备/法宝空槽来源、返回 |

- 神将模型必须继续使用 `CreateAnimModel + PlayStand(1)` 对应的 Imod/`ImodAnimationPlayer` 循环待机，禁止用头像替代。
- 开放条件来自 `function_dat.lua` 的 1045-1048；阵法和升级配置来自 `zhenfa_config_dat.lua`、`zhenfa_level_dat.lua`。
- 16项逐控件实现、成功/失败和重连验证设计只维护在 `../matrices/HERO_CONTROLS.json` 的 `g2Design`，本文不复制第二份实时表。

## Lua/C#边界与生命周期

1. 点击阵容入口后，Lua顺序请求 `/24 op=1 → /48 op=1`；两份快照完成前页面只显示加载/禁用态。
2. C# Presenter只绑定真实 Prefab Transform、展示 Store 快照和发送用户意图；协议字段、排序、阵位 mutation stage 留在 Lua。
3. `/48 op=4` 断线、超时或失败时清 pending，不改本地阵位；重连成功后重新执行 `/24 op=1 → /48 op=1`。
4. `Bootstrap.OnDisconnected` 已调用 `HeroController.reset()`、`EquipmentController.reset()`；G3还必须保证 C# Hero/Formation/Equipment/FaBao 镜像同步清空或不可见。
5. `ReturnToLogin` 已清 Hero/Formation/Equipment/FaBao Store；所有子页、选中 heroId、uid 和弹窗参数必须随切号清除，禁止跨账号恢复。

## Unity代码现状

- `HeroPresenter`：已占用/空/锁定阵位选择、空位上阵、养成、强化大师、替换、6个装备/法宝槽、详细属性、详情渲染与Imod展示。
- `ProjectXApp.EnsureHeroPresenter`：公共关闭和 `btn_buzhen`；子流程接入真实换将、养成、装备/法宝和详细属性 Prefab。
- `FormationPopupPresenter`：五个战斗位Imod、六阵法列表、阵位网格、真实属性/克制/材料/铜钱，`/48 op=2/3`学习升级与切换，以及来源位→目标位的`/48 op=5`互换。
- G3修复了空位选择在 `Render()` 内被首个神将覆盖的问题；空位选择态现在保留到 `Panel_new/addnew`。
- G4主链：同账号 `7200057` 从当前主界面真实入口进入，逐项点击占用/空阵位、上阵、养成、强化大师、替换、6个装备/法宝槽、详细属性、布阵，阵位 `1→2→1` 后权威重拉恢复；结果见 `.local/unity-validation/hero-g4-main-user7200057.json`。
- G4异常：等级1账号锁定阵位拒绝见 `.local/unity-validation/hero-locked.json`；非法 hero `65535` 被服务端拒绝且阵位未变见 `.local/unity-validation/hero-invalid.json`。
- G4重连：停止 `kapai` 后 Unity 观察到真实断线；重启服务并写入手动重连请求后，Unity 完成重新登录、从真实阵容入口重拉 `/24 op=1 → /48 op=1` 权威快照，并再次执行16项真实 Button 链与阵位 `1→2→1` 恢复。结果见 `.local/unity-validation/hero-g4-reconnect-user7200057.json`。
- G5双端采集：用户放宽禁止前台限制后，固定账号 `7200057 / roleId=1000115`、同数据、原生 `1334×750` 已完成 Cocos 16/16 原图、Unity 16/16 原图及全部并排/叠加/差异报告。Cocos 原图在 `.local/ui-fidelity/Hero/cocos/g5-live-20260726/`，比较结果在 `.local/ui-fidelity/Hero/compare/g5-live-20260726/`。
- G5全解锁夹具：等级60、神将57+64、阵位1四件装备 `1001..1004`、两件不同法宝 `1001/1002`，主线覆盖 `10006/10016/10019/10020`；协议穿戴错误0，证据 `.local/unity-validation/hero-g5-fixture-user7200057.json`。Unity 阵容入口已补 `/319 op=1/17` 预取，强化大师在全解锁数据下真实打开，16项 Button 自动化通过。
- G5人工视觉：`16/16 passed`。14项原硬缺陷已修复：主界面公共层、真实装备/法宝图标、候选页残留、养成内容、强化大师、四装备/两法宝独立详情和完整属性弹窗。详见 `.local/ui-fidelity/Hero/compare/g5-live-20260726/manual-acceptance.md`。
- G6机器回归：固定账号 `7200057` 通过 Unity MCP 菜单从真实入口运行16项 Button链，阵位 `1→2→1` 权威恢复；最终结果 `build/ui-migration/bootstrap-app-result.json` 于 `2026-07-26T14:31:28.6502368Z` 成功，Unity原图16/16刷新，严重异常0。纳入 `ChatLayer` 后，正式 `Test-BootstrapSceneIdempotence.ps1` 双批处理于 2026-07-26 22:50 再次通过，两次 SHA-256 均为 `408E3FF9E994AA681B9805AF28F598F2023126E44B00EF55D0BFCACB0C49FEDC`。G6门禁通过。

## 历史有效证据

- `.local/ui-fidelity/Hero/cocos/formation-entry-user7200057-dpi100.jpg`（2026-07-26，当前隔离账号真实入口，原生客户区 1334×750）
- `.local/ui-fidelity/Hero/cocos/g1-*.jpg`（2026-07-26，空阵位/空背包、养成、强化大师失败、换将空态、装备槽锁定、详细属性、布阵弹窗）
- `.local/ui-fidelity/Hero/cocos/g1-locked-row-level1-user7200260.jpg`（等级1隔离角色，2/5/11/15级锁定阵位及“2级开启”拒绝提示）

- `.local/ui-fidelity/Hero/cocos/formation-user7200057-dpi100.png`
- `.local/ui-fidelity/Hero/cocos/hero-bag-user7200057-dpi100.png`
- `.local/ui-fidelity/Hero/cocos/formation-layout-from-formation-user7200057-dpi100.png`
- `.local/ui-fidelity/Hero/cocos/formation-layout-after-move-user7200057-dpi100.png`
- `.local/ui-fidelity/Hero/cocos/formation-layout-restored-user7200057-dpi100.png`

这些文件只能证明对应历史状态，不替代当前16项逐控件复验。尤其 `g1-close-to-main-user7200057.jpg` 显示等级1，而当前同账号服务端/Unity快照为等级60；槽位锁定/来源态也与当前 `/320 op=27` 权威结果不一致。旧全文：`../history/HERO_EQUIPMENT_FULL_2026-07-19.md`。

## 下一步

当前暂停在早期用户Play。用户完成5-15分钟主路径并反馈后，先把反馈写入`.local/unity-validation/hero-early-user-play-latest.json`；阻塞项修复且文件复核、非阻塞项修复或用户接受后，才允许进入G4。G4仍需补齐8项中央语义记录、失败/重连/切号和当前逐控件证据。

## Steam SQLite S5（2026-08-20）

- 证据：`.local/unity-validation/steam-sqlite-s5-hero-latest.json`。
- 隔离新角色在 SQLite/MySQL 执行相同10-case：查询`/24`、`/48`，经生产AddPet奖励链新增神将64，`/48 op4`上阵，非法神将65535拒绝，`/48 op5`成员换位，再次查询权威快照。
- 双端运行态均64响应；`/24`三包、`/48`九包逐包字节一致，结构化语义一致。换位后战斗序列保持`[57,64,0,0,0]`，阵法成员序列为`[64,57,0,0,0]`，按服务端真实语义分别冻结。
- 正常退出后重启，SQLite/MySQL重新登录查询的`/24`、`/48`字节与语义一致；数据库`pet/zhenfa/mission/save_data`四项SHA完全一致。隔离MySQL库已删除，生产`fxl_game_local`、MySQL源码/驱动/构建/Schema/脚本/回归全链路继续保留。
