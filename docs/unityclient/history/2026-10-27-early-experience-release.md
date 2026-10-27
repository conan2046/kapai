# 2026-10-26～27 前期体验变更与 P0 续接

## 发布范围

本次整理承接本地 main 的 `e37ecb264886598636f9b6bd39241ad958bd85a6`（10月26日，59个明确路径）及本次Boss宝箱/结算模板提交，一并推送 origin/main。发布日期2026-10-27；实际提交号以Git日志和远端main为准，不将旧检查点中的“未推送”当作当前发布状态。

工作目录为 `E:\neiwang_kapai\Game`，正式Unity目录 `unityclient`。当前聊天不创建worktree，不跨checkout复制修改。用户授权本次提交、推送及创建新聊天续接P0。

## 两日最终结果

| 范围 | 最终行为与维护源 |
| --- | --- |
| P01功能入口 | function.xlsx为121条规则维护源，派生客户端解锁/玩法目录；修复覆盖优先级，保持既定洞府数据 |
| 道具配置 | item.xlsx优先，1884条正式记录加13条兼容ID，1897条最终输出；旧权威快照仅兜底 |
| 主线奖励 | reward.xlsx、maplist.xlsx、fight_config.xlsx、monster_boss_basic.xlsx统一导出；主线1266关、127章，奖励只走rewardID，首胜与重复使用同一规则 |
| 奖励结构 | 必掉与随机候选分组；随机数量支持四元组；神将经验替换原金币投放，不重复相加；主角经验不由副本发放 |
| 龙崖Boss包 | bigmap.xlsx/bigmap的H列由star_reward改为整数boss_reward，每章引用原最后一个奖励包；无星数门槛，每次Boss胜利均发，不受历史领取状态阻断 |
| 两端链路 | WorldRewards组统一维护bigmap/reward_fixed及服务端JSON、客户端DAT；严格校验最终Boss/包引用；/320 op2尾部增加Boss包ID，预览合并该包 |
| 最终结算UI | 使用正式World/zhandoujiesuanLayer.prefab现有itemlayer与shenjianglayer；等级、A/S/SS/SSS评分、星级、经验条绑定真实数据；货币和主角经验显示按用户最新要求隐藏，到账不变 |
| 用户布局 | 保留原节点的位置、字体、字号、尺寸；道具复用baseItem，品质评分Sprite通过WorldOutcomeBindings引用；不用另建RuntimeBattleReward显示区域 |
| 预览交互 | 每章只显示最后一个Boss包预览入口；移出底部奖励条遮挡区，实际Raycast点击可用；预览不发奖励 |

第一章1001的boss_reward为20013，当前包内容为1000元宝与2402接引道人神魂10。每次Boss胜利发一次；普通关、精英关、战败与非龙崖模式不发该Boss包。未合并前两档奖励，未改reward_fixed包内容。

## 验证及限制

- 10月26日完成正式导出与对应隔离回归、原生奖励规则/构建、主线实际配置解析、定向Play和12项奖励条拖动；保留其既有证据，不将旧星箱口径套用到新规则。
- 10月27日完成9项WorldRewards导出回归、真实正式导出/ValidateOnly、原生服务端构建与127章规则解析、Unity编译和Lua语法。当前运行输出11对一致。
- 新Boss规则有真实同章重复获胜与保存重登证据：四次连续Boss记录每次增加1000元宝、10碎片，累计+4000、+40；旧星箱已领取状态不影响新包。
- 原节点绑定另做真实Boss结算：五位神将等级/评分/星级/经验比例匹配HeroStore，道具一件及两件均显示实际名称、数量和图标，货币/主角经验区域隐藏。最终Console错误0。
- 隔离Slot09已归档，各批Setup只执行一次；最新批保护54份原存档/既有归档哈希不变。Play、测试服务端及8711监听退出，偏好恢复；Editor/MCP保留。
- 没有重新构建Steam发行包；本次是源代码和正式配置发布，不表示Windows发行包验收完成。
- **尚未完成的画面项**：独立开箱动画/表现；奖励预览的通用标题、空白底部按钮；原等级Text宽25、字号22导致99裁切。按用户不改布局的要求保留，最终画面待用户微调确认。

## 维护和发布边界

- 正式结算维护对象为 `Assets/Prefabs/World/zhandoujiesuanLayer.prefab`，不是 `Retained/common` 同名文件。Retained中用户修改保留。
- bigmap暂存仅包含H列Boss字段变化；A3/I3/J3三处既有表头措辞留在工作区。其余无关资源、其他Excel表头、Prefab、工程设置、AGENTS和迁移指南等改动不混入本次提交。
- 客户端、服务端及对应正式配置需要配套更新。SQLite schema不变，旧存档星箱状态保持兼容，不重发旧箱。
- `Outputs/EarlyExperience/20261026/前期体验与投放总表_V0.2.xlsx` 为本机既有策划工作簿，V0.1保留；Outputs与.local不强行纳入Git。V0.2中早期“待定向Play”的状态文字可能落后，本交接的实测结果为最新依据。
- unityMCP保持enabled=true；跨聊天重新核验PID、projectPath、实例及Application.dataPath，不能借用其他工程。

## 新聊天继续P0

1. **P04 初始资源与首战资格**：先只读核对正式新档入口、初始货币/道具/体力、出生神将57与首战条件、首笔收益。高等级隔离测试不等于新档胜率/到账/体验时长通过。
2. 重点核对首关当前1000金币、100神将经验、无元宝与旧351金币+1元宝教学支出的缺口；列出现配、冲突、建议和待定，不擅自补资源或改投放。
3. P04收口后再处理P05主线任务数据与持久化，当前任务/引导存档链未完成；P02首轮目标继续后置，未获新指令不重开。
4. 先读当前AGENTS、HANDOFF和V0.2待定事项；未确认新数值不改正式表，不自动启动新档Play、修改原存档或重开G0–G6。不提交/推送新聊天产生的改动，除非再次授权。

## 证据入口

- `.local/p01-unlocks-20261026/final-verification.json`
- `.local/p01-items-20261026/final-verification.json`
- `.local/main-dungeon-unify-20261026/verification.json`
- `.local/main-dungeon-acceptance-20261026/verification.json`
- `.local/world-reward-display-20261026/verification.json`
- `.local/boss-chest-20261027/verification.json`
- `.local/boss-chest-20261027/play/verification.json` 与 `relogin-final.json`
- `.local/boss-chest-20261027/native-templates/verification.json`、`result.png`、`cleanup.json`
- `.local/boss-chest-20261027/publish/` 保存范围、保护哈希与远端发布核验；失败及解决关联既有 `.local/unity-validation/world-operation-ledger.json`
