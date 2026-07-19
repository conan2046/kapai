# 《道友来封神》Cocos 当前版本入口普查

## 结论

- 全仓 605 个 Lua、1909 个交互候选的旧结果已作废，不能作为当前游戏迁移范围。
- 当前产品以 `Cocos Simulator - 道友来封神`、当前 `MainUI` 为唯一入口根，经 `OpenFunction/InitUI` 构建静态闭包。
- `AppDef` 共 126 条配置路由：42 条进入当前静态闭包，84 条为未归属配置，人工证明前不进入迁移清单；未归属不等同于已确认旧代码。
- 当前闭包为 57 个 Lua、312 个交互候选；主界面登记 42 个事件绑定。
- 当前账号 `userId=1/Test01` 已运行到主界面。Win32 系统和 Cocos 窗口 DPI 均已确认是 `96/100%`，无需修改桌面缩放；但模拟器实际客户区仍为 1067×600，未达到 `config.json` 的 1334×750，底部阵容按钮无法取得本轮合规真实点击证据；白屏抓图均已登记无效。

## 产品归属门禁

| 层级 | 进入当前清单条件 | 不满足时 |
|---|---|---|
| 产品 | 当前模拟器配置/窗口标题为《道友来封神》 | 排除 |
| 入口 | 当前 `MainUI` 存在真实事件绑定 | 未归属 |
| 路由 | 从入口代码经 `OpenFunction` 追到 `AppDef.moduleUI` | 未归属 |
| 弹窗 | 从当前闭包代码经 `InitUI` 追达且 Lua 存在 | 当前静态候选 |
| 资源 | Lua 实际加载的 CSB/动态资源存在 | 阻塞，不允许猜替代 |
| 运行 | 当前账号从真实入口点击到达 | 才能标记 runtime-confirmed |

禁止以“目录名像当前功能”“Prefab 已导入”“AppDef 有枚举”“历史别的游戏用过”为纳入依据。

## 机器清单

| 文件 | 内容 |
|---|---|
| `tools/cocos-audit/generated/cocos-current-entry-inventory.json` | 42 条当前静态路由、84 条未归属路由、42 个主界面候选 |
| `tools/cocos-audit/generated/cocos-control-candidates.json` | 57 个当前闭包文件中的 312 个交互候选 |
| `tools/cocos-audit/generated/cocos-runtime-reachability.json` | 当前运行证据、人工结论、模拟器客户区阻塞、无效白屏证据 |
| `docs/unityclient/matrices/HERO_CONTROLS.json` | 阵容页 16 个控件的重新审计结果 |

## 阵容入口人工复核

当前代码链：

```text
UImainLayer_new/ButtonGroup1/btn_zhenrong
  -> MainUI:PetTouchCallback
  -> OpenFunction(EMID_KAPAI_SHENJIANG=1030)
  -> AppDef.moduleUI[1030]
  -> KaPaiPet.PetZhenRongUI
  -> yingxiongListLayer.csb + yingxiongInfoLayer.csb
```

历史 100% 缩放证据能证明该链在《道友来封神》运行可达，但本轮当前账号没有形成合规真实点击证据，故状态为 `current-run-blocked-historical-runtime-confirmed`，不是本轮通过。

## 阵容重审结果

阵容页登记 16 个控件/状态类，按新标准完成数为 `0/16`：

- Unity 已发现 Listener：公共关闭、已占用阵位选择、布阵入口，共 3 项；仍缺真实入口自动化、失败、重连和人工逐控件证据，不能标记完成。
- Unity 明确缺失：空阵位、锁定阵位、空位上阵、养成、强化大师、替换、装备槽 1-4、法宝槽 1-2、详细属性，共 13 项。
- 旧 `visual-1to1-complete`、旧 G4-G6 仅保留为协议和局部截图历史，不再代表阵容迁移完整。

下一次编码前，先保持 Windows 100% 缩放并修正模拟器为原生 1334×750 客户区，再补齐本轮 Cocos 真实入口和 16 项逐控件状态证据；矩阵未冻结完整前不得进入 G3。
