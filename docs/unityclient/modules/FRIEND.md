# 好友模块

> 状态：下一批，尚未取证完成。

## 目标边界

好友列表 → 申请列表 → 添加 → 同意/拒绝 → 删除。赠送、聊天和黑名单在基础状态闭环后评估。

## 启动检查

1. 先用 `Get-ProtocolEvidence.ps1` 取证候选协议，再回填 Manifest。
2. 在 `server/src/protocol.h` 确认协议号。
3. 在 `server/src/pack_deal.cpp` 确认注册和处理函数。
4. 在旧客户端查好友入口、请求、解析、红点和真实 Prefab。
5. 用只读 smoke/隔离角色确认字段和空态。
6. 明确列表、申请和玩家摘要 Store 边界。

```powershell
pwsh -File tools/unity-migration/Get-ProtocolEvidence.ps1 -Protocol <协议号> -Module Friend
pwsh -File tools/unity-migration/New-UnityMigrationModule.ps1 -Module Friend -DisplayName 好友 -WhatIf
```

## 预期复用

- PlayerStore、ResourceService、VirtualList、Toast、MessageBox、UiStack。
- 头像加载与玩家摘要模型。
- 变更型操作使用全新隔离角色，避免污染默认角色关系网。

## 完成门禁

- 列表与申请权威 Store。
- 添加/同意/拒绝/删除前后状态可复查。
- 重复申请、已是好友、人数上限等错误有明确提示。
- Esc、重复打开、断线、切号、空态和固定分辨率截图通过。
