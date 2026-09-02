# Hero / 阵容迁移交接（2026-09-02）

## 1. 当前结论

- 工作区：`E:\neiwang_kapai\Game`，分支：`main`。
- 模块：`Hero`（神将/阵容），只处理阵容及其兄弟入口边界。
- 正式门禁：`G0 passed / G1-G6 pending`。
- 用户已确认 Unity 早期 Play 中的换将、切换位置、阵法学习和阵法切换修复通过；该确认不是 G6 最终验收。
- 原 G4 SQLite Batch 曾通过 16/16 控件和 6/6 语义，但 G5 检出当前 G1 Cocos 状态集大面积重复，因此 G1-G6 已正式失效；旧 G4 结果只可诊断，不可恢复门禁。
- 用户后续明确要求“跳过 Computer Use”。当前实现将其解释为跳过桌面采集工具，不等于批准跳过 G1 门禁，也不允许复用重复截图。

## 2. 固定身份与运行边界

| 端 | userId | roleId | 数据源 |
|---|---:|---:|---|
| Cocos | 7200057 | 1000115 | workspace-local MySQL + `kapai.exe` |
| Unity | 7200057 | 1000003 | `Application.persistentDataPath/LocalServer/projectx.db` |

- 原生分辨率固定为 `1334×750`；Cocos 原始窗口合同为 `1336×777 → crop(1,26,1334,750)`，禁止缩放。
- Unity、Cocos、`kapai.exe` 和 workspace-local MySQL 均不应继承上个任务的运行状态；按需启动，阶段结束自行关闭。
- 不得用 MySQL 替代用户 Unity 测试用 SQLite。

## 3. 本轮已修

- `FormationPopupPresenter`：阵法条目使用导入的 `bg_Formation` Image 作为真实 EventSystem 射线目标；切换阵法后保留权威选中态。
- `ProjectXApp`：布阵弹窗在权威 `/48` 刷新后保持可见；阵法学习不再关闭弹窗；G4 Runner 等待 Canvas 渲染边界后真实点击阵法条目。
- `HeroController.lua.txt`：换将响应后重新拉取权威阵容快照，避免交互快照选错目标神将。
- 固定账号 Runner：每次使用独立结果路径；Runner 原始结果和汇总结果分离，避免历史模块结果污染及自覆盖哈希失配。
- G1/G5 工具链：`FreezeG1Baseline` 和后续 Cocos baseline 校验均拒绝未声明的重复截图；Hero 的 `HERO-05-ADD-HERO` / `HERO-08-REPLACE` 因共用同一 `PetChangeUI` 候选列表登记为允许同视觉组。
- 工具链回归：309 项通过；迁移文档检查：34 模块无一致性错误。

## 4. 当前阻塞与证据

- 无效 Cocos 目录：`.local/ui-fidelity/Hero/cocos/g1-20260902/`。
- 重复组：`HERO-02/03/04/06/07/08/09/10/11/12/13/14/15` 内容完全相同，不能证明逐状态交互。
- G5 正确失败：`New-UnityModuleG5Evidence.ps1` 首先发现 Unity `HERO-05/08` 同图；源码核对确认两者在当前候选集合下可合法同视觉，已登记允许组。随后中央预检会继续拒绝上述 Cocos 大重复组。
- Computer Use 两轮初始化及内核重置均返回 `Transport closed`；按工具规则未复用失效句柄，也未改用 `Invoke-ClientWindow.ps1` 或坐标脚本绕过。
- 失败与用户跳过决定：`.local/unity-validation/hero-operation-ledger.json`、`.local/unity-validation/hero-computer-use-skip-20260902.json`。
- 原 G4 诊断证据：`.local/unity-validation/hero-fixed-account-latest.json`、`.local/unity-validation/hero-fixed-account-runner-latest.json`。

## 5. 继续路径

### 路径 A：严格恢复门禁（默认）

1. 读取 `UNITYCLIENT_STATUS.md`、`docs/unityclient/MIGRATION_GUIDE.md`、`docs/unityclient/modules/HERO.md`、`docs/unityclient/matrices/HERO_CONTROLS.json`、`tools/unity-migration/migration-gates.json` 和 `git status --short`。
2. Computer Use 可用后，只操作唯一原生 `ProjectX.exe / Cocos Simulator`，逐次观察、单动作、立即刷新；重新采集 16 个真实状态。
3. 每张图落同目录 `<截图名>-ui-resource-map.md`；采集后运行 `FreezeG1Baseline`，重复哈希必须为 0，声明允许组除外。
4. G1 通过后重新执行 G2 源码闭包、G3 数据预检和早期 Play证据核对、G4 Batch、G5 双端对比；不得直接恢复旧门禁。

### 路径 B：用户明确批准跳过 G1 门禁

- 必须取得“批准跳过 G1 门禁，仅做 Unity 单端 G2-G5”的明确授权并在台账记录。
- 即使获批，也只能报告 Unity 单端结果；没有当前 Cocos 双端证据时不得标记 G5 visual-complete 或进入 G6 收口。

## 6. 常用命令

```powershell
& 'C:\Program Files\Git\cmd\git.exe' status --short
& 'tools/unity-migration/Test-UnityMigrationToolchain.ps1'
& 'tools/unity-migration/Test-UnityMigrationDocs.ps1'
& 'tools/unity-migration/Test-UnityModuleG5Preflight.ps1' -Module Hero -RequireInputs
& 'tools/unity-migration/Run-UnityFixedAccountValidation.ps1' -Module Hero -DataPreflightOnly
& 'tools/unity-migration/Run-UnityFixedAccountValidation.ps1' -Module Hero -RunnerTimeoutSeconds 420
& 'tools/unity-migration/New-UnityModuleG5Evidence.ps1' -Module Hero
```

当前 `Test-UnityModuleG5Preflight.ps1 -RequireInputs` 应拒绝 Cocos 重复状态；在真实重采完成前，失败是正确结果。

## 7. 工作树保护

- `unityclient/Assets/ProjectX/res/csd/Prefabs/fuben/DadituuiLayer.prefab` 是用户既有布局/行尾变动，本轮未修改、不得覆盖。
- `UNITYCLIENT_STATUS.md` 还包含 ResourceFoundation 的既有未提交状态变动；Hero 提交只应暂存 Hero 行，禁止顺带提交该无关 hunk。
- `.local/` 为本机证据，不进入 Git；不得删除现有失败记录。
- 未获新授权前不要改动其他模块、批量暂存、重置、改写历史或强推。

## 8. 发布定位

- 本交接文档随 Hero 修复提交发布。
- 继续者先执行 `git log -3 --oneline --decorate` 获取实际提交 SHA；以远端 `main` 当前头为准，不以本文中的历史哈希作为最新证明。
