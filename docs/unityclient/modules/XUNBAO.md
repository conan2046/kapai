# 法宝搜索（XunBao）

> 当前门禁：`G0 passed / G1 implementation fixed, user retest pending / G2-G6 blocked`。登记的Cocos/Unity基准、差异报告与验收目录当前不存在，必须从当前源码串行重取，历史G6仅作线索。

## 范围

- 入口：玩法大厅 `function_id=9`，15 级开启。
- Cocos：`WanFa.XunBaoMainUI` → `csd/wanfa/XunbaoLayer.csb`。
- Unity：导入 `wanfa/XunbaoLayer.prefab`，保持主布局、次数区、法宝合成区与返回路径。
- 已完成搜索、法宝切换、补次数说明、单个/一键合成及权威次数刷新；不再停留在只读骨架。

## 协议

| 方向 | 协议 | 数据 |
|---|---|---|
| C→S | `/319 op=28` | `faBaoId:word, fragmentId:word` |
| C→S | `/319 op=29` | `auto:byte, faBaoId:word` |
| C→S | `/319 op=30` | `faBaoId:word` |
| C→S | `/319 op=31` | 无后续参数 |
| C→S | `/319 op=36` | 无后续参数 |
| S→C | `/319 op=28/29` | 成功标记、权威搜索记录、remaining 与 recoverySeconds；每条记录按 `rewardCount:byte + reward(word,uint,uint)[]` 跳读 |
| S→C | `/319 op=30/36` | 成功/失败与提示；op36 成功包含通用奖励批次 |
| S→C | `/319 op=31` | `remaining:word, recoverySeconds:uint` |

服务端权威实现：`CEquipManeger::TrapSouSuoCnt`。回包直接使用角色法宝搜索计数与下一次恢复秒数，不修改服务端状态。

## Unity 实现

- `XunBaoStore` 保存权威次数与恢复秒数。
- `XunBaoController.lua.txt` 负责 `/319 op=28/29/30/31/36` 的字段级收发，奖励批次与当前 Cocos `ReadRewardData` 一致。
- `XunBaoPresenter` 绑定真实 Prefab 次数/倒计时、法宝切换、碎片搜索、一键搜索、单个/一键合成；操作结果由服务端回包驱动。
- `ProjectXApp.EnterGameplay(9)` 完成玩法大厅进入，关闭按钮和 Esc 返回玩法大厅。

### 2026-08-28 真人Play修复

- 用户截图确认：权威剩余次数为0时，一键搜索仍发送op29并显示“一键搜索成功”，但实际搜索批次为0；Unity没有展示Cocos `XunBaoResultUI`等价结果，也没有用背包权威数据刷新碎片数量。
- 当前修复：0次时客户端不再发送op28/op29，直接进入搜宝令402的背包使用边界；op28/op29逐条解析通用奖励三元组并打开公共“寻宝奖励”弹窗；主界面碎片数量订阅`BagStore`刷新；三种所需碎片不足时不发送op30。
- 同时修正初始范围为Cocos默认三个蓝色法宝`1001/1002/1003`及图片`1002/1003/1001`，不再循环到不存在的`1004..1006`。
- 用户证据：`.local/ui-fidelity/XunBao/user-feedback/20260828-xunbao-actions-ineffective.png`；失败记录：`.local/unity-validation/xunbao-operation-ledger.json`。用户复测与标准门禁前保持未解决。

## 验证

- 命令：`pwsh -NoProfile -File tools/unity-migration/Run-UnityModuleValidation.ps1 -Module XunBao`
- 截图：`build/ui-migration/bootstrap-xunbao.png`
- Unity 历史结果：真实 Prefab、权威回包、截图、关闭/Esc 返回全部通过；旧文档中的 `remaining=30, recoverySeconds=0` 已撤销，生产配置实际为初始 20 次、30 分钟恢复、上限 30 次。
- 2026-08-23：固定账号 `7200057/1000115` 的 `/319 op31` 真实查询、Unity 编译、截图与 16/16 Python 测试通过；当前 Cocos 主页面基线保存于 `.local/ui-fidelity/XunBao/cocos/g1-20260823/XUNBAO-MAIN.png`。
- 写操作闭包已经接通；自动验收只执行无副作用的 op31，op28/29/30/36 的成功与失败分支由当前 Cocos/服务端源码合同和编译门禁覆盖，人工测试时以服务器回包及随后状态为准。

### 历史 G5/G6 收口记录（2026-08-23，当前缺证失效）

- 恢复中心法宝真实图、属性/描述和底部三法宝条目，稳定帧移除模块外全局滚动提示。
- Cocos/Unity 同账号 `7200057/1000115`、原生 `1334×750` 主状态完成并排、叠加、差异报告与人工验收；受控差异仅为只读 Fixture 货币值。
- 7/7 控件、3/3 语义断言、严重异常 0；自动复盘 14/14 失败均已诊断解决。
- 两次正式 `BootstrapSceneBuilder.BuildBatch` SHA-256 均为 `7C0E65C8D6D8E162059B0DC45149B64042CE89EA4D0CB6C944D8E1A678CA8FBA`，中央工具链 190/190。
- 最终证据：`.local/ui-fidelity/XunBao/compare/g5/report.json`、`.local/ui-fidelity/XunBao/compare/g5/manual-acceptance.json`、`.local/unity-validation/xunbao-latest.json`、`.local/unity-validation/xunbao-retrospective-latest.json`。

### Steam SQLite S5（2026-08-20）

- SQLite 与隔离 MySQL 均完成两次真实 `/319 op31` 查询及进程重启后复查：运行态各 2 case/46 响应，重启态各 1 case/20 响应，协议结构差异 0、语义一致。
- `server/config/json/config.json` 的 `fabao_counts=[20,30,30]` 含义冻结为“新角色 20 次、每 30 分钟恢复 1 次、上限 30 次”；回包倒计时属于运行时秒数，保留原始包并仅按有效 `1..1800` 秒窗口归一化比较。
- 重复查询和重启后次数均为 20，未产生业务状态变更；`mission/save_data/xunbao` 字节一致。`pet_equip` 解压后仅 `m_lastCntTime` 因双端启动相差 40 秒，其余静态字节及 `m_faBaoCnt=20` 一致。
- 证据：`.local/unity-validation/steam-sqlite-s5-xunbao-latest.json`。隔离库 `fxl_game_xunbao_s5_v1` 已删除；正式 `fxl_game_local`、MySQL 源码/驱动/构建/Schema/脚本/回归继续保留。
