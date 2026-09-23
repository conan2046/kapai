# Unity 数据目录迁移审计

审计日期：2026-09-23  
审计范围：`unitydata`、`unityclient/Assets/ProjectX/Resources/ProjectXData`、`unityserver`、`unitydata/tools` 及相关运行/验证引用。

## 1. 审计结论

当前工程已经实现了“Unity 独立数据链路”，但实际目录比早期规划更细：

```text
unitydata/export/client/source
unitydata/excel
unitydata/export/server/generated/json_server
unitydata/export/server/authoritative/json
    -> unitydata/tools/*.ps1
    -> unityclient/Assets/ProjectX/Resources/ProjectXData
    -> unityserver/config/json
```

因此，早期规划中的：

```text
unitydata/excel
unitydata/export
unitydata/tools
```

可以作为目标别名，但不能直接删除或覆盖当前 `client/source`、`server/source` 分层。当前结构保留了客户端/服务端隔离、原始导出、中间产物和权威覆盖，信息更完整。

## 2. 当前资产盘点

| 路径 | 文件数 | 体积 | 结论 |
|---|---:|---:|---|
| `unitydata/export/client/source` | 107 | 14.75 MB | Unity 客户端正式源数据 |
| `unitydata/excel` | 58 | 2.17 MB | Unity 服务端 Excel 输入副本 |
| `unitydata/export/server/generated/json_server` | 56 | 4.27 MB | 导表原始中间结果 |
| `unitydata/export/server/authoritative/json` | 11 | 0.49 MB | Unity 服务端权威覆盖表 |
| `unityserver/config/json` | 70 | 4.33 MB | Unity 服务端实际运行 JSON |
| `unityserver/config/xml` | 76 | 3.64 MB | 已验收 XML 基线 |
| `unityserver/config/dat` | 42 | 0.03 MB | 地图/DAT 基线 |
| `unitydata/tools` | 3 个入口文件 | 6.09 MB | 导表工具及内置转换器 |

`unityserver/script` 和 `unityserver/sql` 不是空目录占位：Unity 服务运行时实际依赖 Lua 脚本与 SQLite schema，因此已从原版运行时源同步为 Unity 运行时快照；原版 `server/script`、`server/sql` 仍保留为 Cocos/原版链路源目录。

## 3. 已确认的硬引用

以下代码直接依赖当前路径：

- `unitydata/tools/Export-UnityClientData.ps1`
  - 源：`unitydata/export/client/source`
  - 目标：`unityclient/Assets/ProjectX/Resources/ProjectXData`
- `unitydata/tools/Export-UnityServerData.ps1`
  - Excel：`unitydata/excel`
  - 中间产物：`unitydata/export/server/generated/json_server`
  - 权威覆盖：`unitydata/export/server/authoritative/json`
  - 运行目标：`unityserver/config/json`
- `unityclient/Assets/ProjectX/src/Editor/BootstrapSceneBuilder.cs`
  - 直接读取 `unitydata/export/client/source`
- `unityclient/Assets/ProjectX/src/Core/LocalServerSupervisor.cs`
  - 直接读取 `unityserver/config`
- `unityclient/Assets/ProjectX/src/Editor/SteamWindowsBuild.cs`
  - 直接读取 `unityserver/config`
- `tools/unity-migration/` 下的模块清单、验证脚本和路径合同
  - 大量直接引用 `unityclient/Assets/ProjectX/Resources/ProjectXData`

## 4. 已执行迁移

已完成目录迁移：

```text
unitydata/server/source/excel/json       -> unitydata/excel
unitydata/client/source                  -> unitydata/export/client/source
unitydata/server/source/generated        -> unitydata/export/server/generated
unitydata/server/source/authoritative    -> unitydata/export/server/authoritative
tools/unity-data                         -> unitydata/tools
```

与 `unityserver/config` 完全重复的旧运行配置已移入 `.local/archive/20260923-data-layout-pre-migration/`，没有直接删除。

已更新导表脚本、Unity Editor 路径、验证工具和文档引用；运行时代码与工具中的旧路径检索结果为 0，审计文档保留迁移前后映射作为记录。

已完成迁移后验证：

1. 客户端导出 54/54 文件，源与 Unity Resources SHA-256 全一致。
2. 服务端导表 56 文件，11 张权威覆盖，`unresolved=0`。
3. Unity C# 编译 0 错误、81 个既有警告。
4. Unity Editor Play 启动后 Console 无错误/警告；独立使用 `unityserver/config`、`unityserver/script`、`unityserver/sql/sqlite` 启动服务成功：Lua 配置加载完成、SQLite `integrity=ok`、8711 监听正常，未再出现缺失 `../script/10000.lua`。
5. 真实窗口运行验证通过：点击“新的开始”后进入角色创建界面，Unity 自动拉起 `kapai.exe`，8711 处于 Listen，服务端日志确认 SQLite 与配置初始化完成；退出 Play 后服务进程和端口均已清理。运行截图保存在 `.local/unity-migration/after-new-game.png`、`.local/unity-migration/after-enter-game.png`。

## 5. 当前禁止操作

- 不再把 `unitydata/export/server` 平铺成 `unitydata/excel`；当前分层已作为正式结构保留。
- 不删除 `generated` 或 `authoritative`，它们承担导表审计和基线覆盖职责。
- `unityserver/script` 与 `unityserver/sql/sqlite` 已按实际运行依赖同步；未迁移历史 MySQL SQL，避免扩大 Cocos/原版服务端边界。
- `Export-UnityClientData.ps1 -CleanOutput` 会触发 Unity 重写 `.meta` 空字段；验证后必须检查并清理尾空格。

## 6. 未完成验证

现有 `Test-UnityMigrationToolchain.ps1` 仍被一个与本次目录迁移无关的既有断言阻塞：

```text
Gameplay hub regression again treats a page=0 direct destination route as a visible lobby card.
```

该问题未修改，不能作为本次目录迁移的通过证据。角色名输入未继续完成：Windows 输入法接管了文本焦点，未提交空角色名；这不影响本次目录、导表、服务启动和进入角色创建界面的验收结论。
