# kapai 单机版 GM 后台（本地 Web 控制台）

> 纯本地开发者工具，**不会**进入游戏分发包，也**不会**暴露给玩家。
> 直接复用服务端已有的 `MSG_MGR` 管理协议（`pack_deal.cpp::ServerMgr`），不发任何游戏内 UI。

## 存档位置（重要，别找错库）

GM 后台**只走 TCP 8711**，与数据库路径无关 —— 它作用于 `kapai.exe` 当前打开的那个库。
但排查/核对数据时必须知道是哪一个：

| 场景 | 数据库路径 |
|---|---|
| **Unity Play（正常游玩）** | `%USERPROFILE%\AppData\LocalLow\Xuancai\ProjectX\Saves\SlotNN\projectx.db` |
| 默认/兜底（`LocalServerSupervisor.CreateDefault()`） | `...\ProjectX\LocalServer\projectx.db` |

实测 2026-09-14：Unity Play 起的是
`kapai.exe --sqlite "...\ProjectX\Saves\Slot03\projectx.db" --sqlite-schema "server\sql\sqlite\001_initial_schema.sql"`。
所以**发完资源要去 `Saves\SlotNN\` 那个库核对**，`LocalServer\projectx.db` 很可能是空的/旧的。

想确认当前服务端用的是哪个库：
```bash
powershell -c "Get-CimInstance Win32_Process -Filter \"Name='kapai.exe'\" | Select-Object -ExpandProperty CommandLine"
```

不同槽位的库版本可能不一致（旧槽位可能早于 `admin`/`admin_log` 建表）。
GM 登录失败时工具**不会修改数据库或重置口令**；旧槽位必须显式运行
`docs/gm-backend/migrate_admin.py`，脚本会先生成相邻备份并执行完整性检查。

## 它能做什么（2026-09-14 实机验证结果）

| 操作 | 底层 | 验证状态 | 落库证据 |
|---|---|---|---|
| 查询当前在线存档角色（只读） | `MSG_MGR` op 21 | ✅ 通过 | — |
| 加通宝/元宝 | `MSG_MGR` op 1 | ✅ 通过 | `user_info1.money` +`admin_log` |
| 改等级 | `MSG_MGR` op 5 | ✅ 通过；在线立即刷新 | `role_info.level` +`admin_log`，并推送 `/226` |
| 发资源邮件 | `MSG_MGR` op 15 | ⚠️ 部分 | 仅 `admin_log`；邮件**不会真正投递**（见下） |
| 加物品 | `MSG_MGR` op 2 | ⚠️ 有副作用 | `admin_log`；**会让 LocalServer 停止响应**（见下） |

实测（本机 `projectx.db`，角色 `1000001 / S8D01`）：op1 +5000 → `user_info1.money` 1008634→1013634；
op5 → `role_info.level` 100→101 且重登可见；两条均写 `admin_log`。

对**真实槽位存档**（`Saves\Slot03`，角色 `1000001 / Test01 / Lv1`）也复验通过：
op1 +10000 → `user_info1.money` 0→10000，`admin_log` 0→1 行（`1000001加10000通宝`）。

> 页面顶部状态灯每 3s 轮询 `/status`，所以「先开页面、后进 Unity Play」也会自动转绿，
> 不需要手动刷新。执行修改前，后台会重新查询 op 21，并拒绝非当前在线存档角色，防止误改其他槽位。

### 已知限制（服务端既有问题，非本工具缺陷）

1. **op 15 邮件不投递**：`SendSystemMail` → `SendMailToUser` 走
   `sock.SendServerMsg(EST_LONG, msg)`，单机 LocalServer 没有 server-to-server 通道，
   报文发往 `sock=-1` 后丢弃，`xin_shi` 表无新增。指令本身会执行并写 `admin_log`。
2. **op 2 加物品会让服务端停摆**：该路径触发一次发往 `sock=-1` 的推送
   （日志 `socket send sock=-1 type=15 len=19` / `socket send pending/fail sock=-1`），
   之后 LocalServer 的 accept/recv 循环不再处理任何请求，必须重启游戏。
   已在 Web 界面上标注，请**最后执行**。
3. **服务端 `md5()` 构建差异**：`gyu::util::MD5String` 在未启用 OpenSSL 时退化为
   djb2（`%032lx`）。实测本机 `kapai.exe` 的 `MD5('gm123456')` =
   `000000000000000000000000c6ae3a4e`，与标准 MD5 `b4c61ebb...` 不同。
   新库由服务端执行 `MD5()` 生成口令哈希；迁移旧库时默认使用当前 Windows
   LocalServer 的 `djb2-win32`，启用 OpenSSL 的构建需传 `--hash-mode standard-md5`。

## 前置条件

1. 本地 `LocalServer`（`kapai.exe`）**已经运行**，且配置 `local_test=1`。
   最简单的方式：进入 Unity Play，`LocalServerSupervisor` 会自动起服并监听 `8711`。
2. `projectx.db` 的 `admin` 表存在 `userId/name/pwd` 与 GM 账号。
   若用的是**已有**库，请先退出 Unity Play/停止 LocalServer，再跑迁移脚本（会自动备份）：
   ```
   python ../../docs/gm-backend/migrate_admin.py <path/to/projectx.db>
   ```
   默认 GM 账号：`userId=1 / name=gm / 口令 gm123456`。
   迁移会备份原库，且不会在终端打印明文口令。运行时登录失败只报错，不会自愈改库。
3. `gm_config.ini` 的 `server_id` 与服务端 `server.server_id` 一致（默认 1）。

## 运行

```
cd tools/gm-backend
python gm_web.py
```
或双击 `run_gm_web.bat`。启动后自动打开浏览器，默认地址 `http://127.0.0.1:8081`。

> **端口注意**：`8080` 已被 Unity MCP（`mcp-for-unity` HTTP transport）占用，不要改回 8080。
> `8081` 若也被占用，会按 `web.fallback_ports` 依次尝试 `8088,18080,8899,9000,9527`。

推荐操作顺序：进入目标存档 → `连接自检` → `查询当前在线存档角色`（自动回填 role_id）→ `加通宝` / `改等级`。
切换存档后必须重新查询；若 role_id 与当前在线角色不一致，后台会阻止执行。

## 配置（gm_config.ini）

| 项 | 含义 |
|---|---|
| `server.host` / `server.port` | LocalServer 地址，默认 `127.0.0.1:8711` |
| `server.server_id` | 必须与服务端 `server.server_id` 一致 |
| `gm.account_id` | GM 协议会话使用的本地账号 id；不再用于推断目标存档角色 |
| `gm.gm_user_id` | admin 表中的 GM 账号 userId |
| `gm.gm_password` | GM 账号口令（明文传输，服务端自行哈希后比对） |
| `web.listen_*` | Web 控制台监听地址，默认 `127.0.0.1:8081` |
| `web.auto_open` | 启动后是否自动开浏览器，`1`/`0` |

## 协议说明（逐行核对服务端源码）

```
帧头 6 字节    [uint32 LE bodyLen][uint16 LE msgType][body]   bodyLen = len(body)
字符串         [uint16 LE 字节数][UTF-16LE 字节]               长度是字节数
整数           小端
```

依据：
- `server/src/main.cpp:702` `SetNetMsgEncodeType(MET_Unicode)` → 字符串 UTF-16LE
- `server/src/main.cpp:703` `SetMsgMaxLenSize(MMS_4Byte)` → 帧头 6 字节（`m_msgTypeBegin=4`）
- `server/src/gyu/g_net_msg.cpp:129-159, 299-352` → 长度/编码语义
- `server/src/gyu/g_socket_server.cpp:184-250` → 收包与粘包解析（头长 6 时按 4 字节读 bodyLen）
- `server/src/pack_deal.cpp:780` `UserLogin` / `:11394` `ServerMgr`

响应格式：
- op 11：`[uint8 2][uint8 1=成功|2=失败][string 失败原因]`
- 其他：`[uint16 op][string retMsg]`；变更操作必须返回 `OK|...` 或 `ERR|...`
- op 21：`OK|ACTIVE|roleId|name|level`；无在线角色或同时存在多个在线角色时返回 `ERR|...`
- op 13：服务端已永久禁用，返回 `ERR|op13 raw SQL disabled`

单次动作流程：连接 → `PRO_USER_LOGIN(1001)` → `MSG_MGR op11` → op 21 核对当前在线角色 → 目标 op → 校验响应类型、op 与 `OK|/ERR|` 结果 → 关闭。任一登录失败或目标不一致立即停止。

## 安全边界

- `op 13`（裸 SQL）已从 Python 客户端移除并在服务端永久禁用。
- 变更操作只允许作用于 op 21 返回的唯一在线角色，拒绝旧页面残留或其他槽位 role_id。
- 仅监听本机回环地址，不对外网暴露。
- 依赖服务端 `local_test=1` 的免口令登录，仅适用于本地开发环境。
