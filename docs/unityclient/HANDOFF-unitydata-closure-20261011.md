# Unity 数据源补齐交接（2026-10-11）

## 已完成

- 工程`E:\neiwang_kapai\Game`；Unity实际进程`-projectPath`同工程下`unityclient`。会话工作树位于C盘，本轮全部改动在E盘。
- 已按用户顺序完成Fish → Answer → HappyWheel → FaBaoSearch → HeroCombat → Attributes → CasualGameplay → RoleBattle。
- 新增8份Unity工作簿，47个Sheet、5266条源记录；接管9个JSON、35个XML、4个CSV文件。角色/战斗组32个Sheet含服务端初始化仍读取的旧培养配置；没有开启旧功能或改迁移门禁。
- `Export-UnityOwnedTables.ps1`以`unity-owned-tables.json`定位工作簿/Sheet及类型，先检查整组/全部输入再写产物；可定向导出、只验证、只生成服务端中间产物。客户端和服务端全量导出入口已接入。
- 答题、转盘、钓鱼真正消费SQLite的配置同步到生成种子、运行种子及正式初始化结构标记段。玩家数据未直接读取或修改。
- 所有已接管旧运行文件的业务值、字段语义均与原HEAD逐项核对；JSON/XML/CSV运行文件保留原字节。Cocos旧server链、Prefab、meta、截图没有改动；用户已授权本轮内容提交并推送远程main，发布记录以Git为准。

## 验证

| 检查 | 结果与证据 |
|---|---|
| 源表→运行文件全字段往返 | 47个Sheet通过；`.local/unitydata-closure-20261011/baseline-verification.json`记录原基线语义核对 |
| 独立回归 | `unitydata/tools/tests/test_unity_owned_tables.py`七项通过；`.local/unitydata-closure-20261011/tests.log` |
| 改表传播 | 八组各改变一个源字段，验证生成及运行JSON/XML/CSV更新；钓鱼/答题另核对SQLite实值 |
| 非法输入 | 重复ID、负金币、非整数、公式缓存被拒绝，产物无写入；最后一组失败也不写前面组 |
| 删除与状态保留 | 删除鱼种后既有隔离DB不残留该配置；鱼篓玩家行保持 |
| 特殊合同 | 客户端钓位map_resource保留、服务端/SQLite不混入；角色成长XML601行含原空占位行 |
| 全量双端导表 | 最新源表/验证代码下通过；服务端56个通用转换产物、11项既有权威覆盖、未解决差异0；客户端61文件；全部登记表ValidateOnly通过 |
| 最终产物 | 服务端生成JSON67个、XML35个；Excel递归68个；日志`.local/unitydata-closure-20261011/final-full-export.log` |
| 工作簿视觉检查 | 47个Sheet均渲染并查看6张QA板；预览/检查记录只在`.local/unitydata-closure-20261011` |
| 文本差异 | `git diff --check`通过；tracked修改仅README、三份现有数据工具、SQLite初始化结构及三个旧种子 |

数据/工具变更未启动Play；上述结果是数据链与隔离SQLite验证，不是玩家画面验收。新源表目前保持原参数，没有重新平衡数值。

## 用户要求的旧表Markdown清单

`docs/unityclient/UNITYDATA_LEGACY_TABLES_20261011.md`：48个已接管文件逐项映射到新工作簿/Sheet，标明旧运行路径、CSV编辑源身份退役、种子和旧导表入口用途，以及未纳入本次的保留文件。

原缺口审计保留历史快照，在文首指向本轮结果；日常修改/导出操作唯一说明为`unitydata/README.md`。

## 保留边界

- 尚有4个Steam排除相关JSON没有进入Unity服务端中间目录，以及41个XML旧基线未纳入本轮工作簿；旧表清单逐文件列出，未自动删除或重新开启玩法。
- 战斗表现DAT、部分World文本和玩法路由映射仍有历史快照/旧生成入口，11张权威JSON仍覆盖旧Excel转换结果；不将本轮47表收口等同于全工程所有配置源统一完成。
- 导表不热更新运行中的单机服务端。实际SQLite配置在下次启动时通过正式`001_initial_schema.sql`更新；无需为本轮不变的参数重写当前Slot。
- `server/config`、原Cocos数据以及原server的导表脚本继续独立保留。

本轮数据链阶段可收口；后续规则修改优先改对应Unity源表并定向导出，不再直接改上述运行JSON/XML/CSV或种子。
