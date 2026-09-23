# Unity 服务端配置目录

本目录是 Unity 本地服务端的运行配置，不等同于 `server/config/`。

## 目录职责

| 路径 | 内容 | 处理规则 |
|---|---|---|
| `source/` | Unity 服务端导表输入源，目前包含 CSV 等源数据 | 优先维护源文件，不把运行时 JSON 当源表 |
| `json/` | Unity 服务端实际读取的 JSON 配置 | 由 `unitydata/tools/Export-UnityServerData.ps1` 生成或同步 |
| `xml/` | 已验收的 XML 运行配置 | 当前保持基线，不手工重构格式 |
| `dat/` | 地图及其他 DAT 运行数据 | 当前保持基线，需专用转换器后再纳入统一导表 |
| `config` | Unity 本地服务端启动配置 | 仅修改本地运行参数，不能替代正式配置表 |

## 正式数据链路

```text
unitydata/excel/*.xlsx
    -> unitydata/tools/Export-UnityServerData.ps1
    -> unitydata/export/server/generated/json_server
    -> unitydata/export/server/authoritative/json
    -> unityserver/config/json
```

客户端数据链路见 [`unitydata/README.md`](../../unitydata/README.md)。

## 边界

- `server/config/` 是旧 Cocos/通用服务端配置，不能直接替代本目录。
- 不要手工编辑由导表工具生成的 JSON/XML/DAT；应追溯源表和导出脚本。
- `unityserver/runtime/` 中的 DLL 是运行时依赖，不属于配置表。
- 缺少源表或转换器时，不创建临时配置、不伪造导出结果。

## 导出命令

```powershell
& .\unitydata\tools\Export-UnityServerData.ps1 -CleanOutput
& .\unitydata\tools\Export-UnityServerData.ps1 -CleanOutput -ApplyGeneratedJson
```

执行导出前确认 Unity 客户端和本地服务端没有正在使用目标配置目录；导出后按当前 Unity 功能做定向回归。
