# 神将与阵容

## 当前结论

- 状态：`G0-G6 passed / 16/16 complete`。
- 门禁：`G0-G6 passed`；16项真实控件主链、等级锁定拒绝、非法阵位拒绝、权威快照恢复、真实断线重连、双端原图/差异和最终人工视觉均已通过。
- 旧 `visual-1to1-complete` 和旧 G0-G6 结论已撤销，只保留为历史协议/截图证据。
- 当前控件矩阵：`../matrices/HERO_CONTROLS.json`，`16/16 complete`。
- Unity 已由真实 Button 驱动完成16/16项自动验证与截图，并完成真实断线重连复验；同账号 Cocos/Unity `1334×750` 视觉人工验收 `16/16 passed`。

## 范围

- 阵容入口、5个阵位状态、神将选择。
- 空位上阵、锁定阵位、替换、养成、强化大师、详细属性。
- 装备槽1-4、法宝槽1-2的阵容页入口。
- 布阵弹窗、阵位变更、重拉、重连和切号清理。

神将完整培养、进阶、技能培养和图鉴不在当前阵容修复批次；入口可见时仍必须登记并明确隐藏或后置，不能保留空壳。

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
| 阵位变更 | `/48 op=4 + uint16 petId + uint8 pos` | `CHECK_SYSTEM_OPEN(SOT_1030+pos) → ZhenFa_SetPetState` | 先处理成功/失败响应，再强制 `/48 op=1`；禁止本地乐观改位 |
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
- `FormationPopupPresenter`：阵法列表、阵位网格和换位渲染。
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

本模块已收口。按项目规则生成HANDOFF并新开任务后，再从 `UNITYCLIENT_STATUS.md` 选择下一个模块；不得在本任务继续扩展神将培养范围。

## Steam SQLite S5（2026-08-20）

- 证据：`.local/unity-validation/steam-sqlite-s5-hero-latest.json`。
- 隔离新角色在 SQLite/MySQL 执行相同10-case：查询`/24`、`/48`，经生产AddPet奖励链新增神将64，`/48 op4`上阵，非法神将65535拒绝，`/48 op5`成员换位，再次查询权威快照。
- 双端运行态均64响应；`/24`三包、`/48`九包逐包字节一致，结构化语义一致。换位后战斗序列保持`[57,64,0,0,0]`，阵法成员序列为`[64,57,0,0,0]`，按服务端真实语义分别冻结。
- 正常退出后重启，SQLite/MySQL重新登录查询的`/24`、`/48`字节与语义一致；数据库`pet/zhenfa/mission/save_data`四项SHA完全一致。隔离MySQL库已删除，生产`fxl_game_local`、MySQL源码/驱动/构建/Schema/脚本/回归全链路继续保留。
