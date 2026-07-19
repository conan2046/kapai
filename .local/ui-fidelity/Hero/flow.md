# 阵容模块 G0-G6 证据流程

- 环境：Windows 显示缩放 `100%`；Cocos/Unity 原生 `1334×750`，最终证据不做二次缩放。
- 账号：`userId=7200057`，角色 `1000078/U00057`，60 级，神将 57 苏全忠，最终阵位 1。
- 阵容：`btn_zhenrong → MainUI:PetTouchCallback → 1030 → KaPaiPet.PetZhenRongUI`。
- 背包：`btn_shenjiangbeibao → MainUI:PetBagCallBack → 1100 → PetBagMainUI/PetBagPetSubUI`。
- 布阵：阵容页 `btn_buzhen → FormationClicked → 1040 → Pet.PetFormationSubUI`。
- Unity：`HeroController.lua → LegacyFormationModel.lua → /24、/48 → C# render mirror`。

## 有效 Cocos 基准

| 状态 | 文件 | SHA-256 |
|---|---|---|
| 阵容首页/选中态 | `cocos/formation-user7200057-dpi100.png` | `6CDABE151C16502E94F7274C2C600351046F9BC21597F6165538EF1DA64BD3B7` |
| 神将背包 | `cocos/hero-bag-user7200057-dpi100.png` | `4E1AF1355A7D1264A6974EB352D78477F7DD28F2A607A341447ADACFFF5E7687` |
| 从阵容页进入布阵 | `cocos/formation-layout-from-formation-user7200057-dpi100.png` | `20B3A8A1D9434193E0529961AD9FE312B15029B925969F82E02A99C8312187F7` |
| 换阵后（位置 2） | `cocos/formation-layout-after-move-user7200057-dpi100.png` | `941775B376483F5632D3E3E168FA14899E923EA5D8D6B8DE639E8CAED47BFD5E` |
| 恢复后（位置 1） | `cocos/formation-layout-restored-user7200057-dpi100.png` | `74F9721F9D9CEF36E63297AB827DB8FA9056C49794660C5610907AED23EDD068` |

Unity 对应图及 SHA-256 见 `compare/report.json`；并排、50% 叠加、原始差异图位于 `compare/`。

## 门禁结果

- G0-G4：通过。`/48 op=4` 阵位 `1→2→1`，回包后 `/48 op=1` 重拉；独立 Unity 进程重连持久化；非法 hero 65535 被拒且权威阵位不变。
- G5：阵容首页、背包、布阵弹窗、换阵后、恢复后五组双端视觉证据齐全；未解释视觉缺陷为零。
- G6：Hero Runner、非法回包、重连、16/16 Python UI、Bootstrap 两次幂等、严重异常和文档门禁通过。
- 当前状态：`visual-1to1-complete`。允许按同一流程启动一个相邻模块试行，首选装备/法宝。

## 作废规则

- 所有 Windows `150%` 下实际 `889×500` 再放大到 `1334×750` 的历史图作废。
- 主界面直开布阵图不能替代“从阵容页进入”的同路径图。
- 登录、加载、白屏、错误账号、桌面截图、仅凭文件名推断页面均无效。
