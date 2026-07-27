# 任务模块

## 当前门禁

- G0：通过。已冻结 14 组当前 Cocos 可达控件，见 `docs/unityclient/matrices/TASK_CONTROLS.json`。
- G1：通过。固定账号 `7200057/1000115` 从真实 `btn_renwu` 入口完成 populated、claimable、claimed、前往、领取、列表滚动、四档活跃宝箱、奖励弹窗确认/关闭和奖励物品的原生 `1334×750` Cocos 取证。
- G2：通过。Unity 使用 `/37 type=2/type=0`、`/39`、`/65 type=101` 三方契约，Lua 保持权威状态，C# Store 仅作渲染镜像。
- G3：通过。真实 `huodong_bg`、`RenwuLayer`、`tanchuangjiangli` Prefab 已接线，Unity 2022.3.62f3c1 编译与标准 Runner 通过。
- G4：通过。隔离账号完成 `14/14` 真实控件、成功/失败、重复/非法、关闭重载、断线重连、持久化和切号清理。
- G5：通过。固定账号 `7200057/1000115` 完成 `11/11` 关键状态 Cocos/Unity 原生 `1334×750` 并排、叠加、增强差异和人工视觉验收。
- G6：通过。矩阵 `14/14 complete`，16/16 UI 解析测试、严重异常扫描和正式 `BuildBatch` 双次幂等均通过。
- 真实入口链：`MainUI.btn_renwu → EMID_TASK_DALIY → Activity.TaskLayer → View.Activity.HuoyueTaskUI → huodong_bg.csb + RenwuLayer.csb → Common.RewardGetUI`。
- 进入页面请求 `/37 op=1,type=2` 每日任务和 `/37 op=1,type=0` 活跃奖励；任务领奖为 `/37 op=3,type=2,task_id`，活跃宝箱领奖为 `/37 op=3,type=0,task_id`，增量为 `/39`，红点为 `/65 type=101`。
- 当前只创建“每日任务”一个页签；通宝加号禁用；“前往”必须读取任务配置 `jump`，不得固定跳神将或显示假数据。
- G1 证据：`.local/ui-fidelity/Task/cocos/g1-20260727/G1_COCOS_EVIDENCE.md`。夹具快照 SHA-256 `99ccff91ef8285ff80565658ce2366ec615682a30ebc48378f452ac341494d29`，`setupAssertSql/cleanupAssertSql` 均通过，固定账号数据已精确恢复并无夹具重新登录。

## 范围

日常任务列表、增量、主界面追踪、红点、领奖、奖励和持久化。

## 三方证据

- 日常任务：`/37`。
- 旧主/支线增删：`/39`。
- 功能红点：`/65 type=101`。

## 实现

- `TaskStore` 分离每日任务与四档活跃宝箱，并保存进度、状态、跳转和真实奖励配置。
- `TaskPresenter` 复用迁移任务 Prefab 和 VirtualList，渲染前往、领取、已领取、奖励物品、滚动与宝箱状态。
- Lua Controller 解析协议并保持权威状态，C# Store 只作渲染镜像。
- 主界面追踪和红点由 Store 事件驱动。
- 领奖进入 RewardStore/RewardPresenter；宝箱弹窗区分预览、关闭与可领确认。
- 公共框架显示“任务/每日任务”、真实体力/铜钱/通宝；体力加号进入背包、铜钱加号进入商城、通宝加号禁用。

## 已验证

- 当前 Cocos 配置 148 条已同步到服务端：`type=2` 每日任务 17 条、`type=0` 活跃宝箱 4 条；修复了旧服务端仅 8 条 `type=1` 导致的空列表。
- `/37` 全量返回真实 populated 列表及四档宝箱；任务行覆盖 `state=0/1/2`。
- “帮派副本挑战5次”的前往真实打开帮派页；每日登录领取后显示真实奖励弹窗及物品。
- 首档活跃宝箱完成预览、关闭、确认领取、开箱态和四项奖励验证；任务 TableView 顶部/底部及“已领取”行均有当前 Cocos 证据。
- 注入前快照、SQL 注入断言、SQL 恢复断言、夹具行删除断言均通过；恢复后固定账号重新登录成功。
- 修复夹具重登录访问冲突：同一数据库句柄的夹具查询延后到 `role_info` 当前行读取完成之后。
- 固定账号 Unity 结果：`.local/ui-fidelity/Task/unity/g5-20260727/task-fixed-unity-result.json`；状态为 `14/14 real controls`。
- 注入前与恢复后快照哈希均为 `99ccff91ef8285ff80565658ce2366ec615682a30ebc48378f452ac341494d29`；重登录后恢复哈希硬断言继续通过。
- G5 共 `11/11` 关键状态，报告 `.local/ui-fidelity/Task/compare/g5-live-20260727/report.json`，人工验收 `.local/ui-fidelity/Task/compare/g5-live-20260727/manual-acceptance.json`。
- 最终隔离回归账号 `7200085/1000140`：14/14 真控件、16/16 Python UI、严重异常 0，见 `.local/unity-validation/task-latest.json`。
- 正式 `BootstrapSceneBuilder.BuildBatch` 连续两次 SHA-256 均为 `B27460DB36051DA396630CFF66EDED1115F3C3CB8148388F9574AA60A92D19AE`。

## 边界

- Task 当前 Cocos 可达范围已完成；跳转目标模块内部功能继续由各自模块负责。
- 不新增当前 Cocos 不存在的任务页签或通宝加号业务。
