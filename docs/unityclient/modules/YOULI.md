# 游历三界（YouLi）模块证据

## 范围

独立迁移当前玩法大厅 `function_id=1` 的游历三界页面与 `/335 op=1/2/3`。测试号可从五地点列表发起单地点/一键派遣并领取已完成奖励；每次写操作成功后重查 op1，不用总体成功包伪造单条状态。

## 三方证据

### 当前 Cocos 调用链

`Layer/Main_UI/ButtonGroup1/btn_wanfa → Main.WanFaEntranceUI → EnterBtn(function_id=1) → Utils:OpenFunction(1) → WanFa.YouLiMainUI → CreateUINode("csd/youli/youlisanjie.csb") → LuaNetSendMsg:QueryYouLiInfo()`。

真实子页面：

- `csd/youli/youli.csb`：单地点详情、神将选择、方式/时长与领取。
- `csd/youli/yijianyouli.csb`：一键游历。
- `csd/youli/youlifangshi.csb`：初/中/高级方式选择。
- `csd/youli/youlishichang.csb`：4/8/12 小时时长选择。

### 协议与服务端

- `client/ProjectX/src/NetWork/LuaNetCmd.lua`：`MSG_YOULI=335`。
- `server/src/protocol.h`：`MSG_YOU_LI=335`。
- `server/src/pack_deal.cpp`：注册到 `CPackageDeal::DealYouLi`。
- `op=1`：无额外请求字段；`CXunBaoManage::GetYouLiMsg` 返回 `count:u8`，每条为 `id:u8, type:u8, duration:u8, heroId:u16, lastTime:u32, endTime:u32, fragment:u16, rewardBatchCount:u8, reward batches, dialogueCount:u8, dialogueId:u16[]`。
- `op=2`：请求 `count:u8 + (heroId:u16,id:u8,type:u8,duration:u8)[]`；服务端逐条跳过非法/重复/未拥有神将/等级品质/费用不足项，但最终仍返回 `op=2 + PRO_SUCCESS`，因此成功包不等于每条均开始。
- `op=3`：请求地点 id 列表；仅结束的有效游历被合并领奖，响应 `op=3 + PRO_SUCCESS + 奖励`。
- 未知 op：`DealYouLi` 不写业务结果，但仍统一发送原消息；Unity 只处理 1/2/3，不伪造状态。

### 配置

当前 `server/config/json/sanjie.json` 共 5 个地点：陈塘关、朝歌城、西岐、碧游宫、昆仑山；解锁等级 30/35/40/45/50。Unity 配置为同源字段裁剪副本。

## Unity 实现

- `YouLiCatalog`：加载 5 个当前地点。
- `YouLiStore`：将服务端进行中记录合并到配置地点，明确区分“成功空态”与“尚未响应”。
- `YouLiPresenter`：绑定真实 `youli/youlisanjie` Prefab，渲染地点、等级与权威状态；开放地点按钮、一键派遣和领取按钮均为真实交互。
- `Gameplay.YouLiController`：发送/解析 `/335 op=1/2/3`；op2/3 成功后强制重查 op1，奖励批次按通用奖励结构跳读。
- 当前简化选择合同：自动选择首名上阵神将（无上阵时取首名拥有神将），方式与时长默认选择合法的 `1/1`；完整选择弹窗资产已保留，不影响协议闭包测试。
- Gameplay 路由仅在 `function_id=1` 调用该独立模块，不再显示大厅边界提示。

## 验证

最终动态证据：

- 命令：`pwsh -File tools/unity-migration/Run-UnityModuleValidation.ps1 -Module YouLi`
- userId=`7200057`，roleId=`1000115`（99级全解锁测试号）。
- 2026-08-23 `/335 op=1` 真实查询通过，权威记录数 `0`。
- Unity 状态：5 个配置地点完整渲染，成功空态成立。
- Unity 单端截图：`build/ui-migration/bootstrap-youli.png`，`1334×750`；只证明运行态可见，不构成 Cocos 1:1 证据。
- 严重异常：0；硬门禁 8 个控件、1 个运行态截图、Python UI 门禁 16/16；脚本已关闭本轮 kapai、Unity。

## G5/G6 视觉与发布收口（2026-08-23）

- 从 Cocos `sanjie_dat.lua` 恢复 `pic1=map_01..05`，把五张原始 `InstancesBg` 场景图接入 Unity Resources；空记录时隐藏“我的游历”详情面板。
- Cocos/Unity 同账号 `7200057/1000115`、原生 `1334×750` 空态完成并排、叠加、差异报告与人工验收；战场背景、横向地点列表、地点名和操作层级一致。
- 8/8 控件、3/3 语义断言、严重异常 0；自动复盘 1/1 失败已诊断解决。
- 两次正式 `BootstrapSceneBuilder.BuildBatch` SHA-256 均为 `7C0E65C8D6D8E162059B0DC45149B64042CE89EA4D0CB6C944D8E1A678CA8FBA`，中央工具链 190/190。
- 最终证据：`.local/ui-fidelity/YouLi/compare/g5/report.json`、`.local/ui-fidelity/YouLi/compare/g5/manual-acceptance.json`、`.local/unity-validation/youli-latest.json`、`.local/unity-validation/youli-retrospective-latest.json`。

## 写操作验收边界

- op2/op3 已完整接线且成功后强制重拉 op1；中央自动化为保护共享测试号只执行只读 op1，不主动制造 4/8/12 小时游历记录。
- 人工点击写操作时，界面只接受重拉后的权威记录；服务端静默跳过某条派遣时不会因总体成功而伪造“游历中”。

## Steam SQLite S5（2026-08-20）

- 证据：`.local/unity-validation/steam-sqlite-s5-youli-latest.json`，状态`Passed`。
- S5 严格按当时 manifest 验证非变更查询 `/335 op=1`；2026-08-23 已补齐 op2/op3 客户端闭包，并继续坚持以 op1 重查结果为准。
- SQLite/MySQL新隔离角色均重复查询两次并在正常退出后重启复查；运行期双方各45响应、重启各20响应，归属包始终为2字节权威空态`0100`且逐字节一致，manifest单边协议0、结构差异0。
- 数据库`xunbao/mission/save_data`、角色等级/经验/货币和账号货币原始值一致，游历记录数0、归属写入0。服务端与Unity裁剪配置的5地点`id/name/quality/unlock/show`语义一致，解锁等级为`30/35/40/45/50`。
- 中央工具链`133/133`；只删除隔离库`fxl_game_youli_s5_v1`，正式`fxl_game_local`及MySQL源码/驱动/构建/Schema/脚本/回归全部保留。S5下一模块为`FengShenStory`。
