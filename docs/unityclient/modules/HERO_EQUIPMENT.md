# 装备（法宝边界回归）

## 当前结论

- 状态：`G0-G2 passed / G3-G6 pending`。2026-08-21 用户确认方案A后，当前分母为14来源/974业务ID/86控件。合成目标解析与先扣料风险已修复；服务端输入变化使旧G1失效后，已用Computer Use仅重拍受影响的装备碎片态并重新冻结13态，当前碎片SHA为`FB2219AD3DB7EEED81858C8BAB6F9C83C8300A45D6F018FB4A48DD76DE6BE443`，Fixture恢复、重登哈希和残留均通过。
- 完成主体仅为 `主界面 → btn_chuandai → tankuang2/btn_zhuangbei → 装备`。Hero、Bag、HUD、HuiShou只做影响回归；法宝只做兄弟入口、5..6槽和共享`/319`游标隔离，不计入本模块完成率。
- 当前G0机器分母：`HERO_EQUIPMENT_COVERAGE.json`登记14个源码/配置来源、974个来源记录；控件矩阵登记86项。新增的40项来自真实链 `PetEquipPiecesSubUI:GetBtnClicked → item_dat(4605..4644).item_source`，另有7项品质精炼倍率及4项精炼材料ID 610..613；不得用较小分母替代。
- G1实机发现：勾选“隐藏已穿戴”后计数与空态文案已切到空态，但四张旧装备卡片仍残留；这是Cocos当前真实显示缺陷，G5必须分别断言计数/空态和不应残留的旧卡片。装备碎片40个“获取”入口均有`item_source={{17}}`，不存在可由本模块真实控件打开的“碎片空来源弹窗”，因此不伪造`source-empty`视觉状态；空来源装备模板仍保留为配置/安全失败覆盖。
- G2已完成所有权裁决：新增Unity精炼51、觉醒60、神铸155及大师100条服务端权威JSON；客户端神铸150级仅保留为Cocos显示边界。五次强化、自动精炼、Imod 1..9及外部事务重登oracle纳入G3实现合同；源Prefab内一键兑换/一键升星/一键升阶/一键升层四入口均为`m_IsActive=0`且`BtnStateCheck()`为空，对应弹层不可达，Unity必须保持隐藏并在G4/G5同时断言“不应显示”。
- 历史装备/法宝批处理、`33/33`控件、`20/20`视觉、MCP、BuildBatch、SQLite/MySQL结果全部只作诊断线索，不计入2026-08-21后的任何门禁。

## 当前批次范围

- `btn_chuandai`展开/收起、`btn_zhuangbei`真实入口。
- 装备背包、碎片、详情、更换、来源及回收边界入口。
- 穿戴、替换、卸下、合成、分解、一次/五次/全身强化、精炼、觉醒和神铸。
- 神将详情1..4装备槽，以及`/70`神将属性、`/18`HUD总战力和Bag资源变化。
- 动态列表正常/空/锁定/选中/禁用，成功/失败/边界、返回/重进、延迟多推送、重连、切号和恢复清理。

排除：法宝完整业务；HuiShou目标页内部业务。排除依据为用户2026-08-21确认方案A，排除项仍须完成边界和共享状态回归。

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

主操作协议为 `/319 PET_EQUIP_OPERATE`；所有会改变出战神将属性的成功操作还会触发服务端主动推送 `/70 PRO_UPDATE_PET_INFO`。两条协议共同构成本模块事务闭包。

| op | 用途 |
|---:|---|
| 1/17 | 装备/法宝列表 |
| 2/3 | 装备穿戴/卸下 |
| 4 | 装备强化 |
| 16/22 | 装备/法宝增量 |
| 18/19 | 法宝穿戴/卸下 |

关联推送：

| 协议 | 服务端来源 | 客户端责任 |
|---:|---|---|
| `/70 PRO_UPDATE_PET_INFO` | `WearPetEquip/TakeOffPetEquip/StrongEquip/WearFaBao/TakeOffFaBao → CUser::UpdateZhenFaPetInfo → UpdatePetInfo → SendPetUpdateInfo` | 按原 Cocos `DealUpdatePetInfo` 字段顺序更新目标神将属性、气血和战力；不得只刷新装备槽或强化等级 |
| 玩家总战力增量 | `UpdatePetInfo → SendUpdateInfo(EUUT_TotalZhanDouLi)` | 继续由 Player/HUD 所有者消费，HeroEquip 验收必须断言其最终变化与重登一致 |

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
| 装备碎片 | `zhuangbeisuipian` / `suipianUI/{Bag,Btn_huoqu,Btn_hecheng,recycle}` | 40类碎片、来源、合成和回收边界；Bootstrap旧法宝碎片Prefab路由必须在G3修正 |

配置冻结为装备44、合成40、强化240、精炼51、品质精炼倍率7、精炼材料610..613共4项、觉醒60、神铸客户端150/服务端与Unity 155、大师4类×25级、碎片来源40条。Unity `equip_jinglian/equip_juexing/equip_shenzhu/master/quality/item.json` 与服务端事务源逐字节一致；精炼所需经验按`equip_jinglian.exp × quality.jinglian_ratio / 10000`计算，材料必须为type=4并读取sub_value经验。装备图按 `ResourceService.LoadEquipmentIcon` 从 `ItemIcons/<pic>`、`ItemIcons/equip<pic>` 回退加载；法宝图严格从 `FaBaoIcons/<pic>` 加载，缺图必须计数，不得跨资源域顶替。

### G2 权威与生命周期规则

1. `LegacyEquipmentModel.lua.txt` 是角色装备/法宝权威；C# Store 仅为完整 Lua 快照的渲染镜像。
2. 列表分包未完成时不得发布半包；op2/3/4/18/19 失败时不得先改 C# Store。
3. op16/op22 主动增量先 upsert Lua，再发布镜像；op4 成功不得自行推算强化等级。
4. 装备入口与重连必须先请求`/8`并由`BagController`完整提交`BagStore`，再请求op1+op17；切号调用 `EquipmentController.reset()`，同时清空 Lua、待处理分包、错误文本和 C# Store。精炼缺少权威材料快照时不得回退发送`610×1`。
5. 主界面入口、阵容槽、列表行、弹窗、强化都必须通过真实 Button Listener；Runner 禁止直接调用 Presenter 私有方法。

G2静态审计已完成，但不借用历史实现结论。G3必须以矩阵`sourceAudit.knownGaps`为实现清单：补`/8→/319`权威材料快照顺序、碎片可合成优先排序、op11..16与op24/26、完整失败回包、跨阵位双方刷新、卸下fpos校验、装备碎片Prefab路由、源端隐藏控件负向覆盖，以及两阵位可逆Fixture。完成前G3保持pending。

### 历史 G3 Unity MCP 验证（仅诊断；当前 G3 证据见本节结论）

- Unity 2022.3.62f3c1 经 MCP 强制刷新脚本，编译错误 0。
- MCP 执行 `Force Rebuild Bootstrap Scene` 后，场景包含装备背包、详情、更换、培养、强化、法宝碎片六个真实 View；节点数分别为 41、99、40、49、34、36。
- PlayMode 中 `ProjectXApp` 六个 View 引用均非空，`HeroEquipmentPresenter` 可初始化；装备、法宝及只读碎片页可打开。
- 运行时 Console 为 0 error / 0 warning。证据：`.local/unity-validation/hero-equip-g3-mcp-evidence.md`。

### 历史 G4 联机功能验证（仅诊断，不计入当前门禁）

- 固定账号 `7200057 / roleId=1000115`，全部 Unity 操作由 MCP 触发真实 `Button.onClick` Listener。
- 装备：素心刀强化 `3→5`，卸下 `1→0`、重穿 `0→1`；另一件装备的普通强化验证修复后不再自动进入测试卸下链。
- 法宝：UID `2121072641` 卸下 `1→0`、重穿 `0→1`。
- 失败态：金币镜像置 0 后真实强化按钮返回“您的金币不足！”且等级保持 5；临时非法 UID `4294967295` 通过真实更换按钮发送后返回“参数错误”，真实装备状态不变；法宝卸下按钮连续两次点击，第二次返回“已经装备”。
- 断服后观察 `NetworkState=Faulted`，重启服务并重连到同角色；正常退出 PlayMode 触发保存、重启服务并同账号重登后，装备阵位 1、强化 5、法宝阵位 1 均由 `/319 op1/17` 权威回读恢复。
- 设置页真实切号链验证清理：切换前装备/法宝 `4/2`，切换后 `0/0`、网络 `Disconnected`、登录页恢复。
- G4 发现并修复两处协议控制流根因：普通强化不再无条件进入自动化卸下/法宝链；法宝穿戴失败包不再读取成功包才存在的 `replacedUid`。证据：`.local/unity-validation/hero-equip-g4-mcp-evidence.md`。

### 历史 G5 双端视觉验收（仅诊断，不计入当前门禁）

- 固定账号 `7200057 / roleId=1000115`、原生 `1334×750`，Cocos/Unity 原图与 comparison set 均 `20/20`。
- 装备/法宝背包、帮助、详情、更换、碎片、强化、材料不足、非法 UID、重复操作和穿脱恢复人工验收 `20/20 passed`。
- 同账号后续真实操作导致强化等级/战力高于早先 Cocos 基准，只接受权威状态演进；空白资源、错误层级、截断和错误反馈均未豁免。
- 证据：`.local/ui-fidelity/HeroEquip/compare/g5-live-20260726/manual-acceptance.json`、`.local/unity-validation/hero-equip-g5-mcp-evidence.md`。

### 历史 G6 控件与最终硬门禁（仅诊断，不计入当前门禁）

- 控件矩阵 `33/33 realEntryClick / automationPassed / manualPassed`；装备碎片、回收、法宝碎片动作、深层培养和五次强化按本批排除要求隐藏或禁用。
- Unity MCP 本轮真实补跑主入口、帮助、筛选、列表、培养、碎片、六槽、详情、更换、强化选择/单次/关闭；单次强化 UID `2121072641` 权威刷新 `8→10→12`。
- 最终装备 `4`、法宝 `2`、缺图 `0`、严重异常 `0`、Console `0 error / 0 warning`。
- `BootstrapSceneBuilder.BuildBatch` 连续两次 SHA-256 均为 `188BFD6307DFB0B0F195596D94E95ACE2E103343B8C28057F8AD5A13F580CACB`。
- 证据：`.local/unity-validation/hero-equip-g6-control-runner.json`、`.local/unity-validation/bootstrap-idempotence-latest.json`。

### 2026-08-20 `/70` 与法宝卸下顺序修复记录

| 项目 | 记录 |
|---|---|
| 修改函数 | `CEquipManeger::TakeOffFaBao`；Unity `HeroController.readPetUpdate`、`LegacyFormationModel.ApplyPetUpdate`、`ProjectXApp.CompleteHeroEquipmentMutationValidation` |
| 修改前行为 | 服务端法宝卸下时先调用 `UpdateZhenFaPetInfo` 推送 `/70` 与玩家总战力，再将 `fabao->fpos/wpos` 清零；最后一轮英雄属性和主界面战力仍是穿戴态。Unity此前又未消费 `/70`，只能刷新装备槽。 |
| 原始证据 | `server/src/pet_equip_manage.cpp::TakeOffFaBao`、`server/src/user.cpp::UpdateZhenFaPetInfo/UpdatePetInfo/SendPetUpdateInfo`、`client/ProjectX/src/NetWork/LuaNetRecvdMsg.lua::DealMsgUpdatePet`。G4 实测 `/70=10, changed=True, heroRefresh=False, hudPower=False`。 |
| 修改后行为 | 服务端保存旧阵位/槽位，先清空法宝穿戴状态，再重算阵容属性并推送；Unity按原 Cocos字段宽度消费 `/70`，更新英雄属性、当前气血和战力镜像，玩家 `/18` 总战力仍由 Player/HUD 所有者消费。 |
| 数据来源 | `/319 PET_EQUIP_OPERATE` op18/19；主动推送 `/70 PRO_UPDATE_PET_INFO`；玩家更新协议中的 `EUUT_TotalZhanDouLi(513)`。 |
| 影响 | 法宝卸下后的英雄属性、英雄战力和主界面总战力与真实未穿戴状态一致；同时修复 Cocos 与 Unity 共用服务端的错误推送顺序。 |
| 风险 | 仅调整成功卸下法宝后的清状态/重算先后；失败分支、线上协议结构和存档格式不变。 |
| 回滚 | 还原 `TakeOffFaBao` 中 `fpos/wpos` 清零位置，并撤销 Unity `/70` 注册与消费；不涉及数据库结构。 |
| 验证 | 固定账号夹具完整备份 `role_info` 与 `user_info` 分片；G4 必须断言 `/70` 至少 5 次、属性发生变化、最终英雄三项与 HUD 总战力恢复、重登哈希一致、残留 0。 |

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

当前冻结基准为固定账号`7200057/1000115`、原生窗口裁切`1334×750`，登记在`.local/unity-validation/heroequip-cocos-baseline-latest.json`，共13态：

- `.local/ui-fidelity/HeroEquip/cocos/g1-hero-detail-equipped.png`
- `.local/ui-fidelity/HeroEquip/cocos/g1-wear-popup-open.png`
- `.local/ui-fidelity/HeroEquip/cocos/g1-equipment-bag.png`
- `.local/ui-fidelity/HeroEquip/cocos/g1-equipment-bag-empty.png`
- `.local/ui-fidelity/HeroEquip/cocos/g1-equipment-pieces.png`
- `.local/ui-fidelity/HeroEquip/cocos/g1-equipment-pieces-empty.png`
- `.local/ui-fidelity/HeroEquip/cocos/g1-equipment-detail.png`
- `.local/ui-fidelity/HeroEquip/cocos/g1-strength-before.png`
- `.local/ui-fidelity/HeroEquip/cocos/g1-refine-before.png`
- `.local/ui-fidelity/HeroEquip/cocos/g1-awaken-before.png`
- `.local/ui-fidelity/HeroEquip/cocos/g1-awaken-locked.png`
- `.local/ui-fidelity/HeroEquip/cocos/g1-shenzhu-locked.png`
- `.local/ui-fidelity/HeroEquip/cocos/g1-source-actionable.png`

当前Computer Use账本为`.local/unity-validation/heroequip-cocos-automation-g1-20260821.json`，13个targetId与截图路径均唯一。Fixture最终`restored=true`、`postLoginHash`等于原始`snapshotHash`、`residualCount=0`；旧缺失文件及历史SHA只作诊断。

## Steam SQLite S5（2026-08-20）

- 证据：`.local/unity-validation/steam-sqlite-s5-heroequip-latest.json`。
- 隔离新角色在 SQLite/MySQL 执行相同20-case：`local_test op53`经生产`AddEquip/AddFaBao`新增模板1001，再用真实`/319 op2/4/3/18/19`完成装备穿戴、非法UID拒绝、强化、卸下、法宝穿戴、重复拒绝和卸下。
- 双端运行态均94响应；`/319`各25包、`/70`各12包逐包字节一致，20组结构化语义一致。正常退出后重启均21响应，`/319`与`/70`各2包字节/语义一致，装备保留强化等级且装备/法宝均保持卸下。
- `role_info.pet_equip`仅`m_lastCntTime`随两个服务启动时刻不同；按`CEquipManeger::SaveData`字段边界仅归一该时间戳后结构SHA一致，法宝搜索次数字节一致；`pet/mission/save_data/user_spirit`原始SHA直接一致。隔离MySQL库已删除，生产MySQL全链继续保留。

## 下一步

1. 完成G2中央校验与门禁登记；任何未登记源码/配置/资源ID立即撤回G2。
2. G3只实现`sourceAudit.knownGaps`与86控件合同，并先执行固定账号`-DataPreflightOnly`；不得启动全量Unity后再补Fixture。
3. G4真实EventSystem+独立Oracle，G5同时断言应显示/不应显示；G6自动化通过后仍等待用户最终真实Play确认。

旧全文：`../history/HERO_EQUIPMENT_FULL_2026-07-19.md`。
