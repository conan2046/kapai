# 游历三界（YouLi）模块证据

## 范围

独立迁移当前玩法大厅 `function_id=1` 的游历三界主页面与 `/335 op=1` 权威状态。开始游历、单次/一键派遣、领取奖励保留协议与 UI 边界，本阶段不消耗角色资源。

## 三方证据

### 当前 Cocos 调用链

`Layer/Main_UI/btn_wanfa → Main.WanFaEntranceUI → EnterBtn(function_id=1) → Utils:OpenFunction(1) → WanFa.YouLiMainUI → CreateUINode("csd/youli/youlisanjie.csb") → LuaNetSendMsg:QueryYouLiInfo()`。

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
- `YouLiPresenter`：绑定真实 `youli/youlisanjie` Prefab，渲染地点、等级与权威状态。
- `Gameplay.YouLiController`：发送/解析 `/335`；真实奖励批次按通用奖励结构跳读。
- Gameplay 路由仅在 `function_id=1` 调用该独立模块，不再显示大厅边界提示。

## 验证

最终动态证据：

- 命令：`pwsh -File tools/unity-migration/Run-UnityModuleValidation.ps1 -Module YouLi`
- userId=`1`，roleId=`1000005`。
- 结果 UTC：`2026-07-18T05:52:49.8207076Z`。
- `/335 op=1`：SEND request=5；RECV request=5，`0.111s`；权威记录数 `0`。
- Unity 状态：5 个配置地点完整渲染，成功空态成立。
- Unity 单端截图：`build/ui-migration/bootstrap-youli.png`，`1334×750`；只证明运行态可见，不构成 Cocos 1:1 证据。
- 严重异常：0；Python UI 门禁 16/16；脚本已关闭本轮 MySQL、kapai、Unity。

## 视觉 1:1 记录

- 状态：`pending-cocos-baseline`；功能/协议已通过，视觉完成结论撤销。
- Cocos 脚本：本文件“三方证据”已记录入口、Controller、CSB 与 `/335`；下一轮补精确行号和动态创建节点清单。
- 操作步骤：待记录从 `btn_wanfa → 游历三界` 到五地点空态及各地点弹窗的逐步操作。
- UI 资产：已锁定 `youlisanjie/youli/yijianyouli/youlifangshi/youlishichang` 五组完整相对路径；贴图、字体、Timeline、动态节点待清单化。
- 缺失证据：Cocos 同状态 `1334×750` 截图、Cocos↔Unity 节点映射、叠加/差异图、交互与动画逐项对照。
- 当前 Unity 截图不得用于标记 `visual-1to1-complete`。

## 遗留项

- 开始/领取属于变更型操作，需为可控神将与游历存档建立 Manifest 夹具后独立验证。
- `op=2` 的“部分条目被静默跳过但总体成功”必须在后续 UI 中逐条重拉 `/335 op=1` 确认，不能只看成功字节。
