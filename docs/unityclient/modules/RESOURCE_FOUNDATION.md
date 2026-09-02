# ResourceFoundation

## 当前边界

- 目标：把 `Bootstrap.unity` 从全量 UI 容器改为最小启动场景。
- 当前资源后端：`ResourcesUiAssetProvider`；YooAsset 只允许后续替换后端，不得让业务层直接依赖。
- 目录只保存 `key/source/parent/defaultActive` 字符串元数据；Prefab 引用拆成独立 `UiPrefabReference`，避免读取目录时加载全部 Prefab。
- 原有 Cocos Source 查找入口保持兼容；缺失对象由 `UiRouter` 按需创建。

## 组成

| 能力 | 文件 |
|---|---|
| 后端接口 | `Assets/ProjectX/src/UI/IUiAssetProvider.cs` |
| Resources 实现 | `Assets/ProjectX/src/UI/ResourcesUiAssetProvider.cs` |
| 轻量目录 | `Assets/ProjectX/src/UI/UiPrefabCatalog.cs` |
| 旧调用兼容层 | `Assets/ProjectX/src/UI/UiPrefabLoader.cs` |
| Source 路由 | `Assets/ProjectX/src/UI/UiRouter.cs` |
| 目录/场景生成与门禁 | `Assets/ProjectX/src/Editor/BootstrapSceneBuilder.cs` |

## 生命周期合同

- `GetOrCreate`：同一 key 只保留一个实例，重复查找不得重复实例化。
- `Instantiate`：用于确实允许多实例的临时 UI；必须调用 `Release`。
- `Release`：幂等；释放父级会递归释放目录子级，后续对子级的清理调用安全返回。
- 父 Prefab 首次加载时按目录恢复原 Bootstrap 子 Prefab 组合和 `activeSelf`。
- `GameServices.Dispose` 统一释放当前会话全部单例和瞬态实例。
- 首批显式“创建—关闭—销毁—重建”试点：`HeroBook`、`HeroRecycle`；现有 `ReleaseHeroAuxiliaryViews` 统一走 `IUiAssetProvider.Release`。
- 登录阶段只创建 `loginLayer`、`LoginBgLayer`、服务器列表、创角、公告、错误框、加载层和运行时 Toast；其他业务界面在首次入口按需创建。
- 其他页面本轮由“场景常驻”降为“首次访问后会话缓存”；逐模块完成 Presenter 可释放合同后再升级为关闭即销毁，禁止在未解绑状态监听时强行销毁。

## 完整性门禁

- Bootstrap 根对象固定为 `Main Camera / Directional Light / Canvas / EventSystem / ProjectXApp`。
- Bootstrap 中业务 PrefabInstance 必须为 `0`。
- 目录 key 唯一，Source 非空，父 key 必须存在，每个条目必须有独立 Prefab 引用。
- `ProjectX.Editor.BootstrapSceneBuilder.ValidateResourceFoundationBatch` 必须通过并生成 `.local/unity-validation/resourcefoundation-latest.json`。
- `tools/unity-migration/Test-ResourceFoundation.ps1` 必须通过。
- 现有 G0-G6 模块证据不会自动继承；受 Bootstrap 输入哈希影响的后续正式验证必须使用新场景重跑。

## 回退合同

- ResourceFoundation 改造前基线：`7422cbd83531b365a4188e36e21999e47d508d5d`。
- 该提交已包含用户确认的 `kapaiguaiwuLayer.prefab` 与 `zhuangbeiyangcheng.prefab` 布局修改。
- `DadituuiLayer.prefab` 只有未提交的空白/行尾漂移，不属于回退提交，也不得被 ResourceFoundation 暂存或覆盖。
- 未提交本改造前，可按本文件的变更清单逐文件恢复到上述提交；禁止对整个工作树执行 `reset --hard`。
- 若改造提交后发现阻断问题，回退目标仍是上述提交，使用独立 revert 提交恢复 ResourceFoundation 变更，保留用户 Prefab 基线。

## 后续 YooAsset 接入

- 保持 `IUiAssetProvider` 不变，新增 YooAsset 实现并先使用 OfflinePlayMode。
- 业务层、Presenter 和 `UiRouter` 禁止直接调用 YooAsset API。
- 分包、热更、CDN、DLC 与版本回滚另立门禁，不混入本轮 1～4 步。
