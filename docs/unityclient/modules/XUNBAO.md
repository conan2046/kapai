# 法宝搜索（XunBao）

## 范围

- 入口：玩法大厅 `function_id=9`，15 级开启。
- Cocos：`WanFa.XunBaoMainUI` → `csd/wanfa/XunbaoLayer.csb`。
- Unity：导入 `wanfa/XunbaoLayer.prefab`，保持主布局、次数区、法宝合成区与返回路径。
- 首期只接只读状态；搜索、补次数、合成等消耗操作保持禁用。

## 协议

| 方向 | 协议 | 数据 |
|---|---|---|
| C→S | `PET_EQUIP_OPERATE/319 op=31` | 无后续参数 |
| S→C | `PET_EQUIP_OPERATE/319 op=31` | `remaining:word, recoverySeconds:uint` |

服务端权威实现：`CEquipManeger::TrapSouSuoCnt`。回包直接使用角色法宝搜索计数与下一次恢复秒数，不修改服务端状态。

## Unity 实现

- `XunBaoStore` 保存权威次数与恢复秒数。
- `XunBaoController.lua.txt` 负责 `/319 op=31` 请求与解析。
- `XunBaoPresenter` 绑定真实 Prefab 次数/倒计时，固定展示一套合成区域并禁用所有变更按钮。
- `ProjectXApp.EnterGameplay(9)` 完成玩法大厅进入，关闭按钮和 Esc 返回玩法大厅。

## 验证

- 命令：`pwsh -NoProfile -File tools/unity-migration/Run-UnityModuleValidation.ps1 -Module XunBao`
- 截图：`build/ui-migration/bootstrap-xunbao.png`
- 结果：`remaining=30, recoverySeconds=0`；真实 Prefab、权威回包、截图、关闭/Esc 返回全部通过。
- 自动化：16/16 Python 测试通过，严重异常 0；状态为 `logic-validated-visual-pending`。
- 已知边界：法宝清单/碎片数量依赖客户端配置，搜索和合成等变更流程留待后续阶段。
