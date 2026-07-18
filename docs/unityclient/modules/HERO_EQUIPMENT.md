# 神将、阵容、装备与法宝

## 范围

神将列表/详情、阵容位置、装备/法宝列表与增量、穿脱和装备强化。

## 三方证据

- 神将：`/24 op=1`。
- 阵容：`/48 op=1/op=4`。
- 装备/法宝：`/319 op=1/17` 列表、`op=16/22` 增量。

## 实现

- 阵容试点已改为 `Hero/LegacyFormationModel.lua.txt` 保存神将、阵法、展示阵位、战斗阵位和当前选择的权威状态；方法名沿用旧 `LCPet/LCFormation`。
- `HeroController.lua.txt` 复用旧 `LuaNetSendMsg/LuaNetRecvdMsg` 的 `/24、/48` 请求与解析语义，先更新 Lua 模型，再同步 C# 渲染镜像。
- `HeroStore + FormationStore` 暂时只作为现有 `HeroPresenter` 的渲染镜像，不再作为阵容业务权威源；后续通用 Lua UI Bridge 成熟后再移除模块专属镜像。
- `HeroEquipmentStore + FaBaoStore` 处理分包列表与增量。
- `EquipmentCatalog` 读取 `equip.json/fabao.json`。
- Presenter 复用真实神将、装备背包和详情 Prefab。
- 同步 44 张 `petequip_*.png`，资源走 ResourceService。

## 已验证

- 主界面 `btn_zhenrong` 与 `btn_shenjiangbeibao` 分别绑定阵容、神将背包，不再共用错误入口。
- 阵容复用 `yingxiongListLayer + yingxiongInfoLayer`，神将复用 `yingxiongbeibao` 五列卡牌列表；两者挂载 `OneLevelLayer` 公共背景、标题和返回按钮。
- `HeroCatalog` 从 Cocos `hero_dat.lua` 对齐神将 ID、模型/半身像编号和品质；列表与背包加载 `Resources/MonsterBust` 的真实头像/半身像，并显示等级、星级和上阵标识。
- 阵容中央严格复用 Cocos `Utils:CreateAnimModel(AWRD_ITEM_PET, petId, nil, true) → PlayStand(1)`：Unity 从 `Monster/btm{pic}_zd` 加载 Imod，挂到原 `BaseImage/Node`、继承节点 `0.8` 缩放并循环动作 1；资源缺失时才退回静态半身像。
- `local_test` 的 `/88` 零正文公告响应按“无公告”处理，不再在进入主界面后触发 `Packet body underflow` 并把应用切到 Failed。
- 单神将列表、详情和阵位 `1→2→1` 恢复。
- 阵容 `/48 op=4` 只支持上阵/替换，不伪造空卸下。
- 隔离角色装备穿戴、强化 `0→2`、卸下。
- 法宝穿戴到阵位/槽位后卸下。
- 装备、法宝各 1 件，缺图 `0`。
- 2026-07-18：阵容与神将背包分别以 `-projectXHeroValidation`、`-projectXHeroBagValidation` 重验，Unity 均 `exit=0`；阵容中央 Imod 站立动作、背包真实单卡、`/24 → /48`、入口与截图通过，严重异常 0。证据：`build/ui-migration/bootstrap-hero.png`、`bootstrap-hero-bag.png`。
- 2026-07-18 Lua 回归试点：`btn_zhenrong → HeroController → LegacyFormationModel → /24 → /48`，隔离 `userId=7200056`；神将 `57` 完成阵位 `1→2→1` 并由服务端快照确认，Lua 权威状态与 C# 渲染镜像一致。`Run-UnityModuleValidation.ps1 -Module Hero -NoStartServices -KeepServices`、16/16 Python UI 测试、编译和严重异常扫描通过；截图无错误弹窗。
- 阵位变更会伴随旧任务代际的 `/37` 未请求推送；旧 Cocos `DealMsgTaskInfo` 对未知代际 op 静默忽略，Unity 已仅在没有待处理任务请求时保持同一兼容边界，避免错误弹窗覆盖阵容。

## 视觉门禁

- 旧 `.local/cocos-formation-compare.png` 实际为“游戏公告”空框，不是阵容基准，已排除，不得作为视觉通过证据。
- 当前仅完成真实 Cocos Lua/CSB/Imod 调用链取证和 Unity 动态截图；仍缺同账号、同状态 Cocos 阵容/背包有效截图及差异图，因此状态固定为 `logic-validated-visual-pending`。
- 当前 Unity 阵容截图可见问题：武器名/法宝名字/技能描述等占位文字未替换，部分图标和文字内容不正确，顶部公共货币层遮挡阵容内容，文本存在截断/重叠，红点与按钮状态尚未逐项对齐。取得有效 Cocos 截图后必须按节点映射逐项修复，不得把现有截图记作视觉通过。

## 遗留

- 当前仅完成“Lua 权威业务状态 + C# 渲染镜像”试点；`HeroPresenter` 的节点绑定、VirtualList 和 Imod 仍在 C#，尚未完成通用 Lua UI Bridge。
- 神将培养/进阶/技能/图鉴。
- 法宝强化/炼化、装备精炼/觉醒/神铸、合成、分解、回收、完整属性模型。
