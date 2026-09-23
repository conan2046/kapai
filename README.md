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

> 引擎与依赖体积大、含第三方代码，按团队约定不入库；克隆后需自行补齐上述目录才能编译运行。

服务端无需手工复制 SQL 或旧数据库。全新克隆的自动安装、建库、构建、启动命令见 `LOCAL_RUN.md` 的“全新克隆：服务端最短流程”。

## 本地运行
详见 `LOCAL_RUN.md` 与 `AGENTS.md`（登录服旁路、本地测试开关 `local_test=1`、`AppDef.LOCAL_TEST` 等）。

## 目录约定

完整职责、清理边界和构建出口见 [`PROJECT_STRUCTURE.md`](PROJECT_STRUCTURE.md)。

以下目录仅用于本机缓存、运行或构建，不进入 Git：`build/`、`.local/`、`logs/`、`client/ProjectX/simulator/`、`client/ProjectX/frameworks/`、`tools/local/vcpkg/`、`unityclient/Library/`、`unityclient/Temp/`、`unityclient/Logs/`、`.workbuddy/`。

`.local/` 中的验证证据、数据库和备份不能按普通缓存直接删除；清理前先按 `PROJECT_STRUCTURE.md` 判断保留边界。
