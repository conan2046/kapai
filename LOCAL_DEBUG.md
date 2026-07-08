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
