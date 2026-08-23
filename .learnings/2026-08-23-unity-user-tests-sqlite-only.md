# Unity 用户测试数据源纠正

- 错误：Hero 早期 Play 为用户启动 SQLite 自管服务，却把等级和五神将夹具写入 `fxl_game_local` MySQL。
- 根因：沿用旧 fixed-account MySQL 适配器，没有先核对 `LocalServerSupervisor.CreateDefault()` 的实际启动参数与 `projectx.db` 身份映射。
- 规则：用户参与的 Unity Editor/Player 测试只认 `Application.persistentDataPath/LocalServer/projectx.db`；所有测试数据只能写 SQLite。MySQL 只作离线兼容对照。
- 执行前检查：先核对目标 `kapai.exe` 命令行含 `--sqlite`、数据库绝对路径、`user_info1.role0` 和目标 `role_info.id`，再允许夹具 Setup。
