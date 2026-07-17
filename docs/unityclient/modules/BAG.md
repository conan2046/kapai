# 背包模块

## 范围

背包全量、增量、整理、真实道具使用、奖励与持久化。

## 三方证据

- 全量：`PRO_PACKAGE/8`。
- 增量/操作：`PRO_PACKAGE_UPDATE/15`。
- 旧客户端配置：`item_dat.lua`。
- 本地隔离注入仅用于自动化，不替代正式使用协议。

## 实现

- `BagStore` 是唯一背包状态源，Lua 不保存临时物品字典。
- `BagPresenter` 复用真实背包 Prefab 和五格条目模板。
- 图标统一走 ResourceService：`ItemIcons/equip{pic} → MonsterBust/{pic} → placeholder`。
- `/15` 支持全量整理及单格新增、更新、删除。
- 使用按钮按旧协议发送 slot、数量和 target。

## 已验证

- 非空隔离角色真实渲染 2 组物品。
- `/15 op=6` 整理后 Store 和 UI 保持一致。
- 隔离角色注入 `3201×1` 后使用，收到固定奖励并从背包删除。
- 重新登录确认消耗持久化，缺图 `0`。

## 遗留

- 更多 use_type、批量使用、出售、合成、跳转来源、完整空态/错误态。
