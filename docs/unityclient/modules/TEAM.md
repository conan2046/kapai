# Team 队伍模块

> 状态：第一阶段完成。范围仅含 Team；Guild `/54` 未混入。

## 范围

- 核心协议：`PRO_USER_TEAM/29` 请求/响应、`PRO_UPDATE_TEAM/30` 服务端推送。
- 权威状态：无队伍、队伍类型、阵法、玩家/宠物成员、队长、暂离、邀请列表。
- 可控闭环：创建队伍、邀请、另一隔离角色接受、离队。
- UI：只读导入 `TeamMembersLayer.prefab`、`TeamInviteListLayer.prefab`，使用运行时绑定和覆盖，不重建 Prefab。

## 三方证据

### 协议与服务端

- 协议号：`server/src/protocol.h` 的 `/29`、`/30`。
- 注册与入口：`server/src/pack_deal.cpp` 的 `UserTeamOption`。
- 队伍状态和推送：`server/src/scene_manager.cpp` 的 `CUserTeam::UpdateTeamData`、`CScene::UpdateTeamData` 及 `PRO_UPDATE_TEAM` 分支。
- `/29` 本阶段使用操作：`1` 创建、`5` 邀请、`6` 接受/拒绝邀请、`9` 离队、`16` 权威全量状态；旧实现还包含 `4` 接受申请、`8` 成员等入口。
- `/30` 操作 `1..11` 是队伍关系变化通知；Unity 只解析关联角色字段，命中自身或当前队长后重拉 `/29 op=16`，不把通知包当完整状态。

### `/29 op=16` 字段

| 层级 | 字段 |
|---|---|
| 响应头 | `success:byte`；失败时可带 `reason:string` |
| 空态 | `teamType:byte=255`，兼容尾随状态字节 |
| 队伍 | `teamType:byte`、`formationId:word`、`memberCount:byte` |
| 玩家成员 | `kind=1`、源位置、阵位、队长标记、`roleId:uint`、区服、服务器、暂离、姓名、等级、头像、性别、`power:uint64`、称号列表、外形 |
| 宠物成员 | `kind=2`、位置、阵位、宠物 ID、姓名、等级、星级、突破、`power:uint64` |

关键取证：服务端 `GetZhanDouLi()` 写入 64 位战力；旧 Lua 使用 `ReadUInt` 会截断。Unity 按真实包使用 `ReadULongInt`。

### 旧客户端与真实入口

- 请求与解析：`client/ProjectX/src/NetWork/LuaNetSendMsg.lua`、`LuaNetRecvdMsg.lua`。
- 旧数据：`client/ProjectX/src/Logic/Team/LTeamData.lua`。
- 主界面入口：`UImainLayer_backup.prefab` 的 `Layer/Main_UI/Panel_QuestAndTeam/CheckBox_Team`；`TaskTrackSubUI.lua` 路由到 `Team.TeamMainUI`。
- 旧 UI：`client/ProjectX/src/View/Team/TeamMemberUI.lua`、`TeamInviteUI.lua`。
- Unity 真实 Prefab：`Assets/ProjectX/res/csd/Prefabs/TeamMembersLayer.prefab`、`TeamInviteListLayer.prefab`；本阶段未修改这两个资源。

## 实现

- `PlayerSummary.cs` 成为 Friend、Chat、Team 共用的玩家摘要；没有创建第三套平行玩家模型。
- `TeamStore.cs` 保存权威队伍、玩家/宠物成员和邀请；玩家成员引用 `PlayerSummary`。
- `TeamController.lua.txt` 处理 `/29`、`/30`，暴露状态查询、创建、邀请/接受、离队入口。
- `TeamPresenter.cs` 在导入 Prefab 上运行时绑定五个成员槽、按钮和状态，不回写 Prefab。
- `ProtocolRegistry`、`GameServices`、`ProjectXApp`、Bootstrap 与场景装配已接线；切号会清理 TeamStore。
- `Run-UnityModuleValidation.ps1` 为 Team 分配目标/同伴角色，启动持久同伴协议进程并递归清理其进程树。
- 本地测试服缺少功能开放配置时返回 `0xffff`，会误拦截 60 级隔离角色；`local_test=1` 下仅对 Team 回退到真实开放等级 `32`，线上路径不变。

## 验证

- 最终隔离账号：`userId=7200059`；目标角色 `1000117`；同伴角色 `1000118`。失败账号未用作最终证据。
- 权威闭环：`/29` 空态 → 创建 → 邀请 → 同伴接受 → 两名玩家进入 TeamStore/UI → 离队 → 重拉并持久化空态。
- 推送：`/30` 在创建、入队、离队过程中触发权威 `/29 op=16` 刷新。
- Unity：BatchMode 编译/运行通过，结果 `success=true`；状态为 `COMPLETE`。
- GameView：`1334×750` 双人队和最终空态截图均通过，五槽占位、玩家摘要、按钮完整可见。
- UI 自动化：`python -m unittest discover -s tools/ui_migration/tests -v`，`10/10` 通过。
- 结果：`.local/unity-validation/team-latest.json`；截图：`build/ui-migration/bootstrap-team-members.png`、`bootstrap-team.png`。
- 阶段结束关闭 Unity、`kapai.exe`、workspace-local MySQL，并检查 `3306/8711` 无监听。

## 遗留

- 队伍申请列表、拒绝邀请、踢人、移交队长、阵法/暂离主动操作尚未形成正向闭环。
- 断线重连后的队伍恢复沿用 `/29 op=16`，后续可补专项自动化。
- Guild `/54` 单独作为下一模块，不复用本模块的变更型验证账号。

## 关键坑

- 战力字段必须按 `uint64` 读取，不能照抄旧客户端的 `ReadUInt`。
- `/30` 是通知而非全量数据，统一重拉 `/29 op=16` 可避免并发增量漂移。
- 同伴必须保持在线直到接受邀请；验证脚本需清理 PowerShell 及其 Python 子进程，避免日志锁和残留连接。
- 导入 Prefab 保持只读；空槽残影和按钮裁剪均通过运行时绑定修复。
