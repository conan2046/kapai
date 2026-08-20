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
- Unity 历史结果：真实 Prefab、权威回包、截图、关闭/Esc 返回全部通过；旧文档中的 `remaining=30, recoverySeconds=0` 已撤销，生产配置实际为初始 20 次、30 分钟恢复、上限 30 次。
- 自动化：16/16 Python 测试通过，严重异常 0；状态为 `logic-validated-visual-pending`。
- 已知边界：法宝清单/碎片数量依赖客户端配置，搜索和合成等变更流程留待后续阶段。

### Steam SQLite S5（2026-08-20）

- SQLite 与隔离 MySQL 均完成两次真实 `/319 op31` 查询及进程重启后复查：运行态各 2 case/46 响应，重启态各 1 case/20 响应，协议结构差异 0、语义一致。
- `server/config/json/config.json` 的 `fabao_counts=[20,30,30]` 含义冻结为“新角色 20 次、每 30 分钟恢复 1 次、上限 30 次”；回包倒计时属于运行时秒数，保留原始包并仅按有效 `1..1800` 秒窗口归一化比较。
- 重复查询和重启后次数均为 20，未产生业务状态变更；`mission/save_data/xunbao` 字节一致。`pet_equip` 解压后仅 `m_lastCntTime` 因双端启动相差 40 秒，其余静态字节及 `m_faBaoCnt=20` 一致。
- 证据：`.local/unity-validation/steam-sqlite-s5-xunbao-latest.json`。隔离库 `fxl_game_xunbao_s5_v1` 已删除；正式 `fxl_game_local`、MySQL 源码/驱动/构建/Schema/脚本/回归继续保留。
