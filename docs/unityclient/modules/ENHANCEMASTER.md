# 强化大师模块

> 当前门禁：G0、G1、G2、G3 已通过；等待用户早期 Play，G4-G6 未开始。

## 范围

- 强化大师：装备强化、装备精炼、装备觉醒、装备神铸、法宝强化、法宝精炼六页签。
- 装备养成：强化一次/五次/全身、精炼/一键精炼、觉醒、神铸。
- 法宝养成：8 个材料槽、一键添加、可滚动材料选择、强化、精炼。
- 固定账号：SQLite `userId=1 / roleId=1000001`，两个阵位、两套装备、四件上阵法宝及 12 件低品质法宝材料。

## 权威链路

- Cocos：`QiangHuaDaShiUI.lua`、装备/法宝养成 View、`LuaNetSendMsg.lua`、`LuaNetRecvdMsg.lua`。
- 协议：`/8`、`/15`、`/18`、`/70`、`/319 op1/4/12..27`。
- 服务端：`pet_equip_manage.cpp` 的装备养成、`StrongFaBao`、`JingLianFaBao`、大师检查与推送。
- Unity：Lua 负责请求/解析与权威刷新；`HeroEquipmentStore/FaBaoStore` 只保存 Lua 发布的渲染镜像；Presenter 不预测服务端结果。

## 动态加载

- 强化大师、装备养成子页、法宝强化/精炼、材料选择器已移出 `Bootstrap.unity`。
- 使用 `Resources/UiPrefabs/*.asset` 按需实例化；退出账号/辅助页时释放。
- `yingxiongbeibao.prefab` 为用户维护资源，本模块未修改。

## 门禁证据

- G0：40 个控件、10 个源码入口、898 个业务 ID 已冻结。
- G1：同账号同分辨率 Cocos 14 个状态，固定输入指纹与自动化账本已冻结。
- G2：入口、协议、配置、资源、Prefab、SQLite 夹具审计完成；8 个缺口已在 G3 实现或登记。
- G3：标准 `Run-UnityFixedAccountValidation.ps1 -Module EnhanceMaster -G3RuntimeOnly` 通过；40/40 控件、13 张运行时截图、4 个语义断言，整库恢复与清理断言通过。

## 早期 Play

- 登录固定账号后：阵容 → 任意已穿戴四装备/两法宝的神将 → 强化大师。
- 依次检查六页签、左右神将切换、去养成按钮、装备四页、法宝两页、材料列表滑动与勾选。
- 当前阶段不设置 `manualPassed=true`；收到本轮真实 Play 反馈后再进入 G4。
