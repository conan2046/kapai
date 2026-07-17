# 邮件模块

## 范围

邮件列表、本地已读、正文、附件、单封领取、奖励和领取后权威复查。

## 三方证据

- 协议：`/128 MSG_SERVER_XINSHI`。
- `op=2`：邮件列表。
- `op=3`：单封领取。
- 本地自动化注入只在 `local_test=1` 下生效。

## 实现

- `MailStore + MailPresenter + MailController.lua`。
- 入口：`Layer/Main_UI/ButtonGroup7/btn_mail`。
- 真实 Prefab：`MailLayer.prefab`，未被自动化重写。
- 复用 VirtualList、ResourceService、RewardStore/RewardPresenter、Toast、UiStack。

## 已验证

- 隔离角色 `717026`：注入 → 列表 → 已读 → 正文/附件 → 单封领取 → RewardPresenter → 再拉列表确认移除。
- 正文：`Unity mail validation`；附件：`10点贵族经验`。
- GameView：详情与列表均为 `1334×750`。
- C# 编译 `0 error / 0 warning`。

## 遗留

- 邮件红点、一键领取、删除、确认弹窗、空态和批量错误回归。
