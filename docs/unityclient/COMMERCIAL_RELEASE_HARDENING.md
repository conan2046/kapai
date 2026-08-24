# Unity 商业发布工程化专项执行合同

> 状态：`planned / 未执行`
> 执行触发：用户明确要求“执行 `COMMERCIAL_RELEASE_HARDENING.md`”后启动。
> 约束：本文件不维护迁移完成率，不替代 `UNITYCLIENT_STATUS.md` 或 `MIGRATION_GUIDE.md`，不改变现有 G0-G6 门禁。

## 1. 目标

在当前功能迁移和本地单机闭环基础上，补齐 Steam 商业发布所需的资源、字体、程序集、自动测试、CI/CD、工程文档和可选本地化能力。

最终目标：构建体积和运行内存可量化、资源可分组异步加载、字体授权合规、程序集边界清晰、纯逻辑有单测、构建可复现、发布验收可自动执行。

## 2. 当前实证基线（2026-08-24）

| 项目 | 当前值 | 结论 |
|---|---:|---|
| Steam Windows发布树 | 589文件，约3377.38MB | 包体必须专项治理 |
| `resources.assets.resS` | 约3099.79MB | 单一Resources数据体积过大 |
| `Assets/ProjectX/Resources` | 5748文件，源文件约169.22MB | PNG导入后体积显著膨胀 |
| `Assets/ProjectX/res` | 约234.86MB | 包含Cocos迁移源、Prefab、字体和生成资料 |
| Addressables | 未安装/未接入 | 当前主要使用同步`Resources.Load` |
| 项目asmdef | 0 | 运行代码集中于`Assembly-CSharp` |
| `ProjectXApp.cs` | 约13979行 | Core/UI职责和依赖需要拆解 |
| Unity项目测试 | Test Framework已安装；项目测试0 | 缺少EditMode/PlayMode单测程序集 |
| CI/CD | 未发现 | 当前依赖人工本机构建 |
| 字体 | 4个主要字体约25MB | 需审查授权、字符覆盖和包体 |
| 本地化 | 无统一框架 | 至少55个运行时C#、17个Lua文件含中文 |
| 当前`.meta`改动 | 0 | 禁止执行“926项meta基线提交” |

注意：`Resources`内容会进入构建，但当前代码是按需加载并缓存，没有发现`Resources.LoadAll`。禁止把“全部进入构建”误报为“启动即全部进入内存”。

## 3. 总体执行规则

1. 当前用户指定模块收口后再启动本专项；不得插入模块G0-G6中途。
2. C0-C6严格串行，上一阶段未通过不得进入下一阶段。
3. 每阶段先测量、后修改、再复测；不得用主观“应该变小/变快”验收。
4. 资源、字体、Prefab或加载路径变化后，按输入指纹撤销受影响的旧视觉/运行结论并定向重验。
5. 不删除Cocos权威源；生产资产与迁移源分层保存，禁止用全盘移动破坏可追溯性。
6. 不创建`.meta baseline`提交；新生成或移动的meta只随明确范围文件处理。
7. 未经用户明确要求，不暂存、提交或推送。
8. 不追补历史耗时；继续使用后续门禁与Runner计时样本。

## 4. 阶段顺序

| 阶段 | 优先级 | 内容 | 退出条件 |
|---|---:|---|---|
| C0 | P0 | 商业基线、预算、语言和字体授权决策 | 预算与产品范围由用户确认 |
| C1 | P0 | 纹理导入、图集、无用资源和包体治理 | BuildReport与运行内存达到确认预算 |
| C2 | P0/P1 | 资源接口异步化、Addressables分批迁移 | 试点和扩展组均通过生命周期/失败回退 |
| C3 | P0/P1 | 字体授权、TMP与可选i18n基础 | 无缺字、无布局逃逸、授权可追溯 |
| C4 | P1 | asmdef边界与NUnit测试 | 无循环依赖，核心纯逻辑测试通过 |
| C5 | P1 | Windows自托管CI/CD | PR、夜间、发布三层流水线可复现 |
| C6 | P2 | 架构文档、贡献规范和商业发布验收 | 文档、干净机构建、包体及回归全部通过 |

## 5. C0：商业基线与决策冻结

### 工作项

- 保存当前Steam BuildReport、发布Manifest、文件体积排行和目录体积。
- 采集启动、主界面、战斗、连续切换主要页面后的CPU/GPU/内存基线。
- 区分：磁盘包体、下载体积、首屏内存、峰值内存、资源加载耗时。
- 用户确认目标发行语言：仅简体中文，或简中/繁中/英语/日韩等组合。
- 审计`MicrosoftArial.ttf`、`xiaokaiSJ2.ttf`、`STLITI.TTF`、`STXINWEI.TTF`的商业嵌入授权。
- 用户确认包体、首屏内存、峰值内存、首屏时间和补丁体积预算；无真实产品预算时不得擅自编造阈值。

### 交付物

- `.local/commercial-hardening/c0-baseline.json`
- `.local/commercial-hardening/c0-build-size.csv`
- `.local/commercial-hardening/c0-memory-profile.md`
- `.local/commercial-hardening/c0-decisions.json`

## 6. C1：资源体积与导入治理

### 工作项

- 从BuildReport反查`resources.assets.resS`的大户目录和具体资产。
- 为Windows目标建立纹理导入规则：压缩格式、最大尺寸、透明度、MipMap、Read/Write、Sprite模式。
- 优先处理`ProjectXAnimation`、`WorldUI`和大尺寸战斗/特效图。
- 建立SpriteAtlas候选清单，验证合批、边缘出血、九宫格和像素清晰度。
- 清理生产构建未引用的迁移中间物；原始Cocos证据移出生产导入路径但继续保留可追溯副本。
- 每批修改后生成包体差异、内存差异和双端视觉回归清单。

### 禁止事项

- 禁止一次性改全部纹理设置。
- 禁止仅看PNG源文件大小判断Unity运行体积。
- 禁止删除CSB/CSD、原图或迁移Manifest来换取表面包体下降。

## 7. C2：异步资源与Addressables

### 工作项

- 在`ResourceService`后建立统一异步接口、句柄、引用计数、失败回退和释放合同。
- 安装并锁定与Unity 2022.3兼容的Addressables版本。
- 首个试点只选一个独立低风险资源域；验证成功后再扩展。
- 推荐分组：Bootstrap、本地Lua/配置、公共UI、模块UI、角色/怪物、战斗特效、地图/大背景。
- `ProjectXAnimation`与非首屏`WorldUI`优先迁移；启动资源和必要配置保持小型本地组。
- Steam首版默认本地Catalog；只有用户明确要求远程内容更新时再设计远程Catalog、版本回退和内容签名。
- 建立允许继续使用`Resources.Load`的最小白名单，其余运行时直调由静态检查拒绝。

### 验收

- 冷启动、缓存命中、缺资源、损坏Catalog、加载取消、界面关闭释放、重复进入、重启全部验证。
- 不出现悬空句柄、重复加载、旧页面资源泄漏、首屏黑屏或同步阻塞回退。
- 受影响模块重新执行当前有效的逻辑和视觉门禁。

## 8. C3：字体、TMP与本地化基础

### 工作项

- 未证明商业授权的字体不得进入正式发行候选。
- 统计C#、Lua、配置、Prefab和服务器可见文本字符集。
- 选择已授权主字体；建立常用静态字符集、数字/符号集和受控Fallback策略。
- 玩家名、公告等动态文本必须单独验证，禁止静态子集导致缺字。
- 按模块从Legacy Text迁移TMP；每批验证字号、基线、描边、换行、截断、按钮命中区和视觉差异。
- 若C0确认多语言：建立文本ID、语言表、参数化格式、复数/日期规则、服务端错误映射和字体Fallback。
- 若C0确认仅简体中文：只完成字体合规与文本接口预留，不强制全量抽表。

## 9. C4：程序集边界与自动测试

### asmdef顺序

1. `ProjectX.Diagnostics`
2. `ProjectX.Network`
3. `ProjectX.Data`
4. `ProjectX.LuaRuntime`
5. `ProjectX.UI`
6. `ProjectX.Editor`
7. `ProjectX.Tests.EditMode`与`ProjectX.Tests.PlayMode`

拆分前先生成实际依赖图；发现循环依赖时先抽接口，不通过复制类型或开放全局访问绕过。

### NUnit优先范围

- 协议帧、字段顺序、错误包和断包解析。
- Store状态转换、账号切换清理和重连状态机。
- Catalog配置解析、缺字段、重复ID和非法值。
- 奖励、货币、排序、过滤、装备校验等纯函数。
- Lua DTO到C# ViewState的边界合同。

NUnit只减少纯逻辑回归成本，不替代真实Button、协议交互、SQLite持久化、G4/G5/G6或用户Play。

## 10. C5：CI/CD

### 基础设施

- 优先采用Windows自托管Runner/Jenkins节点，固定Unity版本、许可证、Git LFS、MSVC、Python和PowerShell 7。
- 密钥、许可证和Steam凭据只从受控Secret注入，不写仓库或日志。

### 流水线

| 层级 | 触发 | 内容 |
|---|---|---|
| PR | 每次变更 | JSON/PowerShell语法、文档、Git范围、中央工具链、EditMode测试 |
| Nightly | 每晚 | Unity编译、PlayMode、固定账号模块回归、包体趋势 |
| Release | 人工批准 | 两次BuildBatch、哈希一致、Manifest、禁用文件、干净机/生命周期验收 |

CI失败不得通过重新运行掩盖；偶发失败必须保留日志、归类根因并修复稳定性。

## 11. C6：文档与最终商业验收

### 文档

- `unityclient/ARCHITECTURE.md`：程序集依赖、Lua/C#职责、资源生命周期、协议权威边界。
- `CONTRIBUTING.md`：环境、构建、测试、资源导入、提交和发布命令。
- 两份文档不得复制完成率、当前批次或G0-G6 SOP，只链接唯一状态源与迁移指南。

### 最终验收

- 当前Steam保留模块功能、视觉、持久化和用户确认仍有效。
- 发布包体、首屏与峰值内存、加载耗时满足C0批准预算。
- 无缺字、字体授权缺口、同步大资源阻塞、资源泄漏和失效Addressables句柄。
- CI从干净工作区产出与本地相同版本的可运行包及Manifest。
- Steam下载/安装、只读目录、中文路径、首次/二次启动、更新、崩溃恢复和卸载残留通过。

## 12. 开始执行时的固定入口

```powershell
& 'C:\Program Files\Git\cmd\git.exe' status --short
pwsh -NoProfile -File tools/unity-migration/Test-UnityMigrationToolchain.ps1
pwsh -NoProfile -File tools/unity-migration/Test-UnityMigrationDocs.ps1
pwsh -NoProfile -File tools/unity-migration/Test-UnityMigrationGitScope.ps1 -SummaryOnly
```

启动后先执行C0，只采集当前数据并向用户提交预算/语言/字体决策；未取得确认不得进入C1。

## 13. 明确排除

- 不执行旧HANDOFF中的“926项`.meta`基线提交”。
- 不因Addressables删除Cocos权威源或现有迁移证据。
- 不把asmdef、NUnit或CI冒充模块G4-G6证据。
- 不在未确定海外发行范围前擅自全量翻译。
- 不在用户未授权时提交、推送、安装外部服务或发布Steam内容。
