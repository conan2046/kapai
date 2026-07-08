# kapai（联网卡牌游戏）

Cocos2d-x + Lua 前端、C++ 后端的联网卡牌游戏源码仓库。

## 仓库内容
- `client/`：Cocos 客户端源码（Lua 逻辑 + C++ 工程）；美术/音频/动画/字体资源经 **Git LFS** 管理
- `server/`：C++ 游戏服 + Lua 脚本
- `tools/local/`：本地一键构建 / 启动 / 协议冒烟脚本
- 文档：`AGENTS.md`、`LOCAL_RUN.md`、`LOCAL_DEBUG.md`、`PROTOCOL_COVERAGE.md`

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
| Cocos2d-x 引擎 | `client/ProjectX/frameworks/` | 约 3.3G | 内部 2.17 快照，请从团队内部源获取并解压到该目录 |
| vcpkg | `tools/local/vcpkg/` | 约 1.6G | `git clone https://github.com/microsoft/vcpkg.git` 后切到 commit `a7bd303`（2026-07-05） |

> 引擎与依赖体积大、含第三方代码，按团队约定不入库；克隆后需自行补齐上述目录才能编译运行。

## 本地运行
详见 `LOCAL_RUN.md` 与 `AGENTS.md`（登录服旁路、本地测试开关 `local_test=1`、`AppDef.LOCAL_TEST` 等）。

## 目录约定（均不入库，见 `.gitignore`）
`build/`（构建产物）、`.local/`（本地 MySQL 数据）、`logs/`、`client/ProjectX/simulator/`（模拟器运行产物）、`client/ProjectX/frameworks/`（引擎）、`tools/local/vcpkg/`（依赖）、`.workbuddy/`（智能体记忆）。
