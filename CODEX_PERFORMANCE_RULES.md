# Codex 性能优化与 MCP 管理规则

> 用途：将本机已经验证有效的 Codex 卡顿防护机制迁移到其他电脑。
> 适用：Codex Desktop、Codex CLI，以及使用全局 `AGENTS.md` 和项目 `.codex/config.toml` 的本地项目。
> 原则：只迁移规则和配置意图，不迁移账号、凭据、任务记录、缓存或机器绝对路径。

## 一、已验证问题与优化目标

长任务持续写入完整搜索结果、编译日志、截图和工具原始输出，会导致：

- 任务 JSONL 文件持续膨胀。
- Codex 桌面端恢复、滚动和渲染越来越慢。
- 模型上下文被无关日志污染。
- SQLite 日志库膨胀，增加启动和维护成本。
- 多个 MCP、编译器、浏览器或测试任务并行时争抢 CPU、磁盘和内存。

本规则的目标：

1. 一个功能一个任务。
2. 大日志只落盘，不进入主对话。
3. 达到任务、日志和系统负载阈值时主动提醒。
4. 外部 MCP 默认关闭，只按项目和当前任务临时启用。
5. 阶段完成立即收口，并关闭残留工具进程。

## 二、全局行为规则

将以下内容追加到目标电脑：

```text
%USERPROFILE%\.codex\AGENTS.md
```

```markdown
## Codex 性能与 MCP 管理规则

### 会话与输出控制
- 一个功能只使用一个任务；功能验收或阶段完成后，主动提醒收口，生成 `HANDOFF` 后开启新任务。
- 大日志、完整搜索结果、测试明细和工具原始输出只保存到项目 `.local/` 或明确的临时文件，不直接写入主对话。
- 单次终端输出默认不超过 200 行；日志默认只读取尾部 100 行；超过限制时仅返回数量、文件列表和关键片段。
- 任务文件达到 15 MB 时主动预警；达到 20 MB 时停止继续堆积，提醒收口并换新任务。
- Codex `logs_2.sqlite` 达到 150 MB 时提醒检查和清理；不得在无备份的情况下直接修改内部数据库。

### 并发负载控制
- 本地轻量任务最多并行 2 个；编译、测试、浏览器自动化、Unity、图片或视频处理等重任务同时只运行 1 个。
- 未经用户明确要求，不启用子代理或并行代理。
- 新增并行任务前评估本机负载；系统 CPU 持续超过 70%、可用内存低于 16 GB 或磁盘持续高负载时，停止新增任务并提醒用户。

### MCP 默认关闭与按项目启用
- 外部或项目专用 MCP 默认关闭；核心内置工具和按需懒加载的官方能力除外。
- 进入项目后，先根据技术栈和任务判断是否确实需要 MCP；不需要时不得启动。
- 需要 MCP 时，优先通过项目 `.codex/config.toml` 临时设置 `enabled = true`，不得为单一项目长期修改全局默认值。
- 启用前向用户说明用途和可能负载；任务阶段完成、项目对话收口或 MCP 不再需要时，将项目覆盖恢复为 `enabled = false`，并结束对应残留进程。
- 不得因为项目使用某种引擎或语言就自动开启全部相关 MCP；只启用当前任务实际需要的最小集合。
```

## 三、MCP 配置层级

### 1. 全局配置

位置：

```text
%USERPROFILE%\.codex\config.toml
```

外部 MCP 在其已有配置段中增加：

```toml
enabled = false
```

示例：

```toml
[mcp_servers.funplay]
enabled = false
command = "npx"
args = ["-y", "funplay-godot-mcp@0.9.2"]

[mcp_servers.unityMCP]
enabled = false
url = "http://127.0.0.1:8080/mcp"

[mcp_servers."maker-lua-lsp"]
enabled = false
command = "C:\\path\\to\\python.exe"
args = ["-m", "maker_lua_lsp"]
```

注意：

- 不要直接覆盖另一台电脑的完整 `config.toml`。
- 不要复制本机绝对路径、Token、环境变量或私有服务地址。
- 目标电脑不存在的 MCP 不需要创建配置段。
- 核心 `node_repl` 保留，不按外部 MCP 处理。

### 2. 项目配置

位置：

```text
<项目根目录>\.codex\config.toml
```

默认关闭示例：

```toml
[mcp_servers.funplay]
enabled = false

[mcp_servers.unityMCP]
enabled = false

[mcp_servers."maker-lua-lsp"]
enabled = false
```

任务确实需要时，只开启对应项：

```toml
[mcp_servers.unityMCP]
enabled = true
```

配置变化可能需要开启新任务或重启 Codex 才能完整生效。

## 四、MCP 生命周期

| 阶段 | 操作 |
|---|---|
| 进入项目 | 判断技术栈和当前任务是否需要 MCP |
| 启用前 | 说明用途、资源消耗和预计使用阶段 |
| 执行中 | 只保留当前任务需要的最小 MCP 集合 |
| 功能验收 | 将项目覆盖恢复为 `enabled = false` |
| 任务收口 | 检查并结束残留 Node、Python、浏览器或引擎进程 |
| 切换项目 | 不继承上一项目临时开启的 MCP |
| Codex 异常退出 | 重启后额外检查一次残留进程 |

不需要每次单项测试都关闭 MCP。正确粒度是“一个功能阶段”：阶段内保持，阶段结束关闭。

## 五、会话与日志阈值

| 指标 | 阈值 | 处理 |
|---|---:|---|
| 单次终端输出 | 200 行 | 超出部分写入 `.local/` |
| 默认日志读取 | 尾部 100 行 | 需要扩大时分段读取 |
| 单任务文件 | 15 MB | 主动预警 |
| 单任务文件 | 20 MB | 生成 `HANDOFF` 并换新任务 |
| `logs_2.sqlite` | 150 MB | 备份后检查和压缩 |
| 本地轻量并行任务 | 2 个 | 禁止继续增加 |
| 本地重任务 | 1 个 | 编译、测试、浏览器、Unity等不得并行 |
| 系统 CPU | 持续 70% | 停止新增任务并提醒 |
| 可用内存 | 低于 16 GB | 停止新增任务并提醒 |

## 六、另一台电脑迁移步骤

1. 安装并启动一次 Codex，确认 `%USERPROFILE%\.codex` 已生成。
2. 完全退出 Codex。
3. 备份目标电脑原有：
   - `%USERPROFILE%\.codex\AGENTS.md`
   - `%USERPROFILE%\.codex\config.toml`
4. 将本文件第二章的性能规则追加到目标电脑全局 `AGENTS.md`。
5. 检查目标电脑已有 MCP，仅在对应配置段增加 `enabled = false`。
6. 将仓库中的 `.codex/config.toml` 随项目同步到目标电脑。
7. 重新启动 Codex。
8. 执行第七章的验收检查。

## 七、迁移后验收

使用 PowerShell 7：

```powershell
# 检查外部 MCP 残留进程
Get-CimInstance Win32_Process |
    Where-Object {
        $_.Name -in @('node.exe', 'python.exe', 'cmd.exe') -and
        $_.CommandLine -match '@taptap/maker|funplay-godot|maker_lua_lsp|unityMCP'
    } |
    Select-Object Name, ProcessId, ParentProcessId, CommandLine

# 检查日志库体量
Get-Item -LiteralPath "$env:USERPROFILE\.codex\logs_2.sqlite" |
    Select-Object FullName, @{Name='MB'; Expression={[math]::Round($_.Length / 1MB, 2)}}

# 检查任务文件总量和最大文件
$sessions = Get-ChildItem -LiteralPath "$env:USERPROFILE\.codex\sessions" -Recurse -File -Filter '*.jsonl'
$sessions |
    Sort-Object Length -Descending |
    Select-Object -First 10 FullName, @{Name='MB'; Expression={[math]::Round($_.Length / 1MB, 2)}}
```

验收标准：

- 不需要的外部 MCP 进程为 0。
- 当前任务低于 15 MB。
- 日志库低于 150 MB。
- 没有多个编译、浏览器、Unity或测试重任务同时运行。
- 项目 `.codex/config.toml` 与当前任务技术栈一致。

## 八、安全边界

禁止复制或提交：

- `%USERPROFILE%\.codex\auth.json`
- `%USERPROFILE%\.codex\.env`
- `%USERPROFILE%\.codex\sessions\`
- `%USERPROFILE%\.codex\*.sqlite*`
- `%USERPROFILE%\.codex\plugins\cache\`
- MCP Token、API Key、OAuth凭据
- 另一台电脑无法复用的绝对路径

禁止直接删除或替换正在被 Codex 使用的 SQLite 数据库。需要压缩时：

1. 完全退出 Codex，或使用支持在线备份的受控流程。
2. 先生成一致性备份。
3. 再执行 SQLite 原生压缩。
4. 完成后运行 `PRAGMA integrity_check`。
5. 验证通过后再重新启动 Codex。

## 九、推荐提示词

在另一台电脑首次使用时，将以下内容发给 Codex：

```text
请读取项目根目录 CODEX_PERFORMANCE_RULES.md，并按文档执行本机检查和配置迁移。
不要复制其他电脑的凭据、Token、SQLite、任务记录、插件缓存或绝对路径。
先备份现有 AGENTS.md 和 config.toml，再合并规则；外部 MCP 默认关闭，按当前项目和任务最小化启用。
完成后验证 MCP 残留进程、当前任务大小、日志库体量、CPU和内存，并给出结果。
```

## 十、当前仓库建议

本仓库是 Cocos2d-x + Lua 客户端、C++ 服务端项目。默认不需要：

- Godot `funplay`
- Unity MCP
- 监控错误目录 `./scripts` 的 `maker-lua-lsp`

如未来需要 Lua LSP，应针对真实目录重新配置：

- `server/script`
- `client/ProjectX/src`

不要仅因为项目包含 Lua 就自动启动所有 Lua MCP。

## 参考

- [Codex config.toml 配置参考](https://developers.openai.com/codex/config-reference#configtoml)
- [Codex AGENTS.md 指引](https://developers.openai.com/codex/concepts/customization#agents-guidance)
