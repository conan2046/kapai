# Guild 帮派模块

> 状态：第一阶段完成。范围仅含 Guild `/54`；Team 深化项未混入。

## 范围

- 核心协议：`PRO_BANGPAI/54`。
- 只读能力：无帮派空态、帮派列表、当前帮派信息、成员列表。
- 可回收闭环：新隔离角色创建单人帮派，读取权威状态和成员后退出；单人帮主退出触发解散，不遗留帮派。
- UI：只读导入 `bangpai/GangsApplyLayer`、`GangsLayer`、`GangsMemberLayer`、`GangsfoundLayer`，全部运行时绑定。

## 三方证据

### 协议与服务端

- 协议号：`server/src/protocol.h` 的 `PRO_BANGPAI=54`。
- 注册与入口：`server/src/pack_deal.cpp` 的 `CPackageDeal::BangPai`。
- 列表序列化：`server/src/bangpai.cpp` 的 `CBangPaiManager::MakeBangPaiList`。
- 创建/退出：`CPackageDeal::BangPai` 的 `op=1/12`；单成员帮主退出走 `DismissBang_updata()`，验证后帮派被解散。

### `/54` 操作码总表

| op | 语义 | 本阶段 |
|---:|---|---|
| 0 | 创建面板信息 | 取证 |
| 1 | 创建帮派 | 实现、验证 |
| 2 | 帮派列表 | 实现、验证 |
| 3 | 申请加入 | 字段取证，未做正向变更 |
| 4 | 向有权限成员请求加入 | 取证 |
| 6 | 管理员邀请玩家 | 取证 |
| 7 | 接受/拒绝邀请 | 取证 |
| 8 | 入帮申请列表 | 取证 |
| 9 | 单个批准申请 | 取证 |
| 10 | 帮派成员列表 | 实现、验证 |
| 11 | 逐出帮派 | 取证 |
| 12 | 退出帮派 | 实现、验证 |
| 13 | 当前帮派信息 | 实现、验证 |
| 14 | 查询指定帮派信息 | 取证 |
| 15 | 修改口号，旧代码标记未使用 | 取证 |
| 16 | 修改公告 | 取证 |
| 17 | 空分支 | 不实现 |
| 18 | 解散帮派 | 取证；闭环由单人退出间接触发 |
| 19 | 帮主传位/撤销 | 取证 |
| 20 | 调整位阶 | 取证 |
| 21 | 按玩家查询帮派 | 取证 |
| 22 | 查询传位状态 | 取证 |
| 23 | 全部批准申请 | 取证 |
| 24 | 领取俸禄 | 取证 |
| 25 | 捐献 | 取证 |
| 26 | 入帮邀请推送 | 取证 |
| 27 | 进入帮派场景 | 服务端主体被注释，不实现 |
| 28 | 帮派操作记录 | 取证 |
| 29 | 帮主/长老每日奖励 | 取证 |
| 30/31 | 申请红点状态查询/推送 | 取证，复用既有红点层的后续入口 |
| 32 | 是否显示帮派信息 | 取证 |
| 33 | 帮派任务列表 | 取证 |
| 34~36 | 神树信息/祈福/领奖 | 取证 |
| 37~39 | 捐献信息/捐献金币/内务记录 | 取证 |
| 40 | 自动审核等级 | 取证 |
| 41~42 | 活跃奖励状态/领取 | 取证 |
| 43 | 升级炼器阁 | 取证 |
| 44~45 | 帮派技能查询/升级 | 取证 |

### 本阶段请求/响应字段

| op | 请求 | 响应 |
|---:|---|---|
| 1 | `name:string, notice:string, pic:uint32, autoLevel:uint16` | `op:byte, success:byte, message:string` |
| 2 | 仅 `op` | `op, count:uint16`；每项 `rank:uint16, id:uint32, name:string, level:byte, leader:string, memberCount:uint16, maxMembers:uint16, planted:uint16, notice:string, applied:byte, autoLevel:uint16` |
| 3 | `guildId:uint32` | 原请求回写 `success:byte`；失败追加 `message:string`，申请或自动入帮语义由目标帮派设置决定 |
| 10 | 仅 `op` | `op, count:byte`；每项 `roleId:uint32, name:string, level:uint16, rank:byte, head:byte, contribution:uint32, sex:byte, power:uint64, vip:byte, offlineSeconds:uint32, dailyActivity:uint32` |
| 12 | 仅 `op` | `op, success:byte`；单成员帮主退出后解散 |
| 13 | 仅 `op` | `op, success:byte`；成功追加 `id:uint32, name:string, leader:string, level:byte, legacyId:uint16, memberCount:uint16, prosperity:uint32, notice:string, slogan:string, autoLevel:uint16` |

成员战力由服务端 `SRoleSimpleData.power:uint64` 写入，Unity 使用 `ReadULongInt`。成员玩家数据统一构造 `PlayerSummary`，未建立平行玩家模型。

### 旧客户端与真实入口

- 请求：`client/ProjectX/src/NetWork/LuaNetSendMsg.lua` 的 `QueryBangPaiCreateByMoney`、`ReqSendBangPaiList`、`ReqJoinBangPai`、`QueryFactionMemberList`、`ReqBangPaiInfo`、退出相关入口。
- 解析：`LuaNetRecvdMsg.DealMsgBangPaiOption`；旧客户端同样按 `uint64` 读取成员战力。
- 数据与 UI：`View/BangPai/BangPaiUI.lua`、`BangPaiListPage.lua`、`BangPaiMemList.lua`、`BangPaiInfoUI.lua`。
- 主界面入口：`UImainLayer_new` 的 `Layer/Main_UI/ButtonGroup3/btn_bangpai`。
- 真实 Cocos 资源：`csd/bangpai/GangsApplyLayer.csb`、`GangsLayer.csb`、`GangsMemberLayer.csb`、`GangsfoundLayer.csb`。
- Unity 对应 Prefab 位于 `Assets/ProjectX/res/csd/Prefabs/bangpai/`；本阶段未修改四个 Prefab。

## 实现

- `GuildStore.cs` 保存帮派列表、当前帮派和成员；成员引用通用 `PlayerSummary`。
- `GuildController.lua.txt` 负责 `/54 op=1/2/10/12/13` 请求、严格字段读取和验证状态机。
- `GuildPresenter.cs` 复用 `VirtualList` 渲染帮派/成员列表，运行时绑定创建、成员、退出按钮，并修复导入按钮文字层级与职称列宽。
- 复用现有 `UiStack`、错误/Toast、红点后续入口和通用玩家摘要；未新增奖励或玩家平行模型。
- `ProtocolRegistry`、`GameServices`、`ProjectXApp`、Lua Bootstrap、场景装配和统一 Runner 已接线；切号/销毁会清理 GuildStore。

## 验证

- 最终隔离账号：`userId=7200003`；角色名 `U00003`；创建帮派 `验00003`。`7200000/7200001/7200002` 均不作为最终证据。
- 权威闭环：`op=13` 空态 + `op=2` 列表 → `op=1` 创建 → `op=13` 帮派状态 → `op=10` 单成员列表 → `op=12` 退出/解散 → `op=13` 持久化空态。
- Unity：最终 BatchMode 编译、Bootstrap 重建和运行通过，严重异常 `0`。
- GameView：成员态与最终无帮派列表态均为 `1334×750`；成员字段、底部按钮、列表和空态入口完整可见。
- UI 自动化：`python -m unittest discover -s tools/ui_migration/tests -v`，`10/10` 通过。
- 结果：`.local/unity-validation/guild-latest.json`；截图：`build/ui-migration/bootstrap-guild-members.png`、`bootstrap-guild.png`。
- 阶段结束 Unity、`kapai.exe`、workspace-local MySQL 均关闭；`3306/8711` 无监听。

## 遗留

- 申请→管理员批准/自动加入、邀请、踢人、职位和公告修改尚未形成双账号正向闭环。
- `/30/31` Guild 专属红点、奖励/捐献和帮派任务仍复用现有通用能力边界，后续按子模块单独验证。
- `/80 PRO_MY_BANG` 是另一条“我的帮派”全量协议，本阶段按用户指定只迁移 `/54`，未混入。

## 关键坑

- `/54` 多数响应直接复用请求消息并在尾部追加字段，不应假设统一 `success + reason` 包头。
- `op=13` 的 `legacyId` 被服务端显式截为 `uint16`，Unity 按线上真实包兼容，不擅自改协议。
- 变更验证必须使用单成员新帮派；退出会触发解散，避免遗留帮派污染后续角色。
- 导入 Prefab 保持只读；按钮文字遮挡、职称裁剪均在 Presenter 运行时修复。
