# 红点全链续作交接 2026-10-10

## 目标与停止原因

2026-10-10续作已完成技术回归：摇钱树23、封神榜3、寻宝9、每日任务10、大富翁21、答题27、开心转盘29、钓鱼32，及商店/回收有效业务与排除审计。用户确认答题A/B/C/D选项不应显示红点，已移除；答题业务叶只汇总至玩法卡片/HUD。详细现状只认RED_DOT_REPAIR.md；下方旧阶段记录作为历史保留，不能重新Setup或恢复已消耗测试档。用户最终画面确认仍待完成，未改迁移门禁、未提交/推送。

## 唯一工程与安全边界

续作收尾核验：9个本批隔离档（8玩法+商店）SQLite integrity_check均ok，8条本批失败记录均resolved且证据存在；当前无Slot09、kapai或8711监听。Editor22216仍为E工程，Play已停止，编译及Console0错误。当前Debug kapai SHA256=6f54be5443b6fe7a0fcb6e2847f3a1d69815b0a326b133d21154be95534f1156。原Slot01数据库/metadata哈希与下列冻结值一致。最终清理证据.local/red-dot-audit-20261009/final-continuation-cleanup-20261010.json。MCP原由用户启用，本轮未修改配置；既有Editor保持打开。

- 工程E:\neiwang_kapai\Game，Unity项目其下unityclient，本地checkout；不另建worktree、不启用代理、不提交/推送。
- 有大量既有脏文件，保留手调Prefab/meta/Captures及其他改动。起始状态.local/red-dot-audit-20261009/status-start-20261010.txt；修改allowlist，不git add -A。
- Editor为用户原已打开E工程，收口已停止Play，保留Editor。不启动Cocos/MySQL，当前无kapai、8711监听或测试Slot09。MCP原已enabled=true，没有为此修改配置。
- Slot01始终未改：数据库457e959d35ba652cdd87f78dce272725157591ff1f67e6ec5138182755d4ae3e；metadata f0941e4e34bfd6dcfa276c510d361343549bf7e171a4fa6871aae271de6bd93b。
- 定向Bug阶段，不调用迁移门禁/更新migration-gates、矩阵、完成率。真实Unity输入只用MCP EventSystem/Raycast，不调用Presenter/onClick.Invoke/内部业务完成方法。最终画面由用户确认，不把技术证据称为视觉验收。
- 每生命周期Setup仅一次；领取前断言状态；失败保留复现；修代码后续用已消耗状态。新隔离Slot09须先确认不存在，源档只读backup，不修改生成配置。

## 已完成

进度与细节唯一入口RED_DOT_REPAIR.md。本聊天补完图鉴、布阵、装备/法宝/碎片、招募、副本、游历真实操作/SQLite/重登。前聊天主角和神将其他培养已完成技术回归，用户画面确认仍待完成。

- 图鉴role1000799：免费激活0→1、升级1→2，853剩10但星2不足下一阶3，所有图鉴/神将点false；归档hero-book-test-slot09。
- 布阵role1000899：真实空位上阵64；七星1→2后玄火点保留；玄火0→1后全灭；归档formation-test-slot09。
- 装备role1000999：红装强200/精1/觉醒1/神铸1，法宝强4/精1，10碎片合成1101，金币/材料耗尽、全链false；21独立装备规则；归档equipment-test-slot09。
- 招募role1001099：普通免费3→2进入CD，高级CD自然到期在主界面亮；普通付费拒绝不清高级点；高级1→0全部熄灭，重登保持；保留三池同时显示（用户历史偏好），无页签。跨日重查已实现，真实午夜未测试。归档recruitment-test-slot09。
- 副本role1001199：后台章节/成就/宝箱不抢页/选章；18星领取成就位图0→2；星箱20011领取后普通10011及父入口保留，普通领取后全灭；重登全灭。章节页原缺成就入口，克隆正式按钮并绑定子RuntimeHitSurface；成就动画开/关同clip，旧实现播完透明/屏外，现冻结打开帧再fit，未改手调Prefab/动画。161共享规则通过。function2旧试炼及63排除，function3封神榜放玩法。归档world-test-slot09。
- 游历role1001299：后台/335快照→到期地点/领取按钮→玩法卡片function1→HUD及World游历入口；地点1领取后2保留，2领取后全灭；地点3在主界面自然到期无需重登亮，真实入口领取后全灭、SQL剩派遣0、重登全灭；11独立边界规则通过。服务端LoadMap原解码不回填m_youLi、领奖不erase，已补最小恢复/消耗修复。新Debug构建成功，kapai SHA256 1f0a8de901b9f9f868277760f0564f8d8e4e288f704bdd325a97ab343f4d4a06；归档youli-test-slot09。C#最近补等级变化刷新卡片，编译/Console0并重登回归通过。

所有证据在.local/red-dot-audit-20261009/，按模块*-runtime-result-20261010.json和*-database-result.json读取。截图unityclient/Captures/Editor/RedDotRepair/。测试档仅归档保留结果，勿恢复重跑Setup。最后用户Editor停止Play、原Slot哈希核对通过。

## 历史续作清单（以下事项现已完成，不再执行）

建议下一项摇钱树function23，已有源码初读，尚未修改/建立夹具。其后逐项完成其余7个有效玩法：封神榜3、寻宝9、每日任务10、大富翁21、答题27、开心转盘29、钓鱼32。最终商店/回收当前有效业务及排除审计。不得启用旧试炼2、昆仑7、Arena/Blood商店等SteamExcluded入口，不进入Payment迁移，不因付费可购买制造待办提醒。

玩法总树已新建ProjectXApp.GameplayRedDots.cs，仅游历业务已接权威链，其余8项当前仍取旧GameplayStore.HasHotPoint，不能声称已经实现。有效IDs={1,3,9,10,21,23,27,29,32}，root gameplay；服务端旧41/51/101/103不会直接写HUD，改由当前树聚合。GameplayStore旧映射101→6、51→8、103→9，未覆盖8项，需要逐项从正式业务修复。

旧Shared/HotPointController.refreshGameplay仍请求隐藏昆仑/213 op25；需要按实际有效玩法替换共享后台刷新，避免excluded来源。Bootstrap.OnHeroRedDotRefresh已预加载Hero/Equipment/Draw/World/YouLi；后续只扩当前已完成链的背景刷新，数据回包不可抢页面。玩法卡片GameplayPresenter在store.Changed重绘；不要每秒无条件重建列表。

摇钱树线索：Data/MoneyTreeStore.cs已具HasAuthoritativeResponse、PendingShakeType、Records，RemainingFreeCount=min约束需同时RemainingCount>0；当前UI只CoinType1、Gold页隐藏。Core/ProjectXApp.MoneyTree.cs后台Commit不导航，LuaGameplay/MoneyTreeController.lua.txt /222 op17 query1/shake2，暂无preload。UI/MoneyTreePresenter.cs待接正式Prompt；server/src/pack_deal.cpp15569附近正式Vip免费次数与实际成本，不凭空为付费机会点亮。页上允许收费继续操作不等于免费红点。

其他状态：Data/FengShenStoryStore.cs(HasAuthoritativeResponse/RemainingChallenges/ChallengePending)；Data/XunBaoStore.cs；Data/TaskStore.cs(HasClaimable含daily及activity boxes)；Data/FishStore.cs(basket/HasAuthoritativeState/IsFishing)；Data/HappyWheelStore.cs(CostItemId/key costs/活动秒数/PendingDrawType)；Answer/Monopoly没有独立Data Store文件，先rg --files定位Core状态，不猜文件路径。正式来源沿Lua controller→协议C++→当前配置/SQLite，静态测试不能代替真实入口。

## 本轮新增文件与运行注意

- Core/ProjectXApp.GameplayRedDots.cs、游历Store/Presenter/Core及Bootstrap/YouLiController改动；server/src/xun_bao_manage.cpp两处最小修复（文件已有其他改动，不能全文件视作本轮独占）。
- .local/youli_fixture.py等脚本不正式生产工具；夹具列实际xunbao。首次列名误写xun_bao在只读backup后、角色/metadata写入前失败；修后续同backup完成AssertSetup一次。没有重新初始化已消耗档。
- 游历现有“一键领取”按钮仍逐项ClaimFirstReady，本轮按真实逻辑逐项验证，没有未经授权扩大改成批量。仅到期领取点，不给空地点派遣机会造点。
- 每秒使用ServerTimeService，不用本地Utc作为业务权威。YouLiPresenter的Tick为时间文字/红点刷新，不每秒重建卡片；等级变化重绘。源文件/服务二进制需核对当前指纹。
- 全终端用pwsh UTF8，git完整路径C:/Program Files/Git/cmd/git.exe；Python bundled C:/Users/Admin/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe。
- rg使用实际目录+ -g，不将通配符当路径；未知文件先rg --files。输出<200行、错误附近/日志tail100，大明细写.local。
- 截图工具图片返回会显著增加聊天文件，只查看必要图，监测会话文件15MB预警、20MB停止；下一聊天不要继续加载本聊天大日志。
