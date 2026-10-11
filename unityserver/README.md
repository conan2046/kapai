# Unity Server Runtime

该目录是 Unity 独立服务端源码、构建入口与运行包输入；Cocos/原版服务端继续维护 `server/`。

- `config/`：Unity 本地服务配置与导出后的运行时配置。
- `src/`、`tests/`：2026-10-11 从既有服务端建立的独立源码及数据库验证基线；Unity 后续业务修改仅在本目录进行。
- `CMakeLists.txt`、`tools/Build-UnityServer.ps1`：Unity 专用构建；默认产物 `.local/unityserver-build/server-win`，发布产物 `.local/unity-steam-server-build/server-win`。
- `script/`：Unity 独立 Lua 运行时脚本；`config/config` 的 `script_dir=../script/` 依赖此目录。
- `sql/sqlite/`：Unity 独立 SQLite schema、seed 与验证夹具。

Unity 源码、脚本与SQLite schema直接维护于本目录；配置由 `unitydata` 导出。禁止将 Unity 业务修改回写 `server/` 或 Cocos 配置／源码；不再自动从原版目录覆盖本目录。

Unity 构建仅读取 `unityserver/src`，不编译 `server/src`。zlib 使用独立 `ZLIB::ZLIB`，Lua 5.1/LuaJIT由Unity专用脚本解析既有工作区依赖，直接CMake构建须显式指定Lua输入。编辑器及Steam打包均使用独立目录，拒绝复用指向原版源码的CMake缓存。

Unity 的 TCP 消息编码、装备/阵容 Lua 模型及文本标签转换由当前 Unity 代码执行。它们沿用既有协议与业务规则，不加载 Cocos 引擎；维护时保留字段布局、Unicode 编码、排序、奖励和文本显示语义。
