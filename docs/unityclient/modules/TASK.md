# 任务模块

## 当前门禁

- G0：通过。已冻结 14 组当前 Cocos 可达控件，见 `docs/unityclient/matrices/TASK_CONTROLS.json`。
- G1：阻塞。固定账号真实进入 Cocos 任务页且 `/37 op=2/op=0` 均有服务端回包，但当前每日任务列表为空，只覆盖入口、背景、每日页签、活跃条和四档宝箱；尚缺任务行、前往、领奖、已领取、滚动和奖励弹窗的当前 Cocos 状态。
- G2-G6：不得进入；旧“第一阶段完成”记录不继承为新门禁证据。
- 真实入口链：`MainUI.btn_renwu → EMID_TASK_DALIY → Activity.TaskLayer → View.Activity.HuoyueTaskUI → huodong_bg.csb + RenwuLayer.csb → Common.RewardGetUI`。
- 进入页面请求 `/37 op=2` 活跃奖励和 `/37 op=0` 每日任务；任务领奖为 `/37 op=2`，活跃宝箱领奖为 `/37 op=0`，增量为 `/39`，红点为 `/65 type=101`。
- 当前只创建“每日任务”一个页签；通宝加号禁用；“前往”必须读取任务配置 `jump`，不得固定跳神将或显示假数据。
- G1 证据：`.local/ui-fidelity/Task/cocos/g1-20260727/G1_COCOS_EVIDENCE.md`。解除阻塞必须先建立可回滚的真实 `/37` populated/claimable Cocos 夹具。

## 范围

日常任务列表、增量、主界面追踪、红点、领奖、奖励和持久化。

## 三方证据

- 日常任务：`/37`。
- 旧主/支线增删：`/39`。
- 功能红点：`/65 type=101`。

## 实现

- `TaskStore` 统一保存任务状态。
- `TaskPresenter` 复用迁移任务 Prefab 和 VirtualList。
- Lua Controller 解析协议，C# Store 负责权威状态。
- 主界面追踪和红点由 Store 事件驱动。
- 领奖进入 RewardStore/RewardPresenter。

## 已验证

- 隔离角色拉取 8 条真实日常任务。
- `/37 op=2` 增量、追踪和红点刷新。
- `/37 op=3` 领奖，奖励弹窗显示，任务最终 `state=2` 持久化。
- `/39` 与日常 Store 隔离，避免协议语义串线。

## 遗留

- 全任务类型、更多跳转、完成表现、完整错误/断线/空态组合。
