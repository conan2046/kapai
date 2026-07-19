# 《道友来封神》Cocos 当前版本 UI 普查

```powershell
python tools/cocos-audit/Export-CocosCurrentInventory.py --output tools/cocos-audit/generated
```

输出：

- `tools/cocos-audit/generated/cocos-current-entry-inventory.json`：从当前 `MainUI` 出发的产品静态闭包、主界面控件候选，以及未归属配置路由。
- `tools/cocos-audit/generated/cocos-control-candidates.json`：只扫描当前产品静态闭包后的点击/触摸/列表事件候选。
- `tools/cocos-audit/generated/cocos-runtime-reachability.json`：人工运行确认、阻塞和无效证据。

仓库含旧游戏 Lua。文件存在或 `AppDef` 配置过路由都不能证明属于《道友来封神》；只有从当前 `MainUI` 经 `OpenFunction/InitUI` 静态追达的文件进入当前候选闭包。其余标记 `unqualified`，人工证明前禁止迁移。静态候选仍不是运行时可达性证明。
