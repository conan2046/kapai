# Unity Server Runtime

该目录是 Unity 单机运行时所需的服务端运行包输入，不替代 Cocos/原版服务端源目录。

- `config/`：Unity 本地服务配置与导出后的运行时配置。
- `script/`：从 `server/script/` 同步的 Lua 运行时脚本；`config/config` 的 `script_dir=../script/` 依赖此目录。
- `sql/sqlite/`：从 `server/sql/sqlite/` 同步的 SQLite schema、seed 与验证夹具；Unity 编辑器运行和发布打包只依赖其中的 SQLite 文件。

同步原则：先维护正式源目录，再通过项目工具更新本目录；禁止直接在运行时副本内修业务逻辑。`server/config`、`server/script`、`server/sql` 仍保留给 Cocos/原版链路使用。
