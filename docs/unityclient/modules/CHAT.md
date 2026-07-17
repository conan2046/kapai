# Chat 聊天模块

> 状态：第一阶段完成。

## 范围

- `/26 PRO_MSG_CHAT` 世界、队伍、帮派、私聊频道模型。
- 世界消息发送与本地即时呈现。
- 世界/私聊服务端回包、私聊完整玩家摘要、发送错误包。
- `MainChatLayer.prefab`、消息列表、频道切换、输入框、发送入口和错误态。
- 首阶段不包含历史消息服务、语音、表情、喇叭、跨服聊天以及 Team/Guild 业务。

## 三方证据

- 协议：`server/src/protocol.h` 的 `PRO_MSG_CHAT = 26`。
- 服务端：`server/src/pack_deal.cpp::UserChat`；请求为 `channel + content + targetType + optional roleId/name`。
- 普通回包：`channel + roleId + name + vip + head + sex + content`。
- 私聊回包：频道 `7`，附加等级、队伍、帮派、接收者和服务器时间。
- 错误回包：频道 `8 + originalChannel + result + message`。
- 旧客户端：`LuaNetSendMsg:QuerySendChatMsg/QuerySendPriateMsg`、`LuaNetRecvdMsg.DealMsgChatMsg`、`LChatMsgNode:DecodeFromServer`。
- 入口：旧主界面 `btn_chat`；当前正式主界面缺该节点，运行时补可见聊天入口。
- Prefab：`unityclient/Assets/ProjectX/res/csd/Prefabs/MainChatLayer.prefab`，源为 `cocosstudio/csd/MainChatLayer.csd`。
- 完整取证草稿：`.local/protocol-evidence/26.md`。

## 实现

- `Data/ChatStore.cs`：最多 200 条权威消息、频道模型、错误态、世界本地回显/服务端回包去重、私聊自身双发去重。
- `Data/ChatCatalog.cs`：频道显示名。
- `UI/ChatPresenter.cs`：在导入 Prefab 内运行时绑定频道、滚动消息、输入和发送，不覆盖 Prefab。
- `Resources/Lua/Chat/ChatController.lua.txt`：`/26` 编解码、发送、私聊、错误包和自动化状态机。
- `ProjectXApp/GameServices/ProtocolRegistry/BootstrapSceneBuilder/BootstrapAppRunner`：Store、入口、协议、场景和截图门禁接线。
- 正式主界面没有转换出的 Chat 节点；`ProjectXApp` 运行时增加“聊天”按钮，保持手工 Prefab 只读。

## 验证

- 最终隔离账号：`userId=7200024`，角色 `1000092`。
- 闭环：世界发送/服务端回包去重 → 私聊自身真实回包/双发去重 → 无效角色错误包。
- 最终权威消息：2 条；错误态明确显示“该玩家已下线”。
- Unity BatchMode 编译、场景重建、PlayMode 自动化通过。
- GameView：`build/ui-migration/bootstrap-chat.png`，`1334×750`，频道、消息、输入、发送、错误态无遮挡。
- UI 迁移测试：`10/10`。
- 摘要：`.local/unity-validation/chat-latest.json`，`success=true`。
- 阶段结束：Unity、Cocos、`kapai.exe`、workspace-local MySQL 均关闭；3306/8711 无监听。

## 遗留

- Team/Guild 完成后开放真实队伍/帮派频道可用性判断。
- 私聊目标选择、会话列表、未读红点和 FriendStore 好友摘要联动。
- 历史消息持久化、系统频道、跨服、喇叭、表情、语音及内容合规过滤。

## 关键坑

- `/26` 是广播型协议，不能按普通“一请求一响应”登记超时队列。
- 世界消息可能返回发送者，本地回显必须与真实回包合并。
- 私聊自己时服务端对收发双方各发送一次，Store 必须确定性去重。
- 场景装配新增 Prefab 后必须先运行 `BootstrapSceneBuilder.BuildBatch`，模块验证不会自动重建旧场景。
