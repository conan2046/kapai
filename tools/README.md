# 工具目录索引

当前先采用“文档归类、路径不变”的方式，避免直接移动目录破坏 PowerShell、Python 和 Unity 验证脚本中的相对路径。

## 目录职责

| 当前路径 | 类别 | 职责 | 是否建议移动 |
|---|---|---|---|
| `tools/local/` | 运行/构建 | 本地服务端、客户端、依赖安装、协议冒烟和本地数据库脚本 | 暂不移动，已有大量文档引用 |
| `tools/unity-migration/` | Unity 验证/迁移 | Unity 模块清单、夹具、协议取证、验收和迁移工具 | 暂不移动，作为稳定路径 |
| `unitydata/tools/` | 数据 | Unity 数据导出、配置和资源辅助工具 | 保持现状 |
| `tools/ui_migration/` | 迁移辅助 | Cocos UI/CSB 分析和导出工具 | 保持现状，后续可并入迁移工具索引 |
| `tools/cocos-audit/` | Cocos 验证 | Cocos 当前入口、资源和运行链审计 | 保持现状 |
| `tools/gm-backend/` | 后台 | GM 后台服务和测试脚本 | 保持现状 |
| `tools/steamworks_sdk_165/` | 第三方依赖 | Steamworks SDK 本机依赖 | 不移动、不入库 |
| `tools/local/vcpkg/` | 第三方依赖 | C++ 本地依赖管理和构建缓存 | 不移动、不入库 |

## 新工具放置规则

新增工具按功能放入以下现有目录：

- 服务启动、构建、协议冒烟：`tools/local/`
- Unity 夹具、模块回归、协议取证：`tools/unity-migration/`
- 配置导出、数据转换、数据检查：`unitydata/tools/` 或 `tools/local/`
- Cocos 入口、资源、UI 审计：`tools/cocos-audit/` 或 `tools/ui_migration/`
- GM 接口、后台服务、后台测试：`tools/gm-backend/`

不要在仓库根目录新增临时脚本；不要把构建输出、日志、数据库或截图放入 `tools/`。

## 后续物理整理条件

只有在以下条件同时满足时，才考虑把 `tools/ui_migration/`、`unitydata/tools/` 等目录合并：

1. 全仓库脚本和文档引用已建立清单；
2. 相对路径和输出路径完成回归；
3. Unity、Cocos、服务端本地启动链未受影响；
4. 变更可以按目录白名单提交和回滚。

当前阶段只做索引，不做目录搬迁。
