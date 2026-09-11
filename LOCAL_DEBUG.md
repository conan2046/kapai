# 本地测试服调试手册

## 固定日志扫描

```powershell
Select-String -Path .local/*.out,.local/*.err,client/ProjectX/simulator/win32/local_client.log `
  -Pattern 'error|failed|falied|assert|exception|Crash|cannot|Can not|No such|Unknown|call:|mysql|Query.*fail|失败|错误|attempt to|nil value|stack traceback|断开|连接失败|config error' `
  -CaseSensitive:$false
```

## 问题诊断速查

| 症状 | 优先排查 | 修复原则 |
|---|---|---|
| 缺 `libssl-3-x64.dll` / `libcrypto-3-x64.dll` | MySQL 8.4 bin 目录、`build/server-win/Debug`、`server/config` | 复制 `libmysql.dll` 依赖链到 exe 同目录或 `server/config` |
| `Debug Assertion Failed: vector subscript out of range` | 最近触发的协议、数组下标、配置表为空 | 修边界或本地最小配置，不屏蔽 assert |
| `call:<id> ... nil value` | `server/script/<id>.lua`、`server/src/lua_j_stub.cpp` | 只补具体缺失的 Lua 绑定或本地兜底 |
| `mysql is not connected` | 是否误查登录库 `m_loginDb/g_LoginDB` | `local_test=1` 下跳过非登录关键查询或返回空包 |
| `Unknown table/column` | `server/sql/local_min_schema.sql`、启动 bootstrap | 补最小字段，保留正式库路径 |
| 服务端启动后立即退出 | `.local/*.out/.err`、工作目录是否为 `server/config` | 先修启动依赖，再跑协议 smoke |
| 客户端卡登录 | `client/ProjectX/simulator/win32/local_client.log`、`AppDef.LOCAL_TEST`、TCP 连接 | 确认直连 `127.0.0.1:8711` 和 `DealMsgStartGame` |
| smoke 无响应但服务未崩 | 协议 body 格式、`CNetMessage` 读写顺序 | 从 `pack_deal.cpp` 对应 `*Option` 反推参数 |
| 保存线程 6-7 分钟后报错 | `SaveDataSimple/NoLockSaveData/CBangPai::Save`、Boost format 参数顺序 | 保持 SQL 占位和参数出现顺序一致 |

## 本地修复边界

- 可以：`local_test=1` 下补最小 schema、默认种子数据、Lua stub、非关键系统空响应。
- 不可以：删除线上登录/付费/活动逻辑、伪造完整登录服协议、大面积重写业务流程。
- 新增旁路必须受 `local_test=1` 控制，并在 `LOCAL_RUN.md` 或 `AGENTS.md` 记录。

## 验收口径

- “启动成功”只证明 L1。
- “客户端进主流程”只证明 L2。
- “协议 smoke 干净”只证明对应协议层覆盖，不等于人工 UI 全功能验收。
- 宣称目标完成前，必须有 L6 级证据：主要 UI 功能点人工点击或自动化点击覆盖，并且服务端/客户端日志无错误。

## Windows 本地兼容基线

- `Start-LocalMySql.ps1` 只启动 `.local/mysql-data` 下的 workspace MySQL 8.4，不安装或修改 Windows 服务。
- MSVC输出为 `build/server-win/Debug/kapai.exe`；`libmysql.dll`、`libssl-3-x64.dll`、`libcrypto-3-x64.dll` 必须位于exe同目录或 `server/config`。
- `win_compat.h`、`server/src/boost/*.hpp`、`swigluarun.h` 和POSIX shim只服务本地Windows兼容，禁止扩展成线上业务重写。
- 旧Cocos协议：`MET_Unicode` 字符串使用UTF-16LE；4字节长度为不含6字节包头的body长度；零payload命令合法。
- Windows socket发送必须保留每socket队列；不得改成单pending消息。零body合包不得清掉后续有效包。
- 已修崩溃回归：`MakeNewShenQiBaseInfo()` 不越过 `shenqiList.size()`；保存SQL参数按占位出现顺序；Rapid init响应不得丢包。
- `local_test=1` 可对缺失的非登录关键商店、活动、排行、充值、红点、帮助和登录服在线回写做空响应/降级，但必须保留正式路径。
- Lua兼容按具体 `call:` 错误补最小绑定；现有范围包括 `CUser*`、`GetFuncOpenLevel`、legacy `bit._*`、题目、日常Boss和任务星级相关接口。`server/script/75.lua` 是缺失可选弹窗脚本的本地占位。
- 本地创角允许一次性userId，默认等级99并提供测试货币；帮派创建、公告字段和题库最小schema由bootstrap修复。新增字段仍须进入最小schema，不得依赖正式库猜测。
- workspace MySQL与SQLite职责严格分开：Cocos/离线兼容使用MySQL；Unity Editor/Player用户功能测试使用 `Application.persistentDataPath/LocalServer/projectx.db`。
