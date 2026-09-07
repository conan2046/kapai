# 强化大师模块

> 当前门禁：G0-G6 已通过；固定账号最终 Play 已由用户确认“验收通过”，40/40 控件完成。

## 范围

- 强化大师：装备强化、装备精炼、装备觉醒、装备神铸、法宝强化、法宝精炼六页签。
- 装备养成：强化一次/五次/全身、精炼/一键精炼、觉醒、神铸。
- 法宝养成：8 个材料槽、一键添加、可滚动材料选择、强化、精炼。
- 固定账号：SQLite `userId=1 / roleId=1000001`，两个阵位、两套装备、四件上阵法宝及 12 件低品质法宝材料。

## 权威链路

- Cocos：`QiangHuaDaShiUI.lua`、装备/法宝养成 View、`LuaNetSendMsg.lua`、`LuaNetRecvdMsg.lua`。
- 协议：`/8`、`/15`、`/18`、`/70`、`/319 op1/4/12..27`。
- 服务端：`pet_equip_manage.cpp` 的装备养成、`StrongFaBao`、`JingLianFaBao`、大师检查与推送。
- Unity：Lua 负责请求/解析与权威刷新；`HeroEquipmentStore/FaBaoStore/EnhanceMasterStore` 只保存 Lua 发布的渲染镜像；Presenter 不预测服务端结果。大师等级不再由装备最低等级本地推导。

## 动态加载

- 强化大师、装备养成子页、法宝强化/精炼、材料选择器已移出 `Bootstrap.unity`。
- 使用 `Resources/UiPrefabs/*.asset` 按需实例化；退出账号/辅助页时释放。
- `yingxiongbeibao.prefab` 为用户维护资源，本模块未修改。

## 门禁证据

- G0：40 个控件、10 个源码入口、898 个业务 ID 已冻结。
- G1：当前 HEAD 已重拍14个 Cocos 状态，正式证据目录为 `.local/ui-fidelity/EnhanceMaster/cocos/g1-20260907-recapture-formal/`。
- G2：当前入口/协议/资源审计已完成，覆盖 `/319 op25` 请求、op24/25/26/27 六类型镜像、服务端 op27 分组边界和 C# 只读渲染。
- G3：固定账号真实射线验证通过，40/40 控件覆盖；法宝使用真实模板 `1001/1002`，材料使用真实经验书 `615/616/617`。
- G4：固定账号批验证通过，账号 `1/1000001` 的整库快照、恢复、重登与零残留断言通过。
- G5：14 个同账号同数据 Cocos/Unity 状态完成双端视觉对照，差异报告齐全。
- G6：用户最终 Play 确认“验收通过”；证据 `.local/unity-validation/enhancemaster-final-user-play-latest.json`，自动复盘 `.local/unity-validation/enhancemaster-retrospective-latest.json`。
- G4：固定账号批验证通过，13 个运行态、恢复/清理合同与早期 Play 反馈均已闭环。
- G5：14 个同账号同数据 Cocos/Unity 状态完成对照、并排、叠加和差异报告；证据见 `.local/ui-fidelity/EnhanceMaster/compare/g5/report.json`。

## 早期 Play

- 登录固定账号后：阵容 → 任意已穿戴四装备/两法宝的神将 → 强化大师。
- 依次检查六页签、左右神将切换、去养成按钮、装备四页、法宝两页、材料列表滑动与勾选。
- 当前阶段不设置 `manualPassed=true`；G6 需要用户在当前固定账号构建中确认阵容入口、强化大师六页签、装备/法宝子页和材料选择器均可正常打开。
