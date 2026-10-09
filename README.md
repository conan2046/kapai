# kapai（联网卡牌游戏）

Cocos2d-x + Lua 前端、C++ 后端的联网卡牌游戏源码仓库。

## 仓库内容
- `client/`：Cocos 客户端源码（Lua 逻辑 + C++ 工程）；美术/音频/动画/字体资源经 **Git LFS** 管理
- `server/`：C++ 游戏服 + Lua 脚本
- `unityclient/`：Unity 客户端工程；Unity 本机缓存不纳入交接和备份
- `unityserver/`：Unity 本地服务端运行时及配置，与 `server/config/` 分开维护
- `tools/local/`：本地一键构建 / 启动 / 协议冒烟脚本
- `tools/README.md`：工具目录职责与新增工具放置规则
- `build/README.md`：构建出口、保留规则和清理边界
- `unityserver/config/README.md`：Unity 服务端配置源、导出和运行边界
- 文档：`AGENTS.md`、`PROJECT_STRUCTURE.md`、`LOCAL_RUN.md`、`LOCAL_DEBUG.md`、`PROTOCOL_COVERAGE.md`
- Unity 迁移：`UNITYCLIENT_STATUS.md`（唯一状态源）→ `docs/unityclient/MIGRATION_GUIDE.md`（唯一流程与标准）→ `docs/unityclient/modules/README.md` → 目标模块文档/矩阵
- Unity 迁移工具：`tools/unity-migration/README.md`（Manifest、脚手架、协议取证、统一验收、文档门禁）

## 克隆（含 LFS 资源）
```bash
git clone <repo-url>
git lfs install
git lfs pull
```
资源（png/jpg/ttf/mp3/ani/csb/dat/csi 等）通过 LFS 拉取，普通 clone 不含实际二进制。

## 必须另行获取的外部依赖（本仓库不含）
| 依赖 | 路径 | 体积 | 获取方式 |
| --- | --- | --- | --- |
| Cocos2d-x 引擎 | `client/ProjectX/frameworks/` | 约 3.3G | 内部 3.17 快照，请从团队内部源获取并解压到该目录 |
| vcpkg | `tools/local/vcpkg/` | 约 1.6G | 运行 `tools/local/Install-LocalDeps.ps1 -IncludeBoost`，脚本固定到 commit `a7bd30319eeac16afbe18d64a855303a0a425e84` |

> 引擎与依赖体积大、含第三方代码，按团队约定不入库。Cocos 引擎只用于原版客户端；Unity 工程及本地服务端不需要该引擎。

## Unity 新成员运行

使用 Unity `2022.3.62f3c1`、Windows x64 和 PowerShell 7。先完成上面的 LFS 拉取，再从仓库根目录执行：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File tools/local/Install-LocalDeps.ps1 -IncludeMySql -IncludeBoost
pwsh -NoProfile -ExecutionPolicy Bypass -File tools/local/Build-Server.ps1 -BuildDir .local/server-build/server-win
```

依赖安装会准备 CMake、MSVC、LuaJIT、Boost、Zlib、SQLite 及 MySQL 客户端开发库；Unity 单机运行使用 SQLite。打开 `unityclient/`，等待包解析和资源导入完成，打开 `Assets/Scenes/Bootstrap.unity` 后点击 Play。Unity 会监管本地服务端，停止 Play 后关闭本轮服务；个人存档由单机菜单创建，无需复制他人的数据库。

`Assets/`、`Packages/`、`ProjectSettings/` 和 `unityserver/` 是版本化输入；`Library/`、`.local/`、本机存档和图集导入缓存不随 Git 分发。35 个 SpriteAtlas V2 的源资源、GUID 和分组配置已入库，首次导入或构建时由 Unity 生成打包缓存。Git 包依赖需要能访问 `Packages/manifest.json` 中的仓库地址。发布打包流程见 [`LOCAL_RUN.md`](LOCAL_RUN.md)。

服务端无需手工复制 SQL 或旧数据库。全新克隆的自动安装、建库、构建、启动命令见 `LOCAL_RUN.md` 的“全新克隆：服务端最短流程”。

## 本地运行
详见 `LOCAL_RUN.md` 与 `AGENTS.md`（登录服旁路、本地测试开关 `local_test=1`、`AppDef.LOCAL_TEST` 等）。

## 目录约定

完整职责、清理边界和构建出口见 [`PROJECT_STRUCTURE.md`](PROJECT_STRUCTURE.md)。

以下目录仅用于本机缓存、运行或构建，不进入 Git：`build/`、`.local/`、`logs/`、`client/ProjectX/simulator/`、`client/ProjectX/frameworks/`、`tools/local/vcpkg/`、`unityclient/Library/`、`unityclient/Temp/`、`unityclient/Logs/`、`.workbuddy/`。

`.local/` 中的验证证据、数据库和备份不能按普通缓存直接删除；清理前先按 `PROJECT_STRUCTURE.md` 判断保留边界。
