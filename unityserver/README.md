# Unity Server Runtime

该目录是 Unity 单机运行时所需的服务端运行包输入，不替代 Cocos/原版服务端源目录。

- `config/`：Unity 本地服务配置与导出后的运行时配置。
- `script/`：从 `server/script/` 同步的 Lua 运行时脚本；`config/config` 的 `script_dir=../script/` 依赖此目录。
- `sql/sqlite/`：从 `server/sql/sqlite/` 同步的 SQLite schema、seed 与验证夹具；Unity 编辑器运行和发布打包只依赖其中的 SQLite 文件。

同步原则：先维护正式源目录，再通过项目工具更新本目录；禁止直接在运行时副本内修业务逻辑。`server/config`、`server/script`、`server/sql` 仍保留给 Cocos/原版链路使用。

Unity 与原版客户端共用 `server/src` 服务端源码；这不是对 Cocos 客户端或引擎的运行时依赖。服务端 CMake 不再读取 Cocos SDK 的 zlib 头文件或默认 Lua 库：zlib 使用独立 `ZLIB::ZLIB`，Lua 5.1/LuaJIT 由 `tools/local/Build-Server.ps1` 从工作区依赖提供，直接 CMake 构建须显式指定 Lua 输入。Unity 编辑器产物位于 `.local/server-build/server-win/Debug`，发布构建使用 `.local/steam-server-build/server-win`。

Unity 的 TCP 消息编码、装备/阵容 Lua 模型及文本标签转换由当前 Unity 代码执行。它们沿用既有协议与业务规则，不加载 Cocos 引擎；维护时保留字段布局、Unicode 编码、排序、奖励和文本显示语义。
