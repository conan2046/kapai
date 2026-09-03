# 验证环境接手说明（交给后续 AI）

> 基线日期：2026-09-03。实时功能进度仍只读取根目录 `UNITYCLIENT_STATUS.md`。

## 本次改变

1. 新增脱敏 SQLite 固定账号基准：`server/sql/sqlite/fixtures/projectx-validation-base.db`。
2. 基准只保留 `1/1000001/S8D01` 与 `7200057/1000003/T00057`；清除了登录日志、在线统计、临时身份、竞技排行和帮派运行数据。
3. 新增 SHA/身份 Manifest：`projectx-validation-base.manifest.json`。
4. 新增安全安装器：安装前验证基准，停止相关进程，备份原 `projectx.db` 后再替换；支持显式恢复。
5. `Test-UnityMigrationDocs.ps1` 默认只做纯净克隆可执行的静态合同检查，不再要求 `.local` 截图已存在。
6. `Test-UnityMigrationDocs.ps1 -RequireLocalEvidence` 继续严格检查本机控件截图、视觉报告和运行证据。
7. PNG/JPG 截图继续位于 `.local/ui-fidelity/`，不上传 Git；缺图必须本机重跑，不能复制旧图或伪造路径。

## 拉取后的第一组命令

先执行 `git status --short`。若已有状态文档、Prefab、ResourceFoundation 或大量 `.meta` 改动，先由接手 AI 逐项登记并保护，禁止直接 reset、checkout 或用远端覆盖；确认本地改动安全后再对齐 `origin/main`。

```powershell
git fetch origin --prune
git lfs install
git lfs pull
pwsh -NoProfile -File tools/unity-migration/Install-UnityValidationDatabase.ps1 -Action Verify
pwsh -NoProfile -File tools/unity-migration/Install-UnityValidationDatabase.ps1 -Action Install
pwsh -NoProfile -File tools/unity-migration/Test-UnityMigrationToolchain.ps1
pwsh -NoProfile -File tools/unity-migration/Test-UnityMigrationDocs.ps1
```

`Install` 会输出 `BackupPath`。必须保存该路径；要恢复安装前的本地库：

```powershell
pwsh -NoProfile -File tools/unity-migration/Install-UnityValidationDatabase.ps1 `
  -Action Restore -BackupPath "<Install输出的BackupPath>"
```

## 进入模块前

```powershell
# 只做数据快照、注入、断言、恢复，不启动 Unity
pwsh -NoProfile -File tools/unity-migration/Run-UnityFixedAccountValidation.ps1 `
  -Module <Module> -DataPreflightOnly

# 对应门禁需要本机视觉证据时再严格检查
pwsh -NoProfile -File tools/unity-migration/Test-UnityMigrationDocs.ps1 `
  -Module <Module> -RequireLocalEvidence
```

缺 Unity 图片：使用目标模块登记的标准 batch Runner 重建。缺 Cocos 图片：只能通过原生 `ProjectX.exe / Cocos Simulator`、固定身份、Computer Use preflight 和真实入口重建；Computer Use 不可用或用户要求跳过时，保持 G1/G5/G6 pending。

## 不要做

- 不要提交 `.local/`、`build/`、运行日志、WAL/SHM 或本机截图。
- 不要用 MySQL 代替 Unity persistentDataPath SQLite。
- 不要无备份覆盖接手人的 `projectx.db`。
- 不要把普通文档检查通过写成 G1/G5/G6 动态证据通过。
- 不要批量提交 Unity 自动重写的 `.meta`；先用 Git scope 工具区分语义修改与导入漂移。
