# 神将与阵容

## 当前结论

- 状态：`partial-interactive-audit-required`。
- 旧 `visual-1to1-complete` 和旧 G0-G6 结论已撤销，只保留为历史协议/截图证据。
- 当前控件矩阵：`../matrices/HERO_CONTROLS.json`，`0/16 complete`。
- Unity 仅发现公共关闭、已占用阵位选择、布阵入口3个 Listener；均未满足真实入口、异常、重连、自动和人工完整门禁。

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

| 功能 | 协议 |
|---|---|
| 神将列表/详情 | `/24` |
| 阵容查询 | `/48 op=1` |
| 阵位变更 | `/48 op=4` |

Unity当前为 `HeroController.lua.txt → LegacyFormationModel.lua.txt → /24、/48 → C#渲染镜像`。服务端/Lua结果是权威，C#不得提前改阵位或伪造成功。

## Unity代码现状

- `HeroPresenter`：已占用阵位和神将背包卡选择、详情渲染、Imod展示。
- `ProjectXApp.EnsureHeroPresenter`：公共关闭和 `btn_buzhen`。
- `FormationPopupPresenter`：阵法列表、阵位网格和换位渲染。
- 缺失项以机器矩阵为准，不再在本文复制16行控件表。

## 历史有效证据

- `.local/ui-fidelity/Hero/cocos/formation-user7200057-dpi100.png`
- `.local/ui-fidelity/Hero/cocos/hero-bag-user7200057-dpi100.png`
- `.local/ui-fidelity/Hero/cocos/formation-layout-from-formation-user7200057-dpi100.png`
- `.local/ui-fidelity/Hero/cocos/formation-layout-after-move-user7200057-dpi100.png`
- `.local/ui-fidelity/Hero/cocos/formation-layout-restored-user7200057-dpi100.png`

这些文件只能证明对应历史状态，不替代当前16项逐控件复验。旧全文：`../history/HERO_EQUIPMENT_FULL_2026-07-19.md`。

## 下一步

1. 保持Windows 100%缩放，修正Cocos模拟器客户区为原生1334×750。
2. 用当前账号从真实 `btn_zhenrong` 进入，重采16项控件的正常、空、锁定和失败证据。
3. 冻结完整矩阵并通过G0-G2后，才补Unity缺失Listener和子流程。
4. G4-G6必须逐控件真实点击，禁止Runner直接调用内部弹窗或完成方法。
