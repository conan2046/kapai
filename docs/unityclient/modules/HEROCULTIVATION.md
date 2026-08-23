# 神将培养模块 B

> 当前状态：`G0-G1 passed / G2-G6 pending`。

## 当前结论

- 本模块按 2026-08-23 当前 Cocos、服务端和 Unity 源码重新开门禁；模块 A 只作为 `btn_zhenrong → 养成` 入口与返回回归面。
- 历史 Hero/HeroEquip 截图、Runner、SHA、人工结论和完成标签全部禁止复用。
- G0 已冻结并通过：41 项真实控件覆盖升级、升星、突破、修炼、信息五页签及 `Button_l/Button_r` 切换前后已上阵神将；中央文档门禁 30 模块一致、中央工具链 190 项通过。
- G1 已通过：固定身份 `userId=1 / roleId=1000001`，取得 15 个当前 Cocos 原生 `1334×750` 状态，身份、输入指纹、截图 SHA 与自动化账本均按本轮证据冻结。
- 权威业务协议为 `/24`：`op=1` 查询，`op=3` 升级，`op=4` 一键升级，`op=5` 突破，`op=6` 修炼，`op=7` 升星，`op=12` 修炼激活；信息页只读 `/24` 权威快照。
- 测试数据后端唯一允许 `Application.persistentDataPath/LocalServer/projectx.db`；禁止修改或借用 MySQL。

## 范围

### 纳入

- 真实入口：`btn_zhenrong → PetZhenRongUI → Btn_3_1_0 → PetKaPaiMainUI`。
- 共享培养框架：关闭、返回阵容、五页签、标题、神将模型、星级/等级/突破层数/战力和左右已上阵神将切换。
- 升级：四类经验材料、单次升级、一键升级弹窗及数量调整、成功/不足/主角等级上限。
- 升星：当前/下一星级、消耗、属性/技能详情、升星成功与不足。
- 突破：当前/下一突破层、等级与材料条件、详情、突破成功与不足。
- 修炼：属性进度、帮助、材料、单次/一键/指定次数修炼、天命激活及对应成功/不足。
- 信息：基础属性、技能与天赋列表、滚动、详细属性及技能/星级详情。
- 生命周期：关闭重进、断线重连、客户端重启、切号隔离、延迟回包、重复请求与精确恢复。

### 排除

- 阵法学习、阵位互换、神将上阵/替换属于模块 A 回归面。
- 神将背包、碎片合成、图鉴、重生属于后续独立模块。
- 装备和法宝培养属于 HeroEquip。

## 当前源码入口与协议

```text
Layer/Main_UI/ButtonGroup1/btn_zhenrong
  → MainUI:PetTouchCallback
  → EMID_KAPAI_SHENJIANG=1030
  → KaPaiPet.PetZhenRongUI
  → yingxiongInfoLayer/Btn_3_1_0
  → KaPaiPet.PetKaPaiMainUI
  → OneLevelLayer:AddTabBtn / SelectTab
```

`PetKaPaiMainUI` 的页签实现固定为：

| 页签 | Lua 子页 | 服务端权威 |
|---|---|---|
| 升级 | `PetKaPaiLvUpUI` / `PetOneKeyLvUpUI` | `/24 op=3/4` |
| 升星 | `PetKaPaiStarUpUI` | `/24 op=7` |
| 突破 | `HeroBreakUpUI` | `/24 op=5` |
| 修炼 | `PetKaPaiXiuLianUI` | `/24 op=6/12` |
| 信息 | `PetKaipaiInfoSubUI` | `/24 op=1` 只读 |

左右按钮通过 `PetkaPaiManager:getNextPetPos` 与 `LRoleDataMgr.Pet:GetPetByFightPos` 切换已上阵神将，只更新当前展示与五个子页输入，不发送培养协议。

## G0 固定账号与数据需求

- 固定身份：`userId=1 / roleId=1000001`；本轮只读解析当前 MySQL `zhenfa`，确认其已有两名上阵神将 `57/11`，未修改 MySQL；G3 前 Unity SQLite 必须建立同一唯一绑定。
- 至少两名已上阵且属性明显不同的神将，保证左右切换可观察、可往返。
- 角色等级与功能开放数据覆盖五页签；另保留神将等级达到主角等级的失败态。
- 至少一名神将分别具备可升级、可升星、可突破、可修炼、可激活状态；同时保留材料不足和上限状态。
- 经验物品、对应神将碎片/万能碎片、突破材料、修炼丹 `852`、铜钱及协议实际扣除字段必须来自当前配置和服务端源码，不在客户端伪造。
- Fixture 必须在进程全停时对 `projectx.db` 做快照，setup 后登录断言，运行后重登验证，finally 整库恢复并断言 SHA、`integrity_check=ok` 和残留 0。

## G0 验收样例

1. 给定两名已上阵神将，点击右箭头后五页签全部显示后一名神将的权威数据；点击左箭头恢复原神将，不改变阵容和培养数据。
2. 给定可升级神将与真实经验材料，执行升级后只在 `/24` 权威回包到达后刷新等级、属性和材料数量；断线或失败不得本地成功。
3. 给定满足升星、突破、修炼或激活条件的神将，各写操作按服务端结果更新并在重登后保持；finally 恢复原始 SQLite。
4. 给定材料不足、等级不足或达到上限，按钮显示当前 Cocos 对应提示，角色、神将、物品和货币均不变化。

## 下一门禁

G1 已完成当前 Cocos 原生 `1334×750` 基线：五页签、左右往返、关键弹窗、失败、重连和重进共 15 个状态。G2 仅可使用本轮冻结身份、输入指纹和 SHA；任一输入变化均使受影响状态失效。
