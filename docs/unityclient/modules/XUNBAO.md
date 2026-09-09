# 法宝搜索（XunBao）

> 当前门禁：2026-09-09 G0-G6 已通过，21/21控件、6/6语义、7/7双端状态及用户最终Play“测试通过”均已闭环。任务奖励图标与正式quality底框已恢复；单次/一键搜索奖励补回正式quality底框，底部确定按钮已隐藏并改用同源右上关闭；结果窗尺寸差异由用户接受。范围为21控件、8来源：包含正式 `/37 op=1/3 type=3` 寻宝任务列表/领取；用户 Prefab 修改已保留。

## 2026-09-09 当前输入 G0

- 配方：`hecheng.type=8` 共45条，行ID `197..241`；对应45个目标模板和180个碎片业务ID。
- 协议：`/319 op=28/29/30/31/36` 与 `/37 op=1/3 type=3`；搜索、合成及任务领取均会改变角色状态，模块保持 `mutatesServer=true`。
- 控件：21项；新增寻宝奖励任务列表与领取按钮。移除无来源回调的左右箭头验收，真实法宝切换入口为 `Xunbao/Panel/List/<dynamic item>/Big`。
- 用户资产：`unityclient/Assets/ProjectX/res/csd/Prefabs/wanfa/Xunbao_souxunLayer.prefab` 的按钮文字布局由用户调整，本轮冻结并禁止覆盖。
- 搜索概率来源：`E:/neiwang_kapai/concept/data/excel/xml配置表/新表/fabao_looting.xlsx`，按同目录规则通过`E:/neiwang_kapai/concept/data/excel/转表工具/xl转表.exe`生成`server/config/json/fabao_looting.json`。产物264条、ID连续、碎片无重复，概率分布为40/25/20/10/15；当前180个配方碎片全部覆盖。
- 打表产物SHA-256：`810A38EA30CDDA2F45588DA0B107C004A304270600984D32CAA44AD105E84F5E`。此前临时10000概率夹具及local_test回退代码已删除，生产/本地均读取同源正式JSON。
- 当前账本：`.local/unity-validation/xunbao-operation-ledger.json`；用户早测：`.local/unity-validation/xunbao-early-user-play-latest.json`。

## 范围

- 入口：玩法大厅 `function_id=9`，15 级开启。
- Cocos：`WanFa.XunBaoMainUI` → `csd/wanfa/XunbaoLayer.csb`。
- Unity：导入 `wanfa/XunbaoLayer.prefab`，保持主布局、次数区、法宝合成区与返回路径。
- 搜索列表必须按 `hecheng.type=8` 动态生成：品质 3 且 `id != 615` 默认显示，品质 4 以上仅在任一所需碎片数量大于 0 时显示；当前 Steam V0 资源包默认可见 1001/1002/1003。
- UI 闭包包含帮助、体力/金币/元宝加号、寻宝任务列表/领取、动态卡片、品质面板、碎片槽、搜索与合成边界；不能用空任务弹窗、固定三卡或只统计 Button 绑定数代替。

## 协议

| 方向 | 协议 | 数据 |
|---|---|---|
| C→S | `/319 op=28` | `faBaoId:word, fragmentId:word` |
| C→S | `/319 op=29` | `auto:byte, faBaoId:word` |
| C→S | `/319 op=30` | `faBaoId:word` |
| C→S | `/319 op=31` | 无后续参数 |
| C→S | `/319 op=36` | 无后续参数 |
| S→C | `/319 op=28` | `faBaoId:word, fragmentId:word, ok:byte`；成功后 `remaining:word, searchCount:word, recoverySeconds:uint, rewardBatch[]` |
| S→C | `/319 op=29` | `auto:byte, faBaoId:word, ok:byte`；成功后 `searchCount:word, rewardBatch[], remaining:word, recoverySeconds:uint, useItemCount:word` |
| S→C | `/319 op=30/36` | 成功/失败与提示；op36 成功包含通用奖励批次 |
| S→C | `/319 op=31` | `remaining:word, recoverySeconds:uint` |
| C→S | `/37 op=1` | `taskType:byte=3`，查询寻宝任务列表 |
| S→C | `/37 op=1` | `taskType:byte=3, count:word, [taskId:word, progress:uint, state:byte]` |
| C→S | `/37 op=3` | `taskType:byte=3, taskId:word`，领取任务奖励 |
| S→C | `/37 op=3` | `taskType:byte=3, taskId:word, success:byte, unlockCount:byte, unlockedTask[], rewardBatch` |

服务端权威实现：`CEquipManeger::TrapSouSuoCnt`。回包直接使用角色法宝搜索计数与下一次恢复秒数，不修改服务端状态。

## Unity 实现

- `XunBaoStore` 保存权威次数与恢复秒数。
- `XunBaoController.lua.txt` 负责 `/319 op=28/29/30/31/36` 的字段级收发，op28跳过服务端尾部汇总奖励以避免重复，op29按服务端 `UInt32 seconds + UInt16 useItemCount` 解析，并保留每次搜索的独立奖励批次。
- `XunBaoPresenter` 直接绑定正式导入Button；次数、倒计时、动态法宝、碎片图标/灰态/粒子、品质Open/Compose时间轴均由权威状态与正式配置驱动，不再增加透明命中层。
- `XunBaoResultPresenter` 使用用户调整后的 `Xunbao_souxunLayer.prefab` 每0.3秒追加一次搜索结果，并等待全部批次渲染完成；结果道具保持底框根节点、图标内嵌并按正式`quality`切换品质框，隐藏底部按钮并复用`Xunbao_popupLayer`同源右上关闭。`XunBaoPopupPresenter` 实现mode=1合成反馈、mode=2一键搜索确认和mode=3正式任务列表/领取；119条任务复用统一`VirtualList`，任务奖励补横向布局与正式品质框，保持来源ListView裁剪与拖动。
- mode=3 必须按 Cocos `QueryGotTaskList(3) -> WanFaDailyTaskInfo -> DataSort/ShowRewardList` 链路消费正式 `daily.json`，不能继续使用空白边界或客户端编造奖励。
- 正式Cocos `op36` 成功路径是 `Common.SaoDangUI -> csd/common/saodang.csb`；Unity已改用同源 `common/saodang.prefab` 和 `XunBaoComposeAllPresenter` 展示一键合成奖励，不再用通用奖励弹窗近似替代。
- 搜宝令402与任务奖励1211“高级法宝箱”均来自正式 `item.xlsx`；服务端与Unity `item.json` 为同源记录，没有本地假配置。60028奖励按子类型615/616/617解析正式`fabao.json`。
- `Invoke-XunBaoSqliteFixture.ps1/.py` 只操作 `Application.persistentDataPath/LocalServer/projectx.db`：固定 Unity SQLite 身份`7200057/1000003 (T00057)`、20次搜索、2个搜宝令、清除bit629、写入正式type=3任务25..143并令任务25可领取，同时冻结`save_val`每日标记防止登录重置；Cocos MySQL 对照身份为同名`7200057/1000115`，由跨后端身份合同关联；整库快照、变更断言、恢复SHA、重登和零残留均为硬合同。
- `ProjectXApp.EnterGameplay(9)` 完成玩法大厅进入，关闭按钮和 Esc 返回玩法大厅。

### 2026-08-28 真人Play修复

- 用户截图确认：权威剩余次数为0时，一键搜索仍发送op29并显示“一键搜索成功”，但实际搜索批次为0；Unity没有展示Cocos `XunBaoResultUI`等价结果，也没有用背包权威数据刷新碎片数量。
- 当前修复：0次时客户端不再发送op28/op29，直接进入搜宝令402的背包使用边界；op28/op29逐批解析通用奖励三元组并打开来源一致的搜索结果层；主界面碎片数量、图标、灰态和完成粒子订阅`BagStore`刷新；所需碎片不足时不发送op30。
- 同时修正初始范围为Cocos默认三个蓝色法宝`1001/1002/1003`及图片`1002/1003/1001`，不再循环到不存在的`1004..1006`。
- 用户证据：`.local/ui-fidelity/XunBao/user-feedback/20260828-xunbao-actions-ineffective.png`；失败记录：`.local/unity-validation/xunbao-operation-ledger.json`。用户复测与标准门禁前保持未解决。

## 验证

- 固定账号 G4/G6 命令：`pwsh -NoProfile -File tools/unity-migration/Run-UnityFixedAccountValidation.ps1 -Module XunBao`；XunBao 使用 SQLite 固定账号夹具，禁止以默认 MySQL 后端的通用模块命令代替。
- 截图合同：7组正式双端状态——主界面、寻宝任务奖励列表、单次搜索结果、单个合成反馈、一键合成SaoDang结果、一键搜索确认、一键搜索结果；Unity Runner另保留兼容收口图`build/ui-migration/bootstrap-xunbao.png`。每张正式G5图片必须有同目录`<截图名>-ui-resource-map.md`。
- 当前结果（2026-09-09）：G1冻结7张原生Cocos状态；G2的21控件、`/319 + /37`、119条任务/120条奖励、VirtualList、奖励品质框和右上关闭资源闭包通过。中央工具链327项、文档35模块通过。
- G3固定Unity SQLite账号`7200057/1000003`完成数据预检、编译与批诊断：21/21控件，`/37 type=3`列表和任务25领取成功，无语义失败；证据`.local/unity-validation/xunbao-g3-runtime-latest.json`与`.local/unity-validation/xunbao-fixed-account-runner-latest.json`。
- 视觉修复后的固定SQLite账号Full与G5 VisualOnly均已重跑：21/21控件、6/6语义、7/7双端状态、重登、精确恢复与零残留通过。
- 旧G5差异图用于定位问题，不作为当前通过证据。当前G3图已证明任务奖励图标/品质框、单次与一键结果奖励品质框、右上关闭恢复且底部确定消失；结果窗尺寸差异按用户决定保留。证据`.local/unity-validation/xunbao-g5-visual-assessment-latest.json`，新G5须在G4后生成。
- 数据预检曾发现登录每日重置会擦除任务25；已修复夹具同步`save_val`第10索引为当前0基`tm_yday`，复验整库恢复SHA一致且备份残留0。当前无Unity/服务端残留，等待G3后早期真实Play。
- Unity历史结果仅作诊断线索；旧文档中的 `remaining=30, recoverySeconds=0` 已撤销，生产配置实际为初始20次、30分钟恢复、上限30次。
- 2026-08-23：固定账号 `7200057/1000115` 的 `/319 op31` 真实查询、Unity 编译、截图与 16/16 Python 测试通过；当前 Cocos 主页面基线保存于 `.local/ui-fidelity/XunBao/cocos/g1-20260823/XUNBAO-MAIN.png`。
- 当前G4实现为逐控件真实EventSystem射线、协议往返、完整奖励批次、同源SaoDang/搜索/确认/合成弹窗和权威状态断言；用户在视觉修复与固定身份纠正后确认“测试通过”，21/21控件均登记`manualPassed=true`，G6自动复盘213/213已解决。

### 历史 G5/G6 收口记录（2026-08-23，当前缺证失效）

- 恢复中心法宝真实图、属性/描述和底部三法宝条目，稳定帧移除模块外全局滚动提示。
- Cocos MySQL `7200057/1000115` 与 Unity SQLite `7200057/1000003` 以同名角色 `T00057` 建立正式跨后端映射；原生 `1334×750` 主状态完成并排、叠加、差异报告与人工验收；受控差异仅为只读 Fixture 货币值。
- 7/7 控件、3/3 语义断言、严重异常 0；自动复盘 14/14 失败均已诊断解决。
- 两次正式 `BootstrapSceneBuilder.BuildBatch` SHA-256 均为 `7C0E65C8D6D8E162059B0DC45149B64042CE89EA4D0CB6C944D8E1A678CA8FBA`，中央工具链 190/190。
- 最终证据：`.local/ui-fidelity/XunBao/compare/g5/report.json`、`.local/ui-fidelity/XunBao/compare/g5/manual-acceptance.json`、`.local/unity-validation/xunbao-fixed-account-latest.json`、`.local/unity-validation/xunbao-retrospective-latest.json`。

### Steam SQLite S5（2026-08-20）

- SQLite 与隔离 MySQL 均完成两次真实 `/319 op31` 查询及进程重启后复查：运行态各 2 case/46 响应，重启态各 1 case/20 响应，协议结构差异 0、语义一致。
- `server/config/json/config.json` 的 `fabao_counts=[20,30,30]` 含义冻结为“新角色 20 次、每 30 分钟恢复 1 次、上限 30 次”；回包倒计时属于运行时秒数，保留原始包并仅按有效 `1..1800` 秒窗口归一化比较。
- 重复查询和重启后次数均为 20，未产生业务状态变更；`mission/save_data/xunbao` 字节一致。`pet_equip` 解压后仅 `m_lastCntTime` 因双端启动相差 40 秒，其余静态字节及 `m_faBaoCnt=20` 一致。
- 证据：`.local/unity-validation/steam-sqlite-s5-xunbao-latest.json`。隔离库 `fxl_game_xunbao_s5_v1` 已删除；正式 `fxl_game_local`、MySQL 源码/驱动/构建/Schema/脚本/回归继续保留。
