# 项目目录职责与清理边界

本文件是目录治理说明，不替代各模块文档、`AGENTS.md` 或 `UNITYCLIENT_STATUS.md`。

## 1. 顶层目录

| 目录 | 职责 | 处理原则 |
|---|---|---|
| `client/ProjectX/` | Cocos2d-x 客户端源码、Lua、资源和原生工程 | 源码目录，禁止批量清理 |
| `server/` | 通用/Cocos 服务端源码、协议、脚本和配置 | 源码目录，禁止用 Unity 配置替代 |
| `unityclient/` | Unity 客户端工程 | 仅共享 `Assets`、`Packages`、`ProjectSettings` 等工程源文件 |
| `unityserver/` | Unity 本地服务端运行时及配置 | 与 `server/config` 分开维护 |
| `unitydata/` | Unity 数据链路和映射说明 | 只放共享数据说明或明确的数据资产 |
| `tools/` | 构建、迁移、验证和旧项目工具 | 新工具按用途归类；Unity 专用数据导表工具已迁入 `unitydata/tools/` |
| `docs/` | 设计、流程、模块、协议和验收文档 | 正式文档目录 |
| `outputs/` | 正式交付物和最终报告 | 不放过程日志、临时截图或缓存 |
| `build/` | 可重建的构建产物 | 只保留当前需要的构建结果 |
| `.local/` | 本机运行、数据库、验证证据、备份和临时构建 | 不入库，按保留周期清理 |
| `logs/` | 根目录运行日志 | 不入库，仅保留当前诊断需要的日志 |

工具目录的详细职责和新增工具放置规则见 [`tools/README.md`](tools/README.md)。Unity 专用数据源、导出结果和导表工具已按数据链路迁入 `unitydata/`，其他工具暂保持原路径。

## 2. Unity 本机目录

以下目录是 Unity 本机缓存或编辑器状态，不进入备份和提交：

```text
unityclient/Library/
unityclient/Temp/
unityclient/Logs/
unityclient/UserSettings/
unityclient/Obj/
```

Unity 工程交接时优先交接：

```text
unityclient/Assets/
unityclient/Packages/
unityclient/ProjectSettings/
```

## 3. 配置数据边界

```text
server/config/              通用/Cocos 服务端运行配置
unityserver/config/source/  Unity 配置源数据
unityserver/config/json/    Unity JSON 配置
unityserver/config/xml/     Unity XML 配置
unityserver/config/dat/     Unity DAT/地图等运行数据
```

当前不直接移动这些目录。后续若拆分 `generated/`，必须先确认导表脚本和运行时读取路径。

Unity 服务端配置的具体数据链路见 [`unityserver/config/README.md`](unityserver/config/README.md)，Unity 独立数据根目录见 [`unitydata/README.md`](unitydata/README.md)。

## 4. `.local` 保留与清理规则

必须保留的证据或本地状态：

- `unity-validation/`
- `ui-fidelity/`
- `protocol-evidence/`
- `sqlite-backups/`
- `unity-save-backups/`
- `mysql-data/`

可按版本或时间清理的内容：

- 重复的 CMake 构建目录
- 已被更新版本替代的 `server-build*`、`steam-build*`
- 临时集成构建和编译缓存
- 旧日志和临时探针输出

清理前必须确认：没有进程正在使用目标目录，且目标不是当前验证证据或数据库。

## 5. 构建出口约定

```text
build/server/       当前可复用的服务端构建结果
build/unity/        Unity 发布构建结果（如需要）
build/cocos/        Cocos 发布构建结果（如需要）
.local/builds/      临时构建、诊断构建和失败构建
```

脚本默认不应把多个带日期或带 `final/check/check2` 后缀的构建目录长期堆在根目录或 `.local` 根层。

## 6. 禁止事项

- 不删除整个 `.local/`。
- 不把 `server/config` 和 `unityserver/config` 合并。
- 不把 Unity `Library/`、Cocos `frameworks/`、vcpkg 依赖纳入 Git。
- 不将截图、日志、数据库备份混入 `outputs/` 正式交付目录。
- 不使用 `git add -A` 处理目录清理。
