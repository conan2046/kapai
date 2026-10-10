# 红点补齐交接

完整目标继续有效：按功能入口逐个补齐全部红点，每完成一个子功能汇报。不可把本阶段当作全部完成。

目标工程`E:\neiwang_kapai\Game`，Unity项目`unityclient`。聊天cwd在C盘worktree，所有实际改动均在E盘。禁止提交/推送，保留已有脏改动、Prefab、meta和Captures。

## 收口原因

本聊天任务文件`rollout-2026-10-09T23-01-07-01a1212e-a3cf-7f20-ad7a-8ccfef003c07.jsonl`为22.90 MB，超过用户提供AGENTS第十三节20 MB停止线。停止继续验收，换新聊天续做；不是目标完成。

## 当前状态

- 主角境界/背包/邮件链、神将碎片，以及升级/突破/升星/修炼培养链已完成技术实操、SQLite、重登和隔离档清理。用户最终画面确认待完成。
- 图鉴代码已接入，116项规则测试通过，编译/Console无错误。现有handbook/star/quality/hero配置逐表与当前服务端一致。
- 图鉴后台同步实际成功：角色1000799，仅图鉴免费激活条件成立时，HUD/神将页签点true，布阵页签false。
- 首次进入神将列表发现图鉴入口cell的Prompt被初始化清掉；已修ApplyHeroHubTabRedDots重新应用图鉴入口状态并编译通过。修正后的实操尚未继续，图鉴不得标完成。
- 仍未处理：图鉴后续实操、布阵业务提醒；随后装备、招募、副本、九个有效玩法、商店/回收。以RED_DOT_REPAIR.md为进度主表，不修改迁移门禁或历史完成率。

## 图鉴实现

- function1090=35级，showUpcoming=false，已在正式客户端源输入补入并走现有导出器。
- HeroBookStore增加权威状态与PendingHeroId；Catalog.CanUpgrade共用资格，拥有/解锁/配置/星级/材料/请求中共同判断。免费激活与升级分开。
- hero.book.activate/upgrade→hero.roster.book→神将页签→共享HUD；图鉴入口在神将列表cell，不把图鉴点塞到神将培养按钮或布阵页签。
- Main后台预载/322；131服务端提示触发权威快照，不直接写UI。快照不导航。
- HeroBookPresenter卡片、按钮、确认弹窗接入红点；升级配方弹窗允许查看条件，但确认必须可执行；请求串行，其他目标提醒保留。
- Lua HeroBookController维护单目标pending，失败/成功清理；普通失败不清业务资格。原有结果弹窗与保持图鉴页面逻辑保留。

## 隔离存档检查点

原Slot01未改：数据库SHA256 `457e959d35ba652cdd87f78dce272725157591ff1f67e6ec5138182755d4ae3e`，metadata `f0941e4e34bfd6dcfa276c510d361343549bf7e171a4fa6871aae271de6bd93b`。

账号9100799/角色1000799，神将57等级1星2，图鉴空、金币0、853×20。尚未激活或消耗。Fixture Setup已执行一次，禁止再次Setup。测试Slot09收口归档至`.local/red-dot-audit-20261009/hero-book-unconsumed-test-slot09`，续验时检查当前Slot09为空、kapai已退出，再用原生Move-Item恢复归档到`C:\Users\Admin\AppData\LocalLow\Xuancai\ProjectX\Saves\Slot09`；这属于恢复检查点，不重新生成夹具。

后续实际路径：旧的回忆→滚动Slot09→进入→阵容btn_zhenrong→神将Button2_Runtime→图鉴cell。先确认cell红点已修，再进图鉴。免费激活57（0→1，不耗853），关闭结果弹窗，仍满足升级则保留点。打开升级弹窗真实确认（1→2，853剩10）；虽剩10足够下一次，但神将星2不满足下一图鉴3级，卡片/入口/页签/HUD应全部灭。用SQLite证明user_book解压为[(57,2)]，853剩10；重登一致后归档测试Slot09，验证原Slot01哈希及无服务器残留。

## 工具与证据

- 使用unity-mcp-orchestrator；Unity进程22216已开于E项目，本轮未启动Editor，不要结束它；本轮Play已停止，测试服务器未运行。
- Unity MCP preexisting enabled=true，URL `http://127.0.0.1:8080/mcp`；只用当前实际需要的工具。
- execute_code参数action=execute；真实输入必须EventSystem/Raycast命中Button后发pointerDown/up/click，不使用onClick.Invoke或内部业务方法代替入口。
- refresh_unity(scope=all,mode=force,compile=request,wait_for_ready=true)；read_console类型error。截图放`unityclient/Captures/Editor/RedDotRepair`。
- `.local/red-dot-audit-20261009/hero_book_fixture.py`：setup已用，续验只用assert_result。assert_unconsumed用于本次收口。原记录hero-book-fixture.json保持不变。
- 项目Git使用`C:\Program Files\Git\cmd\git.exe`；Python使用`C:\Users\Admin\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- 最新服务端Debug为`.local/server-build/server-win/Debug/kapai.exe`，SHA256 `540742CBABDE0D4EACDCBEA0DDF567ECC587E21A5E8C48570214797B31FD5D6F`。上一子功能已修修炼数组片段解析与op12 uint8数量，普通拒绝非Fatal；源码改动不得丢失。不要再重建无相关变化的服务端。

新聊天先核对工程/进程/存档/脏状态，然后从图鉴检查点继续，不重做已有效的培养路线。
