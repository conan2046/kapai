# Unity 独立数据

本目录是 Unity 版本独立维护的数据根目录，不读取或反向覆盖 `concept/data/excel`、`client/ProjectX/src/ConfigData`、`server/config`。

## 当前客户端链路

```text
unitydata/client/source
    -> tools/unity-data/Export-UnityClientData.ps1
    -> unityclient/Assets/ProjectX/Resources/ProjectXData
```

`client/source` 是本次客户端迁移建立的 Unity 独立基线快照，包含 54 个当前 Unity 运行所需的数据文件。后续策划 Excel 和 Unity 专用导出工具应接入此目录，不再从 Cocos 或旧服务端目录复制。

## 目录约定

- `client/source/Configs`：客户端 JSON/XML 配置
- `client/source/Tasks`：Unity 任务配置
- `client/source/World`：Unity 世界与培养 TXT 配置
- `client/source/Battle`：Unity 战斗表现 DAT/TXT 配置
- `client/export`：预留给后续 Unity 专用正式导出物

服务端数据另建 `unityserver`，不得写入本目录。

## 当前服务端链路

```text
unitydata/server/source/excel/json/*.xlsx
    -> tools/unity-data/vendor/xl转表.exe
    -> tools/unity-data/Export-UnityServerData.ps1
    -> unitydata/server/source/generated/json_server
    -> unitydata/server/source/authoritative/json 覆盖 11 张服务端权威表
    -> unityserver/config/json
```

`unitydata/server/source/excel/json` 保存 Unity 自有的 58 个正式 Excel 输入副本，转换器也复制到 Unity 工具目录，不依赖外部 `concept` 路径。`unitydata/server/source/generated/json_server` 是每次导表的原始中间产物。

`unitydata/server/source/authoritative/json` 保存当前 Unity 服务端基线中的 11 张权威快照：`daily`、`drop_matching`、`function`、`item`、`level_reward`、`mission_dialog`、`reward`、`sevendays`、`shop_config`、`shop`、`xiulian`。这些表以现有服务器数据为准，覆盖原始 Excel 转换结果；原始 Excel 差异仍记录在 `.local/unityserver-export/latest.json`，但不会再阻断导表。使用 `-ApplyGeneratedJson` 会把合并后的结果同步到 `unitydata/server/source/json` 和 `unityserver/config/json`。

服务端 XML 与地图文件暂保持已验收基线，待补齐对应 XML/地图专用转换器后再纳入同一条链路。服务端运行所需的 3 个 DLL 位于 `unityserver/runtime`，不属于策划数据表。

导表命令：

```powershell
& .\tools\unity-data\Export-UnityServerData.ps1 -CleanOutput
& .\tools\unity-data\Export-UnityServerData.ps1 -CleanOutput -ApplyGeneratedJson
```
