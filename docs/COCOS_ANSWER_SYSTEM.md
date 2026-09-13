# Cocos 每日答题系统源码整理

> 整理日期：2026-09-13
> 范围：Cocos2d-x 2.17 + Lua 客户端、C++/Lua 服务端、配置与界面资源。
> 性质：当前源码静态审计结果，不代表运行验收结论。
> 平台边界：Cocos版本只作为源功能参考，保持现状、不增加本需求修改；本文确认的新入口、新次数规则和奖励缺失降级仅限Unity版本。

## 1. 结论摘要

- 每日答题主协议为 `198`：客户端名 `MSG_EVERY_QUETION`，服务端名 `MSG_ANSWER_QUESION`。
- 玩法入口活动 ID 为 `7`，功能路由 ID 为 `27`。
- **Unity后续目标流程不使用场景NPC**：功能开放后，玩家直接从玩法大厅的答题卡片点击“参加”进入；Cocos入口保持现状。
- 正式题目不是客户端 DAT 配置，而是服务端 `question` 表；用户已确认复用旧博物馆工程的38道中文文物题，当前项目以 `server/config/source/question.csv` 为运行源，并生成SQLite/MySQL种子。
- Cocos 运行界面仅使用 `client/ProjectX/res/csd/dati/AnswerLayer.csb`。
- 当前 C++ 实际限制为每轮 `10` 题、每日 `1` 轮；活动脚本、NPC判断和帮助文本仍保留旧的 `20` 题/`2` 轮口径。
- C++ 按奖励类型 `41` 结算，但当前运行配置 `server/config/json/reward_rank.json` 没有 `type=41`，最终奖励可能为空。
- 用户已确认：Unity答题UI、答题过程和最终奖励流程不改；Unity奖励配置缺失时临时改发金币，后续再调整。
- 当前NPC入口、答题UI创建和结算界面之间存在未闭合调用链，详见“已知问题”；该链路只作为历史现状记录，不作为目标方案。

### 1.0 平台修改边界

| 平台/层 | 本需求处理 |
| --- | --- |
| Cocos Lua客户端 | 不修改 |
| Cocos CSB资源 | 不修改 |
| Cocos现有玩法大厅/NPC入口 | 不修改 |
| C++/Lua共享旧服务端逻辑 | 不为本需求改变Cocos行为 |
| Cocos客户端题库逻辑、次数、奖励配置 | 不修改；workspace-local MySQL共享题库数据同步为本次确认的38道中文题 |
| Unity客户端 | 实现本节确认的新流程 |
| Unity本地服务/SQLite/适配层 | 仅按Unity需求实现次数校验和奖励缺失降级 |

本文第2～15节中的Cocos代码、协议和问题均为迁移参照及现状记录，不构成本需求对Cocos版本的修改要求。

### 1.1 用户确认的目标口径

本节是Unity版本后续实现和验收的优先口径；与Unity中的旧NPC映射、旧帮助文本或硬编码冲突时，以本节为准。不得据此修改Cocos版本。

| 项目 | 目标规则 |
| --- | --- |
| 开放条件 | Unity只认 `function` 表中 `function_id=27` 的开放条件 |
| 入口位置 | Unity玩法大厅内增加/启用“答题”卡片，布局沿用现有玩法卡片 |
| 进入方式 | Unity点击答题卡片的“参加”按钮后直接进入答题UI，不寻路、不进入场景、不交互NPC |
| 每日次数 | Unity由正式数据表控制，代码不得写死每日上限 |
| 次数耗尽 | 保留入口；点击后提示“今日答题次数已用完”，不进入UI、不请求新题 |
| 答题UI | 保持现有 `AnswerLayer.csb` 结构与表现 |
| 答题过程 | 保持现有出题、四选一、倒计时、正误反馈、下一题流程 |
| 最终奖励 | 保持现有最后一题统一结算流程 |
| 奖励缺失 | 仅Unity临时改发金币，金币奖励类型为 `60000`；具体数量后续由策划调整 |

入口参考图中的红框和“答题”文字仅表示玩法大厅右下区域的目标位置，不视为可直接使用的UI资源。正式卡片应复用玩法大厅现有的图标、标题和“参加”按钮结构。

### 1.2 Unity目标调用链

```text
登录/刷新玩法大厅
  -> 读取 function_id=27
  -> 未满足开放条件：按玩法大厅既有未开放规则展示或隐藏
  -> 已满足开放条件：显示可点击的“答题”卡片
  -> 玩家点击“参加”
  -> 读取答题每日次数配置
  -> 今日次数已达上限：提示“今日答题次数已用完”，流程结束
  -> 今日仍有次数：直接创建 AnswerUI
  -> AnswerUI 发起唯一一次 /198 op=1
  -> 后续答题UI、答题过程和最终奖励保持现状
  -> 奖励配置缺失：最终奖励临时降级为金币
```

## 2. 当前旧源码调用链

> 本节记录仓库现状，用于定位需要替换的旧逻辑；不代表目标流程仍需NPC。

```text
玩法大厅 /209，活动ID=7
  -> ActivityFunction.lua 自动寻路
  -> 场景11，NPC实例/模板198“问题大师”
  -> server/script/198.lua
  -> 服务端下发 /191，op=1002
  -> 客户端 LuaNetRecvdMsg.DealMsgGuideIndo
  -> 客户端请求 /198，op=1
  -> CPackageDeal::AnswerQuestionOption
  -> server/script/200.lua:GetQuestionAnswer
  -> script_call.cpp:GetQuestion
  -> MySQL question表
  -> 服务端返回题目与乱序选项
  -> 客户端 DealQueryQuestion / UpdateQuestion
  -> AnswerUI.lua 刷新 AnswerLayer.csb
  -> 玩家选择1~4；20秒超时提交5
  -> 客户端请求 /198，op=2
  -> 服务端校验正确槽位并累计答对数
  -> 第10题按 reward_rank type=41 结算
```

## 3. 标识与入口

| 标识 | 值 | 位置 | 用途 |
| --- | ---: | --- | --- |
| 活动 ID | `7` | `client/ProjectX/src/core/AppDef.lua` | `EAID_QUESTION`，玩法大厅活动 |
| 功能 ID | `27` | `client/ProjectX/src/core/AppDef.lua` | `EMID_QUESTION`，映射 `Activity.AnswerUI` |
| NPC ID | `198` | `server/config/json/npc_template.json` | Cocos旧流程“问题大师”；Unity目标流程不使用 |
| NPC场景 | `11` | `server/sql/_all_sql.sql` | Cocos旧流程坐标；Unity目标流程不使用 |
| 引导协议 | `/191` | 客户端 `MSG_DEAL_GUIDE_INDO` / 服务端 `MSG_XINSHOUYINDAO` | Cocos旧流程 `op=1002`；Unity目标流程不依赖 |
| 答题协议 | `/198` | 客户端 `MSG_EVERY_QUETION` / 服务端 `MSG_ANSWER_QUESION` | 获取题目、提交答案 |
| 玩法协议 | `/209` | `MSG_DAILY_ACTIVITY` | 返回包含活动7的玩法/活跃度数据 |

当前旧源码在玩法大厅点击活动7后执行自动寻路：

```lua
LGameMsg.m_autoPathMsg:ChangeToStart(
    11, -1, -1, 0, bit.lshift(198, 16), true, true, nil
)
```

对应文件：`client/ProjectX/src/View/Activity/ActivityFunction.lua`。目标实现应将该分支替换为“次数预检后直接打开答题UI”。

旧NPC选择“答题”后，`server/script/198.lua` 调用：

```lua
j.SendYinDao2_Op(pUser, 1002)
```

客户端收到 `/191 op=1002` 后调用 `LuaNetSendMsg:QueryQuestion(1)`。Unity目标流程不再经过该协议桥接，Cocos保持现状。

## 4. `/198` 前后端协议

### 4.1 协议注册

客户端：

```lua
MSG_EVERY_QUETION = 198
this.m_pRegisterMsg:Changer(
    LuaNetCmd.MSG_EVERY_QUETION,
    this.DealAnswerQuestion
)
```

服务端：

```cpp
const int MSG_ANSWER_QUESION = 198;
cmdFun.push_back(SCommand{
    MSG_ANSWER_QUESION,
    boost::bind(&CPackageDeal::AnswerQuestionOption, this, _1, _2)
});
```

### 4.2 客户端请求题目

包体：

| 顺序 | 类型 | 值 | 说明 |
| ---: | --- | --- | --- |
| 1 | `UShort` | `198` | 协议号 |
| 2 | `Byte` | `1` | 获取问题 |

发送函数：`client/ProjectX/src/NetWork/LuaNetSendMsg.lua` 中的 `QueryQuestion(op)`。

### 4.3 服务端返回题目

公共头：

| 顺序 | 类型 | 字段 |
| ---: | --- | --- |
| 1 | `Byte` | `op=1` |
| 2 | `Byte` | `result`，`0=失败`、`1=成功` |

成功包体：

| 顺序 | 类型 | 字段 | 当前语义 |
| ---: | --- | --- | --- |
| 3 | `Byte` | `idx` | 当前题号，当前为 `1~10` |
| 4 | `Byte` | `quenum` | 剩余题数，当前为 `9~0` |
| 5 | `String` | `question` | 题目文本 |
| 6 | `String` | `answer` | 四个选项，以 `|` 分隔 |

失败包体：

| 顺序 | 类型 | 字段 |
| ---: | --- | --- |
| 3 | `String` | 错误提示 |

客户端把数据写入 `LRoleDataMgr.MyHeroInfo.m_pQuestion`：

```text
idx
quenum
question
anwser       # 源码拼写如此
curReward
rightNum
reward
```

### 4.4 客户端提交答案

包体：

| 顺序 | 类型 | 值 | 说明 |
| ---: | --- | --- | --- |
| 1 | `UShort` | `198` | 协议号 |
| 2 | `Byte` | `2` | 提交答案 |
| 3 | `Byte` | `1~4` | 玩家选择的答案槽位 |
| 3 | `Byte` | `5` | 客户端20秒倒计时结束 |

发送函数：`LuaNetSendMsg:AnswerQuestion(op, idx)`。

### 4.5 服务端返回答案结果

答对：

| 顺序 | 类型 | 字段 | 当前值/说明 |
| ---: | --- | --- | --- |
| 1 | `Byte` | `op` | `2` |
| 2 | `Byte` | `result` | `PRO_SUCCESS=1` |
| 3 | `Int32` | 本题奖励 | 当前固定写入 `0` |
| 4 | 变长 | 最终奖励列表 | 仅最后一题追加 |

答错、超时或答题状态异常：

| 顺序 | 类型 | 字段 | 当前值/说明 |
| ---: | --- | --- | --- |
| 1 | `Byte` | `op` | `2` |
| 2 | `Byte` | `result` | `PRO_ERROR=0` |
| 3 | `Byte` | 正确答案槽位 | UI用来显示正确印章 |
| 4 | `UInt32` | 本题奖励 | 当前固定写入 `0` |
| 5 | `String` | 错误提示 | 当前客户端未读取 |

最终奖励列表由 `SendAndMakeAwardMsg` 追加：

```text
Byte awardCount
repeat awardCount times:
  UShort award.type
  Int32  award.typeId
  Int32  award.num
```

奖励在服务端通过 `AddMaterial` 直接发放。

### 4.6 预留但未实现的 op

服务端注释定义：

| op | 注释语义 | 当前状态 |
| ---: | --- | --- |
| `1` | 获取问题 | 已实现 |
| `2` | 提供答案 | 已实现 |
| `3` | 关闭界面、完成答题 | 空实现，客户端未发送 |
| `4` | 通知开始答题 | 未实现 |
| `5` | 通知结束答题 | 未实现 |

## 5. 客户端代码清单

| 文件 | 职责 |
| --- | --- |
| `client/ProjectX/src/View/Activity/AnswerUI.lua` | 主界面、四个答案按钮、20秒倒计时、正误反馈、下一题 |
| `client/ProjectX/src/View/Activity/AnswerMainUI.lua` | 旧页签容器；自身没有CSB，只延迟创建 `AnswerUI` |
| `client/ProjectX/src/View/Activity/ActivityFunction.lua` | 活动7参加按钮、战斗态阻断、自动寻路 |
| `client/ProjectX/src/NetWork/LuaNetSendMsg.lua` | `/198` 请求发送 |
| `client/ProjectX/src/NetWork/LuaNetRecvdMsg.lua` | `/191` 与 `/198` 收包处理 |
| `client/ProjectX/src/NetWork/LuaNetCmd.lua` | 客户端协议号 |
| `client/ProjectX/src/Data/Player/LRoleData.lua` | `m_pQuestion` 运行时数据 |
| `client/ProjectX/src/Event/LUIEvent.lua` | `UpdateQuestion`、`UpdateAnswerInfo` |
| `client/ProjectX/src/core/AppDef.lua` | 活动ID、功能ID、UI路由 |
| `client/ProjectX/src/Common/Tips.lua` | 答题标题、题号、倒计时、帮助规则 |

### 5.1 AnswerUI 生命周期

初始化：

1. 注册 `UpdateQuestion`、`UpdateAnswerInfo`。
2. 加载 `csd/dati/AnswerLayer.csb`。
3. 绑定关闭回调和帮助按钮。
4. 绑定四个答案按钮。
5. 先隐藏根节点。
6. 发送 `/198 op=1`。

显示题目：

1. 将 `answer` 按 `|` 拆分。
2. 依次写入 `Button_1~4`，加上 `A/B/C/D` 前缀。
3. 显示题号、问题、正确数、剩余题数。
4. 重置为20秒并启动计时器。

提交答案：

1. 禁用四个按钮。
2. 停止倒计时。
3. 发送 `/198 op=2 + selectedIndex`。
4. 显示正误提示和正确答案印章。
5. 一秒后请求下一题，或在 `quenum=0` 时关闭界面。

## 6. 服务端代码清单

| 文件 | 职责 |
| --- | --- |
| `server/src/protocol.h` | `MSG_ANSWER_QUESION=198` |
| `server/src/pack_deal.cpp` | 协议注册与 `AnswerQuestionOption` |
| `server/script/198.lua` | “问题大师”NPC交互与入口检查 |
| `server/script/200.lua` | 活动列表数据、题目拆分、答案乱序、一键完成 |
| `server/src/script_call.cpp` | 从数据库读取并缓存题库 |
| `server/src/lua_j_stub.cpp` | 将 `GetQuestion` 暴露为 `j.GetQuestion` |
| `server/src/user.cpp` | 题目索引抽取、保存、恢复和每日重置 |
| `server/src/user.h` | `m_isInDaTi`、`m_questionIds` |
| `server/src/init.h` | 答题扩展数据字段枚举 |
| `server/src/rank.h` | 答题奖励类型41 |
| `server/src/award_manager.cpp` | 加载 `reward_rank.json`、按类型和正确数查奖励 |
| `server/src/init.cpp` | 最终奖励编码与实际发放 |

## 7. 服务端状态与规则

| 状态 | 含义 | 变化时机 |
| --- | --- | --- |
| `ED8_6` | 今日完成答题轮数 | 获取到本轮最后一题时增加，不是提交最后答案时 |
| `ED8_35` | 本轮已获取题数 | 每次成功获取题目时增加 |
| `ED8_683` | 今日答对数 | 每次答对时增加 |
| `ED32_6` | 当前题开始时间 | 服务端发题后记录 |
| `m_isInDaTi` | 当前题可提交状态 | 发题后 `true`，提交后 `false` |
| `m_questionIds` | 本轮候选题目索引 | 保存进角色 `questIds` 字段，支持重登恢复 |
| `Val(1)` | 当前正确答案槽位 | `GetQuestionAnswer` 乱序后写入 |

当前 C++ 常量：

```cpp
static uint8 MaxTiMuCnt = 10;
static uint8 MaxDaTiTimes = 1;
```

每日重置会清空：

```text
ED8_6
ED8_35
ED32_6
ED8_683
```

## 8. 题库配置

### 8.1 当前运行数据源

服务端首次调用 `GetQuestion()` 时执行：

```sql
select question,answer1,answer2,answer3,answer4 from question
```

表结构：

| 字段 | 类型 | 语义 |
| --- | --- | --- |
| `id` | `int` | 自增主键 |
| `question` | `varchar(255)` | 题目 |
| `answer1` | `varchar(255)` | 正确答案 |
| `answer2` | `varchar(255)` | 错误答案 |
| `answer3` | `varchar(255)` | 错误答案 |
| `answer4` | `varchar(255)` | 错误答案 |

结构文件：

- MySQL：`server/sql/local_min_schema.sql`
- SQLite兼容结构：`server/sql/sqlite/001_initial_schema.sql`
- 策划源：`outputs/answer-question-bank/question.xlsx`
- 运行源：`server/config/source/question.csv`
- 导表工具：`tools/local/Import-QuestionWorkbook.py` → `tools/local/Export-QuestionBank.ps1`
- 独立种子：`server/sql/mysql/seeds/question.sql`、`server/sql/sqlite/seeds/question.sql`

Unity用户测试使用的 SQLite 与 Cocos本地服务端题库不是同一数据后端；Cocos答题联调必须使用 workspace-local MySQL。

### 8.2 本地测试题

当 `local_test=1` 且没有执行正式题库种子时，`server/src/main.cpp` 会：

1. 创建或补齐 `question` 表字段。
2. 将题库补足到21条。
3. 缺失内容填成：

```text
Local test question N?
A
B
C
D
```

这些数据只是缺表时的本地协议兼容夹具，不能作为正式题库或正式答案配置。当前生成种子会先清空该占位数据，再写入38道中文题。

### 8.3 选题规则

- `answer1` 固定视为正确答案。
- Lua将四个答案槽位随机洗牌，然后把正确槽位写到 `pUser:SetVal(1, right)`。
- C++从题库中抽取20个不重复索引保存到 `m_questionIds`。
- 当前每轮只使用前10个索引。
- 题库少于21条时，`GetQuestionId()` 返回失败。
- 随机索引先进入 `std::set` 再写入数组，因此是“随机选择集合、按索引升序出题”，不是完全随机题序。

### 8.4 已导入的中文策划表

- 原始表位置：`D:\xuancai\museum\策划\excel\question.xlsx`。
- 项目交付表：`outputs/answer-question-bank/question.xlsx`。
- 工作表：`Sheet1!A1:H42`；前4行为字段/类型说明，数据区共38道完整中文题。
- 字段为 `ID / antiqueID / describe / question / answer1 / answer2 / answer3 / answer4`，其中 `answer1` 为正确答案，与当前服务端读取约定一致。
- 用户于2026-09-13确认将这38道题用于当前测试；已转换为UTF-8运行源并写入Unity当前SQLite与workspace-local MySQL。
- 题目全部是博物馆文物主题，保留原表1组重复题干（ID 25、26，答案组选项不同），未擅自修改策划内容。

`Import-QuestionWorkbook.py`从策划表第5行开始生成UTF-8 CSV；`Export-QuestionBank.ps1`校验连续ID、必填字段、中文题干和最少21题，并同步生成SQLite/MySQL `INSERT` 数据。`answer1`继续作为正确答案，服务端发题时再随机打乱四个选项。

## 9. 活动、功能和NPC配置

| 配置 | 答题相关内容 | 当前权威性 |
| --- | --- | --- |
| `server/config/json/function.json` | 功能27“答题”，开放条件 `1-10` | 当前 `CSystemOpenCfgMananger` 实际加载 |
| `client/ProjectX/src/ConfigData/function_dat.lua` | 功能27“答题”，开放条件 `1-10` | 客户端可读生成物 |
| `client/ProjectX/res/ConfigData/function.dat` | 功能配置二进制产物 | Cocos资源 |
| `server/config/xml/Function_Level.xml` | 旧活动7，开放条件 `1-39` | 当前服务端不直接加载 |
| `server/script/200.lua` | 活动7：39级、全天、2次、10活跃度 | 当前玩法列表业务逻辑 |
| `server/config/json/npc_template.json` | NPC 198“问题大师”，脚本198 | 当前服务端配置 |
| `server/sql/_all_sql.sql` | NPC 198场景和坐标 | 本地数据库种子 |
| `server/script/198.lua` | NPC对话、等级/次数判断、发送1002 | 当前入口逻辑 |

### 9.1 Unity目标配置职责

| 配置职责 | 唯一目标来源 | 要求 |
| --- | --- | --- |
| 答题功能开放条件 | Unity `function_id=27` | Unity玩法大厅与Unity业务校验必须读取同一条配置 |
| 每日可体验次数 | Unity正式答题/玩法数据表 | 必须有明确字段；Unity入口和业务层共同使用 |
| 今日已使用次数 | Unity角色每日数据 | 每日重置，Unity本地服务/适配层权威 |
| 题目数量和单题时间 | 保持当前答题过程配置/逻辑 | 本次需求不调整 |
| 最终奖励 | Unity正式奖励配置 | 正常配置存在时保持现有结算 |
| 缺失奖励降级 | 金币 `60000` | 仅在应结算但奖励配置缺失时启用 |

Unity每日次数字段的具体表名和字段名需在实现时沿正式导表链确定。当前 Cocos `pack_deal.cpp` 的 `MaxDaTiTimes`、`server/script/200.lua` 的 `activityNum`、NPC脚本中的数字只作为源逻辑参考，不修改，也不能作为Unity的多个独立权威源。

目标判定顺序：

```text
function_id=27 是否开放
  -> 否：执行玩法大厅既有未开放表现
  -> 是：允许点击答题入口
      -> todayUsed >= configuredDailyLimit
          -> 是：提示“今日答题次数已用完”
          -> 否：直接打开 AnswerUI
```

次数预检应由Unity界面改善体验，Unity本地服务/业务适配层必须再次按同一配置校验，不能只依赖按钮状态。不得为此改变Cocos `/198 op=1` 的现有行为。

## 10. 奖励配置

### 10.1 当前结算逻辑

本轮最后一题提交后：

```cpp
sAwardManager.GetRankAward(
    CRankMgr::ERT_DaTiZhengQueShu,
    pUser->GetExtData8(ED8_683),
    rad
);
SendAndMakeAwardMsg(pUser, rad, msg, false, MUT_DaTi);
```

其中：

```cpp
ERT_DaTiZhengQueShu = 41;
MUT_DaTi = 114;
```

### 10.2 配置现状

当前服务端实际加载：

```text
server/config/json/reward_rank.json
```

该文件只有以下奖励类型：

```text
1, 2, 10, 11, 12, 13, 14
```

不存在 `type=41`。旧文件 `server/config/xml/rank_reward.xml` 也只有 `type=1~14`。

因此按当前配置执行：

```text
GetRankAward(41, correctCount, rad)
  -> 找不到type 41
  -> rad为空
  -> 最终没有配置奖励可发
```

`client/ProjectX/src/ConfigData/reward_rank_dat.lua` 同样没有答题代码直接读取关系。

### 10.3 Unity奖励缺失时的目标规则

正常奖励配置存在时，Unity答题最终奖励流程和内容保持不变。只有满足以下条件时才执行金币降级：

```text
已经完成本轮答题
AND 按正确题数应进入最终奖励结算
AND 奖励类型/档位不存在，或解析后奖励列表为空
```

降级奖励：

```text
award.type   = 60000    # 金币
award.typeId = 0
award.num    = 待策划调整的临时金币数量
```

约束：

- 不改变答题过程中间奖励、正误反馈和最后结算时机。
- 不因为配置读取异常而静默发空奖励。
- 金币数量应落在正式配置中；若实现阶段仍没有数值，必须明确标记为待配置，不能散落在客户端和服务端多个常量中。
- 降级发生时应记录服务端错误日志，包含角色、正确题数和缺失的奖励类型/档位，便于后续补表。
- 该降级规则不应用于Cocos客户端、Cocos服务端或Cocos奖励配置。

## 11. 关联任务与文案

### 11.1 支线任务

`server/config/xml/mission_config.xml`：

```text
任务ID：287
名称：[支]学富五车
目标：EMISS_DC_62，参加1次答题活动
最低等级：39
```

服务端成功发题时调用：

```cpp
SingletonCMissionManager::instance()
    .VerifyNewBranchMissionFinish(pUser, EMISS_DC_62);
```

注意：当前任务进度在“成功获取题目”时校验，不是在完成整轮答题时校验。

### 11.2 客户端帮助文本

`client/ProjectX/src/Common/Tips.lua` 当前描述：

```text
1. 每天可以参与1次。
2. 一轮共有20道题。
3. 答对有奖励，答错没有奖励。
4. 退出时正在作答的题目按失败处理。
```

该描述与当前服务端10题、空奖励类型、空 `op=3` 实现不完全一致。

## 12. Cocos界面资源

### 12.1 正式运行CSB

```text
client/ProjectX/res/csd/dati/AnswerLayer.csb
```

加载位置：`client/ProjectX/src/View/Activity/AnswerUI.lua`。

主要节点：

```text
Layer
└─ Panel
   └─ AnswerBg
      ├─ RewardBg
      │  ├─ RightBg/Text              正确数
      │  ├─ TimeBg/Text               倒计时
      │  ├─ Bg1/Value                 剩余题数
      │  ├─ Bg2/Value                 本题金币，默认隐藏
      │  ├─ Bg3/Value                 累计金币，默认隐藏
      │  ├─ Reward                    奖励展示，Lua未接入
      │  └─ Panel_1                   3/7/10题宝箱区，默认隐藏、Lua未接入
      ├─ SubjectBg
      │  ├─ TitleBg/Text              当前题号
      │  ├─ Bg/Text                   题目文本
      │  ├─ Button_1/RightImage       A答案/正确印章
      │  ├─ Button_2/RightImage       B答案/正确印章
      │  ├─ Button_3/RightImage       C答案/正确印章
      │  └─ Button_4/RightImage       D答案/正确印章
      ├─ RightText                    “答对了！”
      └─ WrongText                    “答错了！”
```

Lua实际使用的节点：

```text
RewardBg/RightBg/Text
RewardBg/TimeBg/Text
RewardBg/Bg1/Value
RewardBg/Bg1/Icon
RewardBg/Bg2/Value
RewardBg/Bg3/Value
SubjectBg/TitleBg/Text
SubjectBg/Bg/Text
SubjectBg/Button_1~4
SubjectBg/Button_1~4/RightImage
RightText
WrongText
```

### 12.2 Cocos资源缺口

- 仓库只有 `AnswerLayer.csb`，没有对应的可编辑 `AnswerLayer.csd`。
- `AnswerMainUI.lua` 只创建空 `cc.Node`，没有独立CSB。
- Cocos源码中没有 `datijiesuan.csb`，也没有任何Lua引用 `datijiesuan`。

## 13. Unity转换预制体

这些文件是Cocos资源转换产物，不属于当前Cocos运行路径：

| 文件 | 来源/状态 |
| --- | --- |
| `unityclient/Assets/ProjectX/res/csd/Prefabs/dati/AnswerLayer.prefab` | `AnswerLayer` Unity预制体 |
| `unityclient/Assets/ProjectX/res/csd/UnityMigration/documents/dati/AnswerLayer.json` | 转换节点与资源文档 |
| `unityclient/Assets/ProjectX/res/csd/Prefabs/dati/datijiesuan.prefab` | 答题结算预制体，当前Cocos逻辑未接入 |
| `unityclient/Assets/ProjectX/res/csd/UnityMigration/documents/dati/datijiesuan.json` | 结算面板转换文档 |

`datijiesuan` 主要节点：

```text
Layer
├─ Mask
└─ datijiesuan
   ├─ Bg
   ├─ Title_1                 答题结算
   ├─ Value_1                 本轮正确作答题数
   ├─ Title_2                 获得奖励
   ├─ Value_2                 无奖励提示
   ├─ TableView
   ├─ Btn_Close               点击屏幕继续
   └─ ItemList/itemlayer_1~7  奖励道具列表
```

## 14. 已知问题与不一致

### 14.1 旧NPC入口不符合目标流程，且没有创建答题UI

当前链路：

```text
NPC 198
  -> /191 op=1002
  -> 客户端 QueryQuestion(1)
  -> /198题目返回
  -> 只发送 UpdateQuestion 事件
```

`DealQueryQuestion` 中原有的 `InitUI("Activity.AnswerMainUI")` 已被注释。仓库内也未找到NPC路径主动调用 `OpenFunction(EMID_QUESTION)` 的代码。

因此，若 `AnswerUI` 尚未存在，`UpdateQuestion` 没有接收者，按当前可见源码无法显示界面。

Unity目标方案不照搬或修补NPC链，而是从玩法大厅直接创建Unity答题UI。Cocos中的NPC链与 `AnswerUI` 保持不动。Unity一次入口只能创建一次UI，并只发出一次取题请求。

### 14.2 题数和每日次数有四套口径

| 来源 | 每轮题数 | 每日轮数 |
| --- | ---: | ---: |
| `pack_deal.cpp` 当前实际执行 | 10 | 1 |
| `server/script/200.lua` 活动配置 | 未直接写题数 | 2 |
| `server/script/198.lua` NPC判断 | 累计20题 | 2 |
| `Tips.lua` 帮助文本 | 20 | 1 |

另外，玩法一键完成分支把活动次数硬编码为 `4`，与上述口径继续冲突。

本次确认只要求Unity“每日次数由数据表控制”，不调整现有答题UI和答题过程，也不修改Cocos的任何题数/次数逻辑。Unity落地时应将每日上限收敛到唯一正式配置；Cocos旧的10/20题口径继续作为现状记录。

### 14.3 开放等级有三套口径

| 来源 | ID | 等级 | 实际影响 |
| --- | ---: | ---: | --- |
| `server/script/200.lua` | 活动7 | 39 | 玩法大厅活动显示与可参加状态 |
| `function.json` | 功能27“答题” | 10 | 通用功能路由配置 |
| `server/script/198.lua` | 错用功能7 | 当前为34 | NPC直接交互检查；功能7在当前JSON中是“决战昆仑” |

旧 `Function_Level.xml` 的活动7为39级，但当前服务端 `CSystemOpenCfgMananger` 实际读取的是 `function.json`，不能再把旧XML当运行权威。

Unity目标口径已确认：只使用 `function_id=27`。Unity不得复制活动ID `7` 查询功能开放等级的旧逻辑；Cocos活动脚本和NPC脚本不在本次修改范围内。

### 14.4 答题奖励类型缺失

- C++请求 `type=41`。
- `reward_rank.json` 没有 `type=41`。
- 最后一次提交可能得到空奖励数组。
- 客户端也没有解析服务端追加的奖励列表或打开 `datijiesuan`。

Unity目标口径已确认：不重做最后奖励流程；Unity奖励配置缺失或查表结果为空时临时发金币 `60000`，具体金币数量后续调整。Cocos奖励逻辑保持现状。

### 14.5 退出规则没有实现

- 服务端 `op=3` 分支为空。
- 客户端关闭按钮不发送 `op=3`。
- 帮助文本声称退出会把当前题判错，但源码没有对应结算。
- 关闭UI后，服务端 `m_isInDaTi` 仍可能保持为 `true`，直到收到一次 `op=2`。

### 14.6 服务端没有真正校验20秒超时

- 客户端倒计时20秒，到时提交答案槽位5。
- 服务端计算 `useTime`，但只把异常值改为13，没有使用该值判断超时或奖励。
- 客户端时间可以约束正常操作，但不是服务端可信校验。

### 14.7 完成轮数的计数时机偏早

服务端在“成功发出本轮最后一题”时就增加 `ED8_6`，不是在玩家提交最后一题后增加。玩家收到最后一题后掉线或退出，也可能已经占用今日次数。

### 14.8 正确数按日累计，不按轮重置

`ED8_683` 只在每日重置时清零。若未来恢复每日多轮，第二轮奖励会使用当天累计正确数，而不是本轮正确数，需要先明确正式策划口径。

## 15. 当前验证覆盖

`PROTOCOL_COVERAGE.md` 和 `tools/local/Invoke-ProtocolSmoke.ps1` 仅覆盖：

```text
answer_question_get: /198 + op=1
```

当前没有自动覆盖：

- 正确答案提交。
- 错误答案提交。
- 20秒超时。
- 第10题结算。
- 奖励到账。
- 中途退出与重登恢复。
- NPC入口是否真正打开界面。

## 16. 后续使用建议

Unity版本已确认事项：

1. 不使用场景NPC。
2. `function_id=27` 控制开放条件。
3. 开启后从玩法大厅直接点击进入。
4. 每日体验次数由正式数据表控制。
5. 次数耗尽时点击入口只提示，不进入答题。
6. 答题UI、答题过程和最后奖励流程保持不变。
7. 奖励配置缺失时临时发金币，后续再调整数值。

Cocos版本边界：上述七项均不修改Cocos Lua、CSB、玩法大厅、NPC和MySQL行为。共享C++服务端只新增SQLite分支；Cocos/MySQL仍走原 `ExtData8` 次数与 `reward_rank` 奖励逻辑。

Unity当前实现口径：

1. 每日次数配置：`server/config/source/answer-settings.csv` 的 `daily_attempt_limit`，当前为1。
2. 缺失奖励金币：同表 `fallback_reward_type=60000`、`fallback_reward_amount=1000`，后续直接改表。
3. 保留当前10题流程与20秒单题倒计时，不在本次统一旧帮助文案中的20题描述。

建议按以下顺序完成Unity版本闭环：

```text
function_id=27开放条件
  -> 玩法大厅答题卡片
  -> 数据表每日次数与Unity业务层校验
  -> Unity入口不依赖NPC/自动寻路/191-1002
  -> 唯一UI打开链
  -> /198完整收发包
  -> AnswerLayer显示
  -> 保持现有答题过程和最终结算
  -> 奖励缺失时金币降级
  -> 正确/错误/超时/退出/重登/最终奖励自动回归
  -> Unity真人操作验收
```
