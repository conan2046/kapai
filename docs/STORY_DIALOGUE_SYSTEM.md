# 剧情对话系统梳理与配置指南

> 适用项目：`E:\neiwang_kapai\Game`
> 梳理日期：2026-09-13
> 当前用途：剧情设计、配置制作、程序接入和数据校验的统一参考。
> 本文基于当前源码与配置静态审计；未启动 Cocos、Unity、服务端或本地数据库。

## 1. 总结

项目内并非只有一套剧情对话系统，而是存在 5 套用途和数据源不同的对白机制。

| 系统 | 主要用途 | 权威数据源 | 当前状态 |
|---|---|---|---|
| 章节/关卡剧情对白 | 进入章节、挑战关卡前播放线性剧情 | Cocos Lua 配置 | **Cocos 当前生效** |
| 服务端任务剧情 | 任务接受、进行、完成过程中的对白 | `mission_config.xml`、`mission_dialog.xml` | **数据存在，加载入口关闭** |
| NPC 脚本对白 | NPC 交互、功能入口、简单选项 | `server/script/*.lua` | **当前生效** |
| 战斗对白 | 指定回合在战斗单位头顶显示气泡 | `fight_dialog.xml` | **当前生效** |
| 三界游历文本 | 游历随机事件和结果描述 | `sanjie_dialogue.json` | **当前生效** |

当前进行主线章节剧情设计时，应以“章节/关卡剧情对白”为准。不要将服务端任务剧情的 `1001～2216` ID 与客户端章节剧情的 `10001～10042` ID 混为同一套编号。

## 2. 章节/关卡剧情对白

### 2.1 数据链路

```text
章节配置 bigmap_dat.lua
        │ DialogueId
        ├──────────────┐
        │              ▼
关卡配置 maplist_dat.lua ──> mission_dialog_dat.lua
                               │ dialogid 分组
                               ▼
                         NPCChatDialogUI.lua
                               │
                               ├─ NPC 名称、立绘：npc_template_dat.lua
                               ├─ 点击或定时切换下一句
                               └─ 结束后进入章节地图或关卡挑战界面
```

### 2.2 相关文件

| 用途 | 文件 |
|---|---|
| 剧情对白内容 | `client/ProjectX/src/ConfigData/mission_dialog_dat.lua` |
| 章节剧情触发 | `client/ProjectX/src/ConfigData/bigmap_dat.lua` |
| 关卡剧情触发 | `client/ProjectX/src/ConfigData/maplist_dat.lua` |
| NPC 名称和立绘映射 | `client/ProjectX/src/ConfigData/npc_template_dat.lua` |
| 对白界面和播放逻辑 | `client/ProjectX/src/View/Common/NPCChatDialogUI.lua` |
| 章节入口逻辑 | `client/ProjectX/src/View/FuBenMap/NormalFuBenUI.lua` |
| 关卡入口逻辑 | `client/ProjectX/src/View/FuBenMap/FuBenDetailUI.lua` |
| 已播放标记 | `client/ProjectX/src/Data/LUserConfigMgr.lua` |
| NPC 半身像 | `client/ProjectX/res/res2/Monster_Bust/` |

> **权威源表（2026-09-13 补）**：章节/关卡对白与三界游历存在 Excel 策划源表，位于 `E:\neiwang_kapai\concept\data\excel\xml配置表\新表\`（`mission_dialog.xlsx`、`sanjie_dialogue.xlsx` 等），由 `E:\neiwang_kapai\concept\data\excel\转表工具\xl转表.exe` 导出为客户端 `mission_dialog_dat.lua` 与服务端 JSON。修改剧情文案应优先改源表后重跑转表工具，避免直接手改 lua/json 导致漂移。战斗对白 `fight_dialog.xml` 暂无对应的 Excel 源表。

### 2.3 当前剧情清单

现有客户端主线剧情共 10 段、35 句。

| 剧情ID | 触发位置 | 触发类型 | 句数 |
|---:|---|---|---:|
| 10001 | 第一章“苏护反商” | 进入章节 | 6 |
| 10002 | 关卡“崇黑虎” | 战前 | 4 |
| 10011 | 第二章“潜入朝歌” | 进入章节 | 4 |
| 10012 | 关卡“殷郊” | 战前 | 3 |
| 10021 | 第三章“解救妲己” | 进入章节 | 3 |
| 10022 | 关卡“妲己” | 战前 | 4 |
| 10031 | 第四章“查明真相” | 进入章节 | 3 |
| 10032 | 关卡“魔化锤兵” | 战前 | 3 |
| 10041 | 第五章“朝歌议事” | 进入章节 | 2 |
| 10042 | 关卡“帝辛” | 战前 | 3 |

### 2.4 播放规则

#### 章节剧情

1. 玩家进入当前已解锁章节。
2. 读取 `bigmap_dat.lua` 的 `DialogueId`。
3. `DialogueId > 0` 且章节剧情未播放时，打开 `NPCChatDialogUI`。
4. 剧情结束后进入章节地图。

#### 关卡剧情

1. 玩家点击当前可挑战关卡。
2. 读取 `maplist_dat.lua` 的 `DialogueId`。
3. `DialogueId > 0` 且关卡剧情未播放时，打开 `NPCChatDialogUI`。
4. 剧情结束后打开关卡挑战界面。

#### 播放操作

- 点击屏幕：立即显示下一句。
- 无点击：按正文长度计算等待时间后自动播放下一句。
- 点击跳过：直接关闭整段剧情。
- 播放完最后一句：结束剧情并继续原来的章节或关卡流程。

自动播放时间并不读取配置中的 `speed` 和 `delay`，当前代码约按每秒 6 个中文字符计算，且最少等待 1 秒。UTF-8 字节长度和文本颜色标签会造成计时偏差。

### 2.5 对白字段定义

| 字段 | 设计含义 | 当前运行表现 | 配置要求 |
|---|---|---|---|
| `dialogid` | 一段剧情的唯一ID | 生效，用于筛选同组对白 | 必填；正整数 |
| `order` | 组内播放顺序 | **未用于排序** | 仍应从 1 连续递增，便于校验和未来修复 |
| `npcid` | 当前说话人 | 生效 | `10000` 表示玩家；其他值必须存在于客户端 NPC 表 |
| `position` | 立绘站位 | 生效 | `0` 左侧，`2` 右侧 |
| `dialog` | 对白正文 | 生效 | 必填；避免把流程指令写入正文 |
| `scale` | 立绘缩放 | 未生效 | 当前统一填 `1` |
| `speed` | 文字或播放速度 | 未生效 | 当前值不控制实际速度 |
| `delay` | 自动播放等待时间 | 未生效 | 当前值不控制实际等待时间 |
| `showskip` | 是否允许显示跳过 | 未生效 | 跳过按钮当前始终显示 |

注意：播放器按 `mission_dialog_dat.lua` 中的物理排列顺序播放，而不是按 `order` 排序。因此调整剧情顺序时，必须同时调整文件中的实际行顺序。

### 2.6 说话人与立绘

- `npcid = 10000`：使用当前玩家名称及玩家形象逻辑。
- 其他 `npcid`：从客户端 `npc_template_dat.lua` 读取名称和 `picture`。
- 立绘路径：`client/ProjectX/res/res2/Monster_Bust/<picture>.png`。
- `position = 0` 显示在左侧，`position = 2` 显示在右侧。
- 站位只表示画面位置，不代表玩家或 NPC 身份；身份始终由 `npcid` 决定。

新增剧情角色前，必须同时确认：

1. 客户端 NPC 配置中存在该 `npcid`。
2. NPC 的 `picture` 字段正确。
3. 对应半身像 PNG 已存在。
4. 名称、立绘方向和对白站位符合剧情设计。

### 2.7 当前缺陷

| 优先级 | 问题 | 影响 |
|---|---|---|
| P0 | 已播放状态仅有“章节”和“关卡”两个设备级布尔值 | 不按账号、章节或剧情ID区分；多账号可能互相影响 |
| P0 | `order` 字段不参与排序 | 配置行位置错误会直接导致播放顺序错误 |
| P1 | 剧情 `10042` 的物理顺序为 `1、2、1`，末句重复 | 该重复**已存在于源表 `mission_dialog.xlsx`**（第三行复刻第一行），当前版本会实际播放重复台词；须改源表后重跑 `xl转表.exe` 重新导出 |
| P1 | `speed`、`delay`、`showskip`、`scale` 均未接入 | 策划配置这些字段不会产生效果 |
| P1 | 没有剧情回看入口 | 玩家跳过或漏看后无法重新观看 |
| P2 | 没有表情、语音、背景、镜头和动作指令 | 仅能完成基础双人立绘对白 |
| P2 | 导出链覆盖不全、易漂移 | 章节/关卡对白、三界游历有 `concept` 下 Excel 源表 + `xl转表.exe` 导出（见 §2.2）；但战斗对白 `fight_dialog.xml`、休眠的服务端任务剧情 `mission_dialog.xml` 无 Excel 源、仍手写 XML；且直接手改 `lua`/`json` 会与源表漂移 |

## 3. 服务端任务剧情

### 3.1 数据与规模

| 文件 | 内容 |
|---|---|
| `server/config/xml/mission_config.xml` | 任务定义，共 340 个任务 |
| `server/config/xml/mission_dialog.xml` | 任务剧情，共 662 句、227 组 |
| `server/config/json/mission_dialog.json` | 同类 JSON 数据，但不是当前服务端任务运行权威源 |
| `server/src/mission_manager.cpp` | 任务和剧情加载、状态机逻辑 |
| `server/src/script_call.cpp` | 剧情协议下发 |
| `client/ProjectX/src/View/Common/PlotChatUI.lua` | 客户端任务剧情播放器 |

现有 XML、JSON 均可正常解析，但服务端 `CMissionManager::Init` 中以下加载调用已被注释：

```cpp
// ReadMissionConfig();
// ReadMissionDialogConfig();
// ReadMubiaoConfig();
```

因此，这套任务剧情当前属于“代码和数据保留，但运行入口关闭”的休眠系统。未经程序恢复和完整联调，不能直接作为新增剧情的交付路径。

### 3.2 原设计能力

若重新启用，原状态机可串联以下任务动作：

- 剧情对白；
- 战斗；
- 道具提交；
- 收集目标；
- 接取和完成任务；
- `<name>` 玩家名称替换；
- `<sex>` 玩家性别文本替换。

其中真正参与运行的对白字段主要是 `order`、`npcid`、`dialog`。`position`、`scale`、`speed`、`delay`、`showskip` 虽然被解析，但没有完整下发和消费。

### 3.3 数据风险

- 3 处重复的 `(dialogid, order)`：`1007/2`、`1007/3`、`1312/2`。
- 9 个顺序不连续的剧情组：`1007`、`1014`、`1312`、`1617`、`2108`、`2110`、`2112`、`2114`、`2204`。
- `mission_config.xml` 中 155 个数字型剧情引用均能找到对应剧情组。
- 5 个 `accept_dialog` 填写的是正文，但旧代码按数字 ID 解析，实际会转为 `0`。
- XML 与 JSON 有字段差异，不能假定二者完全等价。

## 4. NPC 脚本对白与选项

### 4.1 数据链路

```text
玩家点击 NPC
  -> 服务端校验距离、队伍和 NPC 状态
  -> 根据 NPC 配置调用 server/script/<scriptId>.lua
  -> Dialog 或 Option 下发文本
  -> 客户端 NPCChatUI.lua 显示
  -> 玩家选择选项
  -> /13 MSG_NPC_CHAT 返回服务端
  -> 服务端校验允许的选项并执行回调
```

相关文件：

- `server/src/pack_deal.cpp`
- `server/src/script_call.cpp`
- `server/script/*.lua`
- `client/ProjectX/src/View/Common/NPCChatUI.lua`
- `client/ProjectX/src/Data/LuaNetRecvdMsg.lua`

脚本示意：

```lua
function NpcMain(pUser)
    Option(pUser, "NPC名称", "请选择：", "1|选项一|2|选项二")
    pUser:SetCallFun("SelectOption")
end

function SelectOption(pUser, optionId)
    if optionId == 1 then
        Dialog(pUser, "NPC名称", "选项一的结果文本")
    elseif optionId == 2 then
        Dialog(pUser, "NPC名称", "选项二的结果文本")
    end
end
```

限制：

- 最多支持 20 个选项对，但实际剧情设计不应超过 3～4 个。
- 大多数 NPC 选项界面约 5 秒后会自动选择第一项。
- 当前不适合用于不可逆奖励、阵营选择、角色生死等重要剧情分支。
- 分支全部写在 Lua 脚本中，缺少统一的可视化配置和静态校验。

## 5. 战斗对白

### 5.1 配置入口

| 用途 | 文件 |
|---|---|
| 战斗对白 | `server/config/xml/fight_dialog.xml` |
| 普通战斗关联 | `server/config/xml/fight_config.xml`、对应 JSON |
| 特殊战斗关联 | `server/config/xml/fight_special_config.xml` |
| 服务端触发 | `server/src/fight.cpp` |
| 客户端显示 | `client/ProjectX/src/View/Battle/BattleUnitNode.lua` |

### 5.2 字段与规则

| 字段 | 含义 |
|---|---|
| `dialogid` | 战斗对白组ID |
| `show_turn` | 触发回合 |
| `order` | 同回合播放顺序 |
| `group` | 阵营：`1` 我方，`2` 敌方 |
| `zhenfa_idx` | 阵型位置 |
| `time` | 气泡持续时间 |
| `dialog` | 显示文本 |

当前共有 46 行、17 组，其中 43 行具备运行所需字段。`dialogid = 1001` 的 3 行缺少 `show_turn` 和 `group`，不会触发。未被战斗配置引用的组为 `1001`、`1006`、`1009`、`1010`。

该系统只支持按回合显示头顶文字气泡，不支持选项、镜头、立绘和剧情状态分支。

## 6. 三界游历文本

| 用途 | 文件 |
|---|---|
| 服务端数据 | `server/config/json/sanjie_dialogue.json` |
| 客户端数据 | `client/ProjectX/src/ConfigData/sanjie_dialogue_dat.lua` |
| 服务端逻辑 | `server/src/xun_bao_manage.cpp` |
| 客户端显示 | `client/ProjectX/src/View/YouLi/YouLiUI.lua` |

当前共 8 条，按事件类型 `101/102` 选择，用于游历事件氛围描述，不属于主线全屏剧情系统。

## 7. Unity 迁移状态

Unity 资源配置中保留了 `maplist` 的 `DialogueId`，但当前未发现 Unity C# 代码读取这些字段，也未发现以下能力：

- 章节剧情触发；
- 关卡战前剧情触发；
- 对白队列播放器；
- NPC 名称和立绘解析；
- 跳过、自动播放、已播放状态；
- 剧情回看；
- 剧情选项和条件分支。

因此不能将“配置已进入 Unity Resources”视为剧情功能已经迁移。后续 Unity 接入时，应先确定是否复刻 Cocos 线性系统，还是直接实现新的统一剧情模型。

## 8. 当前版本的配置流程

适用于不改程序、继续沿用 Cocos 线性剧情的短期需求。

> **权威源表与导出（2026-09-13 修订）**：章节/关卡对白、三界游历的文案**应优先在 `E:\neiwang_kapai\concept\data\excel\xml配置表\新表\` 下的 Excel 源表维护**（`mission_dialog.xlsx`、`sanjie_dialogue.xlsx`），再运行 `E:\neiwang_kapai\concept\data\excel\转表工具\xl转表.exe` 重新导出客户端 `mission_dialog_dat.lua` 与服务端 JSON。战斗对白 `fight_dialog.xml` 暂无 Excel 源表，仍按下方直接维护 XML。**不要在未重跑转表工具的情况下直接手改 `lua`/`json`，否则会与源表漂移。**

### 8.1 新增章节剧情

1. 分配新的 `dialogid`，不得与已有ID重复。
2. 在 `concept` 仓库的 `mission_dialog.xlsx` 中追加该剧情的所有对白（保持四行表头与字段定义），然后运行 `xl转表.exe` 重新导出 `mission_dialog_dat.lua`。
3. 保证 `xlsx` 内物理排列顺序与设计播放顺序一致（播放器按物理行序播放，不按 `order` 排序）。
4. 在 `bigmap_dat.lua` 的目标章节填写 `DialogueId`。
5. 校验所有 `npcid`、NPC 名称和半身像资源。
6. 使用未播放过该章节剧情的本地状态，从章节入口进行真实点击验证。

### 8.2 新增关卡战前剧情

1. 分配新的 `dialogid`。
2. 在 `concept` 仓库的 `mission_dialog.xlsx` 中写入对白，然后运行 `xl转表.exe` 重新导出 `mission_dialog_dat.lua`。
3. 在 `maplist_dat.lua` 的目标关卡填写 `DialogueId`。
4. 校验关卡解锁条件和挑战状态。
5. 从真实关卡点击路径验证：打开剧情、逐句播放、跳过、结束后进入挑战界面。

### 8.3 单句配置模板

```lua
{
    dialogid = 10051,
    order = 1,
    npcid = 501,
    position = 0,
    dialog = "这里填写对白正文。",
    scale = 1,
    speed = 100,
    delay = 30000,
    showskip = 0
}
```

当前模板中的 `scale`、`speed`、`delay`、`showskip` 只用于保持数据结构一致，不代表对应表现已经实现。

## 9. 后续统一剧情表建议

正式批量生产剧情前，建议建立单一权威策划表，通过导出工具生成客户端或服务端配置，禁止继续同时手工维护 Lua、XML、JSON。

### 9.1 建议字段

| 分类 | 字段 | 说明 |
|---|---|---|
| 剧情 | `story_id` | 一段剧情的唯一ID |
| 节点 | `node_id` | 节点唯一ID，不再只依赖物理行顺序 |
| 节点 | `next_node_id` | 默认下一节点 |
| 触发 | `trigger_type` | 章节进入、关卡战前、战后、NPC、任务、战斗回合等 |
| 触发 | `trigger_target` | 章节ID、关卡ID、NPC ID、任务ID或战斗ID |
| 条件 | `condition` | 等级、任务、道具、角色、历史选择等 |
| 角色 | `speaker_id` | 说话人ID |
| 角色 | `speaker_name_override` | 特殊场景临时名称，可为空 |
| 表现 | `position` | 左、中、右或其他站位 |
| 表现 | `portrait` | 立绘资源 |
| 表现 | `expression` | 表情或立绘变体 |
| 表现 | `background` | 背景资源或场景状态 |
| 表现 | `voice` | 语音资源 |
| 表现 | `effect` | 屏幕、音效、镜头或震动指令 |
| 文本 | `text` | 正文 |
| 播放 | `auto_delay` | 自动切换等待时间 |
| 播放 | `can_skip` | 是否允许跳过 |
| 分支 | `option_id` | 选项ID |
| 分支 | `option_text` | 选项文本 |
| 分支 | `option_next_node` | 选项目标节点 |
| 分支 | `option_action` | 选择后的业务动作 |
| 状态 | `play_scope` | 每账号一次、每角色一次、每周目一次或可重复 |
| 回看 | `archive_group` | 剧情回看分类 |

### 9.2 必须实现的导出校验

- `story_id`、`node_id` 唯一；
- 默认下一节点和选项目标节点存在；
- 无不可达节点、无死循环，允许循环时必须显式声明；
- 章节、关卡、任务、NPC 和战斗引用存在；
- 说话人配置存在；
- 立绘、背景、语音和特效资源存在；
- 同一剧情入口没有冲突配置；
- 分支条件可解析，分支至少存在一个可达出口；
- 不允许重要选项自动默认选择；
- 多语言 Key 唯一且正文不为空；
- Lua、XML、JSON 等生成物带来源版本和生成时间，禁止手改生成文件。

## 10. 推荐实施顺序

| 阶段 | 工作 | 交付结果 |
|---|---|---|
| 1 | 修复当前线性系统基础缺陷 | 按剧情ID记录播放状态、按 `order` 排序、修复 `10042` |
| 2 | 建立剧情策划表和导出校验 | 单一配置源，可稳定生成运行数据 |
| 3 | 补齐基础演出字段 | 表情、背景、语音、速度、延时、可跳过 |
| 4 | 建立节点与选项模型 | 条件分支、结果动作、重要选择禁用自动选择 |
| 5 | 接入 Unity | 复用统一数据模型，完成真实入口和玩家操作验证 |
| 6 | 建立剧情回看和调试工具 | 按剧情ID预览、跳转节点、查看条件和重置状态 |

在第 1～2 阶段完成前，不建议直接批量扩写剧情。否则对白数量增加后，设备级播放状态、物理行顺序和多份配置源会显著提高返工成本。

## 11. 验收清单

每段新剧情至少验证以下内容：

- [ ] 从真实章节、关卡、NPC、任务或战斗入口触发；
- [ ] 触发条件和账号状态符合策划设定；
- [ ] 每句说话人、名称、立绘、站位正确；
- [ ] 台词顺序正确，无重复、漏句和错组；
- [ ] 手动点击可逐句推进；
- [ ] 自动播放时间可接受；
- [ ] 跳过行为符合配置；
- [ ] 最后一句结束后进入正确业务流程；
- [ ] 分支选项不会被错误自动选择；
- [ ] 重登后的已播放状态符合 `play_scope`；
- [ ] 不同账号、角色之间不会错误共享剧情状态；
- [ ] 所有引用资源存在且在目标客户端中可加载；
- [ ] Cocos 与 Unity 若同时交付，使用同一剧情数据和同一步骤分别验证。
