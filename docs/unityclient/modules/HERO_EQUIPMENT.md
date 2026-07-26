# 装备与法宝

## 当前结论

- 状态：`G0-G6 passed / 33/33 complete`。
- `/319`数据、穿脱、强化、失败态、重连、持久化和切号清理均已由 Unity MCP 触发真实 Button 闭环。
- 2026-07-26 已新建 `../matrices/HERO_EQUIPMENT_CONTROLS.json`，冻结 33 个真实或必须禁用的可见控件；机器 Preflight 与 DryRun 通过。
- G1 已按固定账号 `7200057 / roleId=1000115`、Windows 100% DPI、原生客户区 `1334×750` 从玩家真实入口重采 20 张 Cocos 基准；覆盖装备/法宝背包、帮助、碎片、隐藏筛选、六槽总览、详情、更换、单次强化前后、材料不足、非法 UID、重复操作、卸下与恢复。
- 材料不足和非法 UID 使用可回滚的临时 Cocos 取证注入触发真实按钮回调；两处 Lua 已恢复到仓库原始字节，源码 `git diff` 为 0。取证结束时四件装备和两件法宝均恢复阵位 1，素心刀强化等级为 3。
- G5 已完成 Cocos/Unity 各 `20/20` 原图及并排、叠加、差异、人工逐项验收；强化页补齐真实主角头像。
- G6 控件矩阵 `33/33`，缺图0、严重异常0；`BootstrapSceneBuilder.BuildBatch` 经 Unity MCP 连续两次 SHA-256 一致。

## 当前批次范围

- 神将详情装备/法宝槽入口。
- 装备背包、法宝背包、法宝碎片、共享详情和更换弹窗。
- 装备穿戴、替换、卸下、单次强化和属性刷新。
- 法宝列表、详情、穿戴、卸下。
- 空背包、材料不足、非法/重复操作、重拉、重连、切号清理。

排除：装备精炼、觉醒、神铸、合成、分解、回收；法宝强化、炼化和完整培养；批量操作和复杂属性模型。

## Cocos入口链

```text
主界面装备：tankuang2/btn_zhuangbei
  → MainUI:OnPetEquipButtonClick
  → EMID_KAPAI_EQUIP_BAG=1110
  → PetEquip.PetEquipMainUI/PetEquipBagSubUI

主界面法宝：tankuang2/btn_fabao
  → EMID_KAPAI_FABAO_SYS=1180
  → FaBao.FaBaoMainUI/FaBaoSubBagUI

阵容槽位：btn_zhenrong → PetZhenRongUI → EquipIcon1..6/PosCallBack
  → 1..4装备，5..6法宝
```

核心 Prefab：`UImainLayer_new`、`OneLevelLayer`、`yingxiongInfoLayer`、`zhuangbeibeibao`、`zhuangbeigenghuan`、`zhuangbeiInfo`、`zhuangbeiyangcheng`、`zhuangbeiqianghua`、`fabaosuipianbeibao`。

## 权威数据与协议

统一协议：`/319 PET_EQUIP_OPERATE`。

| op | 用途 |
|---:|---|
| 1/17 | 装备/法宝列表 |
| 2/3 | 装备穿戴/卸下 |
| 4 | 装备强化 |
| 16/22 | 装备/法宝增量 |
| 18/19 | 法宝穿戴/卸下 |

`LegacyEquipmentModel.lua.txt + EquipmentController.lua.txt`保存角色态权威；原始回包先更新Lua，再发布到`HeroEquipmentStore/FaBaoStore`渲染镜像。Bootstrap共享op路由必须只读取一次op。

### G2 请求与响应冻结

| op | 请求体（不含命令号和 op） | 成功/失败响应体（op 后） | 状态规则 |
|---:|---|---|---|
| 1 | 无 | `total:u16`；非空再跟 `packetCount:u8, packetIndex:u8, itemCount:u8, equipment[]` | 最后一包才替换 Lua 装备表 |
| 17 | 无 | `total:u16`；非空再跟 `packetCount:u8, packetIndex:u8, itemCount:u8, fabao[]` | 最后一包才替换 Lua 法宝表 |
| 2 | `fpos:u8, uid:u32` | 原请求字段后追加 `success:u8, message:string` | 成功后 Lua 更新同部位替换关系；失败不预改 |
| 3 | `fpos:u8, uid:u32` | 原请求字段后追加 `success:u8, message:string` | 成功后 Lua 清除装备阵位 |
| 4 | `uid:u32, type:u8`，本批仅 `type=0` | 原请求字段后追加 `success:u8`；成功再跟 `crit:u8, addLevel:u16, attrCount:u8, (attrType:u16, attrValue:u32)[]` | 服务端先主动推送 op16，再处理 op4 成功结果；渲染必须以 op16 为准 |
| 16 | 服务端主动推送 | `equipment` | 按 UID upsert Lua 装备表 |
| 18 | `uid:u32, fpos:u8, wpos:u8`，`wpos∈{5,6}` | 原请求字段后追加 `success:u8`；成功为 `replacedUid:u32, message:string`，失败仅为 `message:string` | 成功后 Lua 更新槽位并清除被替换 UID；失败不得读取不存在的 `replacedUid` |
| 19 | `uid:u32` | 原请求字段后追加 `success:u8`；失败再跟 `message:string` | 成功后 Lua 清除法宝阵位与槽位 |
| 22 | 服务端主动推送 | `fabao` | 按 UID upsert Lua 法宝表 |

装备记录固定为：

```text
uid:u32, templateId:u16, fpos:u8, jlExp:u32,
cultivateCount:u8, (type:u8, level:u16)[],
baseAttrType:u16, baseAttrValue:u32,
重复4组：(cultivateType:u8, attrCount:u8, (attrType:u16, attrValue:u32)[])
```

其中装备 `wpos/part` 不在回包内，由 `equip.json[templateId].part` 补齐。

法宝记录固定为：

```text
uid:u32, templateId:u16, fpos:u8, wpos:u8, qHExp:u32,
cultivateCount:u8, (type:u8, level:u8)[]
```

字段依据：Cocos `LuaNetSendMsg.lua:5901-6073`、`LuaNetRecvdMsg.lua:1905-2415,5881-5958`；服务端 `pack_deal.cpp:25295-25383`、`pet_equip_manage.cpp:840-858,1204-1211,1701-1767,2083-2431`。搜索草稿保存在 `.local/unity-validation/hero-equip-g2-protocol-evidence.md`。

G2 同时修正 `Invoke-ProtocolSmoke.ps1` 三个旧错误负例：装备穿戴/卸下补 `fpos:u8`，装备强化补 `type:u8`，不再用错位或短包冒充合法异常验证。

### G2 Prefab、控件与资源冻结

| 页面 | Unity Prefab / Transform 根 | G3 必须接线 |
|---|---|---|
| 主界面入口 | `common/UImainLayer_new` / `Layer/Main_UI/tankuang2/btn_zhuangbei,btn_fabao` | 真实 Button → Lua `EquipmentController.open(1/2)` |
| 公共框架 | `OneLevelLayer` / `Layer/Panel_12/Title/CloseBtn`、`Bg/Btn_ListView/Panel_10/Button1` | 关闭、装备/法宝页签、法宝碎片页签；帮助按钮需按 Cocos 公共层语义补建/绑定 |
| 神将六槽 | `shenjiangyangcheng/yingxiongInfoLayer` / `Layer/EquipUI/Bg/bg/EquipIcon1..6` | 1..4 装备，5..6 法宝；空槽、已穿戴分流 |
| 背包列表 | `zhuangbeibeibao` / `Layer/zhuangbeibeibaoUI/{TableView,ItemList,CheckBox,recycle}` | 行点击详情、装备行培养、隐藏已穿戴；回收必须隐藏 |
| 更换弹窗 | `zhuangbeigenghuan` / `Layer/Popup/{Btn_close,CheckBox,TableView}` + `Layer/ItemList/Item1..2/Btn_yangcheng` | 按部位/未穿戴过滤、穿戴、关闭 |
| 详情弹窗 | `zhuangbeiInfo` / `Layer/zhuangbeiInfoUI/{Popup/Btn_close,zhuangbei/Btn_genghuan,zhuangbei/Btn_xiexia,Info/qianghuashuxing/Btn_qianghua}` | 装备/法宝独立内容；排除培养区隐藏 |
| 强化 | `zhuangbeiyangcheng` + `zhuangbeiqianghua` / `Layer/zhuangbeiqianghuaUI/qianghua/qianghuaxiaohao/{qianghuaBtn,qianghua5Btn}` | 左侧装备切换、单次强化；五次强化隐藏 |
| 法宝碎片 | `fabaosuipianbeibao` / 动态碎片项与 `xunbaoBtn` | 本批只读；合成/寻宝/回收不发包 |

配置冻结为 `equip.json` 44 条、`fabao.json` 53 条、`equip_qianghua.json` 240 级。装备图按 `ResourceService.LoadEquipmentIcon` 从 `ItemIcons/<pic>`、`ItemIcons/equip<pic>` 回退加载；法宝图严格从 `FaBaoIcons/<pic>` 加载。当前资源域含 `ItemIcons` 573 张、`FaBaoIcons` 53 张；缺图必须计入 `MissingIconCount`，不得用另一资源域同名图替代。

### G2 权威与生命周期规则

1. `LegacyEquipmentModel.lua.txt` 是角色装备/法宝权威；C# Store 仅为完整 Lua 快照的渲染镜像。
2. 列表分包未完成时不得发布半包；op2/3/4/18/19 失败时不得先改 C# Store。
3. op16/op22 主动增量先 upsert Lua，再发布镜像；op4 成功不得自行推算强化等级。
4. 重连必须重发 op1+op17；切号调用 `EquipmentController.reset()`，同时清空 Lua、待处理分包、错误文本和 C# Store。
5. 主界面入口、阵容槽、列表行、弹窗、强化都必须通过真实 Button Listener；Runner 禁止直接调用 Presenter 私有方法。

G2 静态审计冻结的 G3 缺口已全部收口：`Show()` 不再自动打开第一条详情；隐藏已穿戴、装备行养成、更换筛选、强化左侧装备选择均接入真实控件；回收、五次强化和排除培养区隐藏/禁用；空槽进入兼容候选；法宝碎片改为只读真实 Prefab；公共帮助接入运行时按钮。

### G3 Unity MCP 验证

- Unity 2022.3.62f3c1 经 MCP 强制刷新脚本，编译错误 0。
- MCP 执行 `Force Rebuild Bootstrap Scene` 后，场景包含装备背包、详情、更换、培养、强化、法宝碎片六个真实 View；节点数分别为 41、99、40、49、34、36。
- PlayMode 中 `ProjectXApp` 六个 View 引用均非空，`HeroEquipmentPresenter` 可初始化；装备、法宝及只读碎片页可打开。
- 运行时 Console 为 0 error / 0 warning。证据：`.local/unity-validation/hero-equip-g3-mcp-evidence.md`。

### G4 联机功能验证

- 固定账号 `7200057 / roleId=1000115`，全部 Unity 操作由 MCP 触发真实 `Button.onClick` Listener。
- 装备：素心刀强化 `3→5`，卸下 `1→0`、重穿 `0→1`；另一件装备的普通强化验证修复后不再自动进入测试卸下链。
- 法宝：UID `2121072641` 卸下 `1→0`、重穿 `0→1`。
- 失败态：金币镜像置 0 后真实强化按钮返回“您的金币不足！”且等级保持 5；临时非法 UID `4294967295` 通过真实更换按钮发送后返回“参数错误”，真实装备状态不变；法宝卸下按钮连续两次点击，第二次返回“已经装备”。
- 断服后观察 `NetworkState=Faulted`，重启服务并重连到同角色；正常退出 PlayMode 触发保存、重启服务并同账号重登后，装备阵位 1、强化 5、法宝阵位 1 均由 `/319 op1/17` 权威回读恢复。
- 设置页真实切号链验证清理：切换前装备/法宝 `4/2`，切换后 `0/0`、网络 `Disconnected`、登录页恢复。
- G4 发现并修复两处协议控制流根因：普通强化不再无条件进入自动化卸下/法宝链；法宝穿戴失败包不再读取成功包才存在的 `replacedUid`。证据：`.local/unity-validation/hero-equip-g4-mcp-evidence.md`。

### G5 双端视觉验收

- 固定账号 `7200057 / roleId=1000115`、原生 `1334×750`，Cocos/Unity 原图与 comparison set 均 `20/20`。
- 装备/法宝背包、帮助、详情、更换、碎片、强化、材料不足、非法 UID、重复操作和穿脱恢复人工验收 `20/20 passed`。
- 同账号后续真实操作导致强化等级/战力高于早先 Cocos 基准，只接受权威状态演进；空白资源、错误层级、截断和错误反馈均未豁免。
- 证据：`.local/ui-fidelity/HeroEquip/compare/g5-live-20260726/manual-acceptance.json`、`.local/unity-validation/hero-equip-g5-mcp-evidence.md`。

### G6 控件与最终硬门禁

- 控件矩阵 `33/33 realEntryClick / automationPassed / manualPassed`；装备碎片、回收、法宝碎片动作、深层培养和五次强化按本批排除要求隐藏或禁用。
- Unity MCP 本轮真实补跑主入口、帮助、筛选、列表、培养、碎片、六槽、详情、更换、强化选择/单次/关闭；单次强化 UID `2121072641` 权威刷新 `8→10→12`。
- 最终装备 `4`、法宝 `2`、缺图 `0`、严重异常 `0`、Console `0 error / 0 warning`。
- `BootstrapSceneBuilder.BuildBatch` 连续两次 SHA-256 均为 `188BFD6307DFB0B0F195596D94E95ACE2E103343B8C28057F8AD5A13F580CACB`。
- 证据：`.local/unity-validation/hero-equip-g6-control-runner.json`、`.local/unity-validation/bootstrap-idempotence-latest.json`。

## Unity实现边界

- 真实Prefab和旧配置机械转换；C#只做配置查询、资源加载、Transform显隐、列表和属性渲染。
- 装备/法宝列表每行两件；更换列表只显示兼容且未穿戴项。
- 详情按穿戴态显示更换/卸下；排除培养入口隐藏或禁用。
- 法宝图使用独立 `FaBaoIcons/<pic>` 资源域，避免普通道具同名覆盖。

## 历史逻辑证据

- 固定角色曾验证装备5、法宝3、碎片6组。
- 装备 `/319 op2 → op4/op16 → op3`、法宝 `op18 → op19` 通过。
- 非法UID、重复穿戴、材料不足、最终重拉、独立重连和切号清理有历史结果。
- 16/16 UI、Bootstrap幂等和严重异常扫描有历史通过记录。

以上只算诊断/局部逻辑证据，不等于新标准下的控件完成。

## G1 Cocos 动态基准

当前冻结基准登记在 `tools/unity-migration/unityclient-modules.json`，关键状态：

- `.local/ui-fidelity/HeroEquip/cocos/g1-hero-detail-equipped.png`
- `.local/ui-fidelity/HeroEquip/cocos/g1-equipment-bag.png`
- `.local/ui-fidelity/HeroEquip/cocos/g1-fabao-bag.png`
- `.local/ui-fidelity/HeroEquip/cocos/g1-strength-before.png`
- `.local/ui-fidelity/HeroEquip/cocos/g1-strength-after.png`
- `.local/ui-fidelity/HeroEquip/cocos/g1-equipment-material-insufficient.png`
- `.local/ui-fidelity/HeroEquip/cocos/g1-illegal-uid.png`
- `.local/ui-fidelity/HeroEquip/cocos/g1-repeat-operation.png`

全部登记图均为本轮现存 `1334×750` PNG；旧缺失文件及历史 SHA 继续只作诊断记录，不计入门禁。

## 下一步

HeroEquip 当前模块已收口；新任务按 `UNITYCLIENT_STATUS.md` 选择下一模块，不在本任务扩展装备深度培养。

旧全文：`../history/HERO_EQUIPMENT_FULL_2026-07-19.md`。
