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
- 最终基准固定 Windows `100%` 显示缩放、原生 `1334×750`；旧 `150%` 下实际 `889×500` 再放大的截图全部降级为历史参考。
- 固定账号 `userId=7200057`、角色 `1000078/U00057`、神将 57 苏全忠。有效 Cocos 基准覆盖阵容首页、神将背包、布阵弹窗、换阵后和恢复后五个状态。
- 对应 Unity 图、并排图、50% 叠加图、差异图、SHA-256 和全帧指标位于 `.local/ui-fidelity/Hero/unity/`、`.local/ui-fidelity/Hero/compare/`。五组 RGB MAE 分别为 `5.153 / 4.259 / 13.190 / 13.015 / 12.983`；指标包含同一 Imod 的不同动画帧、字体采样和 Cocos 实时跑马灯，不单独作为通过判定。
- 已修复：三货币公共层、5 个阵容槽、真实头像/品质框/技能图和技能文本、中央与弹窗 Imod、神将/碎片页签、阵法图标/属性/消耗/材料、弹窗标题/遮罩、截断重叠、红点和占位文图。
- 逻辑门禁：`/24 → /48`、阵位 `1→2→1`、回包后重拉权威快照、独立 Unity 进程重连持久化、非法 `hero=65535` 拒绝且阵位不变均通过；日志为 `unity-hero-validation.log`、`unity-hero-bag-validation.log`、`unity-formation-popup-validation.log`、`unity-formation-invalid-validation.log`。
- 换阵后与恢复后均已取得 Cocos/Unity 同路径原生对照。此前所谓登录循环是把追加日志跨进程记录和启动早期截图误判为单进程循环；正确做法是等待 `40-45` 秒稳定帧并以客户区 `PrintWindow flags=2` 捕获。
- 换阵补证修复：`HeroPresenter.ItemCount` 恢复为神将实际数量；`FormationPopupPresenter` 按首个非零战斗阵位和阵法网格映射挂载 Imod，换到位置 2 后模型不再消失。
- G6：`Run-UnityModuleValidation.ps1 -Module Hero -UserId 7200057 -NoStartServices -KeepServices -SkipPythonTests` 通过并恢复 `1→2→1`；16/16 Python UI 通过；Bootstrap 两次 SHA-256 一致为 `2041B981D9A85C45A8080447E8D92CAB282C2D8C3E8C6BD8E51752C038A1031C`；严重异常 0。状态升级为 `visual-1to1-complete`。

## 遗留

- 当前完成“Lua 权威业务状态 + C# 渲染镜像”试点；`HeroPresenter` 的节点绑定、VirtualList 和 Imod 保持为 Unity 平台渲染适配，不回收为业务权威。
- 允许把本流程推广到一个相邻模块试行，首选装备/法宝；禁止多模块并行或批量 C#→Lua 重写。
- 神将培养/进阶/技能/图鉴。
- 法宝强化/炼化、装备精炼/觉醒/神铸、合成、分解、回收、完整属性模型。
