# Unity 独立数据

本目录是 Unity 版本独立维护的数据根目录，不读取或反向覆盖 `concept/data/excel`、`client/ProjectX/src/ConfigData`、`server/config`。

## 当前客户端链路

```text
unitydata/export/client/source
    -> unitydata/tools/Export-UnityClientData.ps1
    -> unityclient/Assets/Resources/ProjectXData
```

`export/client/source` 是本次客户端迁移建立的 Unity 独立基线快照，包含 54 个当前 Unity 运行所需的数据文件。后续策划 Excel 和 Unity 专用导出工具应接入此目录，不再从 Cocos 或旧服务端目录复制。

宝箱预览表 `World/reward_fixed_dat.txt` 由客户端导出工具从 Unity Excel 的服务端中间产物 `export/server/generated/json_server/reward_fixed.json` 生成，并检查与 `unityserver/config/json/reward_fixed.json` 一致，避免客户端预览与实际奖励不同。仅同步该表可用 `Export-UnityClientData.ps1 -OnlyWorldBoxRewards`。

全量导出校验相对路径与文件哈希；内容未变时不重写文件。`-CleanOutput` 仅删除输出目录内数据源已不存在的数据文件，保留目录和全部 `.meta`，避免已有 Unity GUID/Importer 配置丢失。宝箱模式只同步宝箱预览表，不清理其他输出。

历史 Fish G0 同步入口 `tools/unity-migration/Sync-FishConfig.mjs` 已停用并归档，不再向原版 `server` 或旧 Unity Assets 目录回填。钓鱼客户端三表使用当前独立数据源；服务端三表暂保留 `unityserver/config/json` 基线，尚未接入 Unity 专用 Excel 导出，不能把历史 G0 数据当作当前导出输入。

```powershell
& .\unitydata\tools\Export-UnityClientData.ps1
& .\unitydata\tools\Export-UnityClientData.ps1 -OnlyWorldBoxRewards
& .\unitydata\tools\Export-UnityClientData.ps1 -CleanOutput
```

## 目录约定

- `export/client/source/Configs`：客户端 JSON/XML 配置
- `export/client/source/Tasks`：Unity 任务配置
- `export/client/source/World`：Unity 世界与培养 TXT 配置
- 神将升级门槛由客户端导出器从正式服务端中间产物`exp.json`生成`Configs/hero-level-exp.json`，并核对当前`unityserver/config/json/exp.json`；培养显示与红点共用，避免旧Cocos经验曲线与单机服务端不同。
- 神将突破同样从正式`break/quality/hero.json`生成`Configs/hero-break.json`并核对当前服务端；按真实神将品质缩放费用，按钮显示和红点共用。
- 神将升星从正式`star/hero.json`生成`Configs/hero-star.json`并核对当前服务端；专属碎片ID、品质费用、下一星级存在性供按钮和红点共用。
- 神将修炼从权威`xiulian.json`及正式config的`xiulian_attr/xiulian_cost`生成`Configs/hero-cultivation.json`并核对当前服务端；训练剩余次数与激活消耗分开判定，不使用固定400次或强制最少1次。
- 神将图鉴继续使用正式handbook/star/quality/hero四张客户端JSON，导出时核对当前Unity服务端；图鉴快照、拥有状态、星级门槛及材料资格供卡片/按钮与主入口共用。
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
