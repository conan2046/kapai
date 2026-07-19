# 装备与法宝

## 当前结论

- 状态：`partial-interactive-audit-required`。
- `/319`数据、穿脱、强化和异常诊断有历史通过证据，但尚未按新标准证明全部可见入口、详情、更换、强化按钮均由玩家真实点击闭环。
- G0-G3历史取证/实现可复用；G4-G6必须按完整控件矩阵重做。

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

核心CSB：`zhuangbeibeibao`、`zhuangbeigenghuan`、`zhuangbeiInfo`、`zhuangbeiyangcheng`、`zhuangbeiqianghua`。

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

## 视觉证据与缺口

当前保留的关键列表对照：

- `.local/ui-fidelity/HeroEquip/cocos/05-equipment-bag-seeded.png`
- `.local/ui-fidelity/HeroEquip/cocos/06-fabao-bag-seeded.png`
- `.local/ui-fidelity/HeroEquip/compare/`

旧Runner曾误删冻结Cocos基准；详情、弹窗、穿脱、强化、失败态必须重新取证，禁止复用缺失文件的历史SHA宣称通过。

## 下一步

1. 新建独立 `HERO_EQUIPMENT_CONTROLS.json`，冻结所有入口、按钮、Tab、Item和状态。
2. 从Cocos真实入口逐项补证并重新确认Lua/op/Transform。
3. 审计Unity阵容槽、背包、详情、更换、强化的真实Listener，禁止直接调用Presenter内部方法。
4. 重做G4-G6：成功/失败/重连、双端差异、Runner、人工逐控件和切号清理。

旧全文：`../history/HERO_EQUIPMENT_FULL_2026-07-19.md`。
