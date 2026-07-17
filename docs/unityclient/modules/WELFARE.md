# 福利模块

> 状态：第一阶段完成。每日签到变更闭环、在线奖励只读状态和阶段目标真实空态已验证。

## 范围

- 每日签到列表、累计签到天数、今日领取状态。
- 在线奖励里程碑、已领取/可领取/等待状态和 ServerTime 剩余时间。
- 阶段目标服务端边界与真实空态。
- 一次隔离账号签到领取、奖励展示、权威状态重拉和红点状态刷新。

## 三方证据

- `/199 MSG_HUODONG_OPTION op=8`：每日签到查询/领取。
- `/222 MSG_TMP_HUODONG activity=4`：在线奖励查询/领取；本阶段只读。
- `/223 MSG_STAGE_GOAL`：阶段目标；当前 `CMissionManager` 查询与领奖主体已注释，不能形成可用回包。
- 旧入口：`MainUI.lua` 的 `btn_fuli`；旧福利分类见 `WelfareConfig.lua`。
- Prefab：`WelfareLayer.prefab`、`SignLayer.prefab`、`huodong/LoginGiftLayer.prefab`，保持导入资产只读。

## 实现

- `WelfareStore` 保存签到和在线奖励权威状态，奖励复用 `RewardRecord`。
- `WelfarePresenter` 复用导入 Prefab、VirtualList、ResourceService、ServerTime、UiStack 和通用奖励弹窗。
- `WelfareController.lua` 严格解析 `/199` 和 `/222 activity=4`，领取成功后重拉 `/199`。
- `/223` 不发送无回包请求，UI 明示服务端未启用。

## 验证

- 命令：`pwsh -File tools/unity-migration/Run-UnityModuleValidation.ps1 -Module Welfare`。
- 最终隔离账号：`userId=7200014`；`7200009-7200013` 为外层超时、场景未重建、视觉或红点修正过程账号，不作为最终证据。
- `/199`：31 条真实签到奖励，初始 `today=0,days=0` → 单次签到成功 → 重拉 `today=1,days=1`。
- `/222 activity=4`：12 档在线奖励，权威状态 `claimed=0`；下一档 3 分钟，倒计时由 ServerTime 驱动，未等待或伪造在线时长领取。
- `/223`：服务端处理主体为空，不发起必超时请求；阶段目标页展示真实不可用空态。
- 奖励：签到成功复用 `RewardStore/RewardPresenter`；领取后以 `/199` 重拉结果作为最终状态证据。
- GameView：`bootstrap-welfare-sign.png`、`bootstrap-welfare-online.png`、`bootstrap-welfare-stage-empty.png`、`bootstrap-welfare.png`，均为 `1334×750`。
- Unity BatchMode 编译/运行通过；结果 `success=true`；严重异常 `0`（日志仅有 Unity CrashHandler 性能标签）；UI 转换测试 `10/10`。
- 阶段结束 Unity、`kapai.exe`、workspace-local MySQL 已关闭，3306/8711 无监听。

## 关键坑

- 新增 Prefab 后必须先执行 `BootstrapSceneBuilder.BuildBatch` 重建 Bootstrap 场景，模块 Runner 不会自动刷新旧场景。
- `/199 op=8` 使用 `u16` 子操作码，查询/领取类型为 `u8`；查询回包不含统一 `PRO_SUCCESS`，不能套活动通用包头。
- `/222 activity=4` 返回的是“当前已领档位 + 当前档累计秒数”；下一档阈值使用相邻累计分钟差，倒计时只用 ServerTime。
- `/223` 旧客户端仍保留完整解析，但当前服务端实际实现为空，禁止按旧 UI 或旧解析伪造可用状态。

## 遗留

- 在线奖励领取、七日登录、等级礼包及阶段目标服务端恢复。
- 福利活动开放周期配置、更多错误/断线/重复打开组合。
