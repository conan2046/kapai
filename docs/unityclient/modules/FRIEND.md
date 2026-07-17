# 好友模块

> 状态：第一阶段完成。最后验证：2026-07-17。

## 范围

- 好友列表、申请列表、玩家摘要与空态。
- 按角色 ID 添加、同意、拒绝、删除。
- 重复申请、非法状态等服务端错误以清理颜色标签后的 Toast 明确显示。
- 赠送、聊天、黑名单、推荐/搜索、一键处理留待后续阶段。

## 三方证据

### 服务端

- `server/src/protocol.h`：`PRO_Friend = 27`。
- `server/src/pack_deal.cpp`：`FriendOption` 注册 `/27`；本阶段 op 为 `1列表、2申请、3添加、4同意/拒绝、10删除、31好友变化推送`。
- `server/src/friend.cpp`：列表字段为 `roleId/name/level/sex/head/power/offlineSeconds/guildId/guildName`；好友列表额外带 `intimacy/sendFlag`。
- op `3/4/10` 回包保留请求中的 `roleId`（op4 还保留 `accept`），随后追加 `success + message`；op31 为 `changeType + roleId`，收到后重拉权威列表。

### 旧客户端

- 请求：`client/ProjectX/src/NetWork/LuaNetSendMsg.lua` 的 `QueryFriendList/QueryFriendApplyList/QueryAddFriend/QueryAddFriendAct/QuertDelFriend`。
- 解析：`LuaNetRecvdMsg.DealFriends`、`LSocialData.DecodeFriendList/DecodeApplyList`、`LFriendsData.DecodeFromServer/DecodeApplyDataFromServer`。
- 入口：`MainUI.lua` 的 `btn_friend`；模块映射为 `Social.FriendLayer`。
- Prefab：`unityclient/Assets/ProjectX/res/csd/Prefabs/common/FriendLayer.prefab`，主界面路径 `Layer/Main_UI/ButtonGroup7/btn_friend`。

### 真实协议

- `tools/local/Invoke-ProtocolSmoke.ps1` 新增 `-FriendApplyRoleId`，可用隔离角色发送 `/27 op=3` 并校验匹配成功回包。
- 最终验收 userId `7200018`；目标角色 `1000087`，申请方 `1000088/1000089`。
- 闭环：拒绝 `1000089` → 主角色向其添加 → 重复申请收到显式错误 → 同意 `1000088` → 列表出现 → 删除 → 好友/申请列表持久化为空。

## 实现

- `Data/FriendStore.cs`：好友、申请双权威集合，最大数量、排序、删除和切号清理。
- `Resources/Lua/Friend/FriendController.lua.txt`：`/27` 请求、解析、op31 重拉、错误提示及自动化状态机。
- `UI/FriendPresenter.cs`：复用导入 Prefab；VirtualList 渲染列表/申请；同意、拒绝、删除、按 ID 添加；运行时黑色遮罩、空态文字和空态添加入口。
- `GameServices/ProjectXApp/ProtocolRegistry/BootstrapSceneBuilder/LoginView/Bootstrap`：服务、协议、Lua、主界面按钮、UiStack、场景和切号清理接线。
- `BootstrapAppRunner`：Friend UI、截图、Esc 返回门禁。
- `Run-UnityModuleValidation.ps1`：三隔离角色准备、ISO UTC 新鲜度解析与 Friend summary 字段。

## 验证

- 文档门禁：`Unity migration docs passed: 9 modules, no consistency failures`。
- Unity 编译/场景：BatchMode `UnityExitCode=0`，严重异常 `0`。
- 统一验收：`Run-UnityModuleValidation.ps1 -Module Friend` 成功。
- 结果：`.local/unity-validation/friend-latest.json`，`success=true`。
- UI 转换测试：`10/10`。
- 截图：`bootstrap-friend-list.png`、`bootstrap-friend.png`，均为 `1334×750`；列表态、持久化空态、空态添加入口、Esc 返回均通过。
- 阶段结束：Unity、Cocos、`kapai.exe`、workspace-local MySQL 全部关闭；3306/8711 无监听。

## 遗留项

- 好友赠送/领取、一键处理、推荐/搜索、黑名单。
- 头像目前保留导入 Prefab 占位，后续接角色头像 Catalog/ResourceService。
- 聊天、队伍、帮派在 FriendStore 玩家摘要模型上继续扩展。

## 关键坑

- Unity 2022.3 运行时内置字体必须使用 `LegacyRuntime.ttf`，不能使用已废弃的 `Arial.ttf`。
- PowerShell 7 的 `ConvertFrom-Json` 会把 ISO UTC 自动转为 `DateTime`；不能先转字符串再按本地时区二次解析。
- 原 Prefab 的旧空态插画在独立弹层尺寸下会溢出；保持 Prefab 只读，用运行时空态文字/按钮覆盖。
