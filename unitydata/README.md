# Unity 独立数据

本目录是 Unity 版本独立维护的数据根目录，不读取或反向覆盖 `concept/data/excel`、`client/ProjectX/src/ConfigData`、`server/config`。

## 当前客户端链路

```text
unitydata/export/client/source
    -> unitydata/tools/Export-UnityClientData.ps1
    -> unityclient/Assets/ProjectX/Resources/ProjectXData
```

`export/client/source` 是本次客户端迁移建立的 Unity 独立基线快照，包含 54 个当前 Unity 运行所需的数据文件。后续策划 Excel 和 Unity 专用导出工具应接入此目录，不再从 Cocos 或旧服务端目录复制。

## 目录约定

- `export/client/source/Configs`：客户端 JSON/XML 配置
- `export/client/source/Tasks`：Unity 任务配置
- `export/client/source/World`：Unity 世界与培养 TXT 配置
- `export/client/source/Battle`：Unity 战斗表现 DAT/TXT 配置
- `export/client/`：Unity 客户端数据导出工作区

服务端数据另建 `unityserver`，不得写入本目录。

## 当前服务端链路

```text
unitydata/excel/*.xlsx
    -> unitydata/tools/vendor/xl转表.exe
    -> unitydata/tools/Export-UnityServerData.ps1
    -> unitydata/export/server/generated/json_server
    -> unitydata/export/server/authoritative/json 覆盖 11 张服务端权威表
    -> unityserver/config/json
```

`unitydata/excel` 保存 Unity 自有的 58 个正式 Excel 输入副本，转换器也复制到 Unity 工具目录，不依赖外部 `concept` 路径。`unitydata/export/server/generated/json_server` 是每次导表的原始中间产物。

`unitydata/export/server/authoritative/json` 保存当前 Unity 服务端基线中的 11 张权威快照：`daily`、`drop_matching`、`function`、`item`、`level_reward`、`mission_dialog`、`reward`、`sevendays`、`shop_config`、`shop`、`xiulian`。这些表以现有服务器数据为准，覆盖原始 Excel 转换结果；原始 Excel 差异仍记录在 `.local/unityserver-export/latest.json`，但不会再阻断导表。使用 `-ApplyGeneratedJson` 会把合并后的结果同步到 `unityserver/config/json`。

服务端 XML 与地图文件暂保持已验收基线，待补齐对应 XML/地图专用转换器后再纳入同一条链路。服务端运行所需的 3 个 DLL 位于 `unityserver/runtime`，不属于策划数据表。

导表命令：

```powershell
& .\unitydata\tools\Export-UnityServerData.ps1 -CleanOutput
& .\unitydata\tools\Export-UnityServerData.ps1 -CleanOutput -ApplyGeneratedJson
```
