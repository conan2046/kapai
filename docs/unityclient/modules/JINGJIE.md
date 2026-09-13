# 境界模块

> 状态：Unity 实现、固定账号运行闭环与用户真人 Play 均已通过；G1 因缺当前 Cocos 原生基线而阻塞，暂不提升正式门禁。

## 范围与入口

- 主界面 Unity 节点 `btn_jingjie` 与 `Layer/Main_UI/Head` 共用境界入口，功能 ID `22`，角色等级 `10` 开放；Unity 目标 Prefab 以手调节点 `btn_jingjie` 为准，Cocos 源节点仍为 `btn_zhujue`。
- 公共框 `OneLevelLayer`，内容 `zhujue/JingjieLayer`，预览 `zhujue/Jingjieyulan`。
- 协议 `/306`：`op=1` 登录/变更同步当前境界；`op=4` 请求突破并返回结果。
- `op=2/3` 在当前服务端已注释，不纳入本轮。

## 配置来源与修改方法

权威策划表：`E:/neiwang_kapai/concept/data/excel/xml配置表/新表/jingjie_config.xlsx`。旧目录同名表已过期，不得使用。

1. 在新表维护20阶的名称、品质、等级/战力门槛、成本、属性和图标名。
2. 成本统一为三元组 `[物品ID, 子类型, 数量]`；当前20阶按产品决策仅保留金币 `[60000,0,数量]`，不再引用缺失的861–865。
3. 用现有转表链生成 Cocos Lua 与服务端 JSON；Unity `Resources/Configs/jingjie.json` 同源更新。
4. 校验20行连续 ID、每组成本均为三元组，并确认策划表、Cocos Lua、服务端 JSON、Unity JSON 完全一致。
5. 若改 `icon`，必须提交同名正式 PNG 到 Cocos 资源并同步 Unity `Resources/JingJieIcons`；不得占位。
6. 改完从最早受影响门禁重验，突破成本必须验证服务端真实扣除与重登持久化。

## Unity 实现

- `JingJieController.lua.txt`：协议发送、回包解析、断线清态。
- `JingJieViewState.cs`：权威当前境界、pending、一次性动画信号。
- `JingJieConfigData.cs`：加载并强校验20阶三元组配置，汇总金币成本并兼容未来恢复物品成本。
- `JingJieRenderBridge.cs`：绑定既有 Prefab 节点，渲染当前/下一/满阶/预览，执行等级/战力/金币条件提示与动画。
- `ProjectXApp.JingJie.cs`：主入口、公共框、真实 EventSystem/raycast 运行验证、截图资源映射与重连验证。
- `Invoke-JingJieSqliteFixture.ps1/.py`：固定 `7200057/1000003`，准备境界0、金币100000及可被服务端重算为205650的正式阵容；真实突破后断言境界1、金币90000，并执行整库恢复、重登稳定业务哈希与残留清零。

## 已修正的源问题

- 缺失道具861–865已按产品决策从策划表及三侧运行配置移除，20阶只消耗现有金币，首阶仍为10000。
- Cocos UI 与 Unity UI 已支持金币-only 成本；未来恢复物品成本时仍兼容物品+金币组合。
- `/306 op=4` 的成功 `nextId` 由服务端 C++ `int` 写为4字节；Unity 已按 `uint32` 完整消费，避免遗留2字节破坏严格协议校验。
- 本地服务端登录可能推送未主动打开的 `/213 op=15` 地图包；Unity 只消费权威数据，不再用 `functionId=0` 打开其他模块或把境界流程误判失败。
- `OneLevelLayer/GoldCheck` 不使用 Prefab 默认文本：体力来自 `/18`，金币和通宝来自 `/1004`，并随 `CurrencyStore.Changed` 刷新；运行验证逐项比对节点文本和权威值。
- `btn_jingjie` 的名称、显示、图标与布局以用户手调的主界面 Prefab 为准；角色头像 `Layer/Main_UI/Head` 复用同一境界打开逻辑。

## 已知缺口

- 正式配置第11–20阶引用 `ui_jingjie_icon_jingjie_05/06`，当前仓库和策划目录均缺 PNG；Unity 不使用占位图，缺图时隐藏图标。
- 服务端加载时会逐阶累计 `attr`，而配置值外观上已像累计值；本轮保持当前权威行为，数值策划确认后另开调整。
- 当前 Unity 固定账号定向运行已通过：6/6真实控件、6/6语义断言；覆盖用户手调 `btn_jingjie`、`Head`、GoldCheck `/18+/1004` 权威值、预览/关闭、真实 `/306 op=4`、金币100000→90000、3秒突破特效和断线重连。整库恢复、重登稳定业务哈希、清理后重建测试夹具均通过；证据位于 `.local/ui-fidelity/JingJie/unity/g3-runtime`。
- 2026-09-13 用户已完成当前 Unity 真人 Play 并明确反馈“测试通过”；控件矩阵据此记录 `manualPassed=true`。当前仍无本轮 Cocos 原生截图，因此不得把用户确认扩展为标准 G1–G6 完成。
- 2026-09-13 尝试执行 `DataPreflightOnly` 时被门禁按预期拦截：G1 仍为 `pending`。阻塞记录见 `.local/unity-validation/jingjie-operation-ledger.json`；不得绕过 G1 把夹具自检冒充正式门禁证据。
