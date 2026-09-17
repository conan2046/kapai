# Jingjie（境界）内嵌「背包」切页 — 实现方案 A（交接手稿）

> 需求：主界面点头像 `Head` 打开 `DynamicUi_JingjieLayer`；在该页左侧 `Btn_ListView` 增加一个「背包」切页，可在本页内切换查看背包，无需退回主界面。
> 方案 A：把 Jingjie 由「单标签」改为「两标签模块（境界 / 背包）」，复用代码库既有两标签范式（`SelectHeroEquipmentTab` `ProjectXApp.cs:15281` + `SetTabText` `:16493`），切换时显隐 `jingJieView` 与 `bagView`，**不改动任何 prefab**。
> 约定：本手稿只描述改动；实际改 `ProjectXApp.JingJie.cs`（partial of `ProjectXApp`）由对接 AI 落地。

> **实施状态（2026-09-17 16:51）**：已按本手稿落到 `unityclient/Assets/ProjectX/src/Core/ProjectXApp.JingJie.cs`（新增枚举/字段、`ConfigureJingJieFrame` 启用 `Button2_Runtime`、`SetJingJieTabs`/`ShowJingJieSurface`/`ShowJingJieBag` 三方法、`TryHandleJingJieBack` 增加背包态回退）。未改 `BagPresenter.cs`，**未改 prefab**（详见 §7 修正）。
>
> **⚠️ 实机回归（2026-09-17 17:30）**：用户测试「点头像进 Jingjie 未看到背包标签」。**根因**：本手稿原误判 `Button2_Runtime` 为 frame 预设节点；实际 Jingjie 的 `OneLevelLayer` 实例上**不存在**该节点，须像 `HeroCultivation` 那样在运行时从 `Button1` `Instantiate` 克隆（`ProjectXApp.cs:15494`）。原 `SetJingJieTabs` 只做 `Find`+`BindClick`，`Find` 返回 null → 整段静默 no-op，标签永不出现。**已修复**：`SetJingJieTabs` 在 `second==null` 时克隆并 `name="Button2_Runtime"`、偏移 `-100f`、绑定 `ShowJingJieBag`（见 §2.2 修正版）。待用户重测。

---

## 0. 关键事实（已核对，确保 diff 准确）

- 共享外壳：`OneLevelLayer.prefab` → `Layer/Panel_12/Bg/Btn_ListView/Panel_10/{Button1, Button2_Runtime}` 为单槽位左侧切页条。
- Jingjie 打开链路：`ProjectXApp.JingJie.cs`
  - `ShowJingJie()` `:299` → `EnsureJingJieBridge()` `:363`（加载 `zhujue/JingjieLayer`=`jingJieView` + `Jingjieyulan`=预览，二者作为 frame 的 `DynamicUi_` 子节点）
  - `ConfigureJingJieFrame()` `:400` → 现把 `Button1` 设「境界」、`Button2_Runtime` **隐藏**（即当前单标签）。
  - `HideOtherOneLevelChildren()` `:389` → 隐藏除 jingJieView/jingJiePreviewView 外的所有 `DynamicUi_`。
- 背包：`ProjectXApp.cs`
  - `EnsureBagPresenter()` `:13730` → `bagView` = 源 `zhujue/beibao`（frame 的 `DynamicUi_` 兄弟节点，由 `GetDynamicUiRoot()` `:16484` 挂载到 frame 的父级 Canvas）；`BagPresenter`(`:51-56`) 把 `Button1` 设「全部」并 `BindClick` 到 `tabClickCount++`，内容根 `Layer/beibao_layer`，`Render()` `:85`。
  - `IsBagOpen` `:646` = `UiStack.Current == bagView`。
- 复用前提：`CocosUiView.BindClick`(`CocosUiView.cs:108`) 第 126 行执行 `onClick.RemoveAllListeners()`，即**重绑会覆盖旧监听**，可解决与 `BagPresenter` 已绑 `Button1` 的冲突。
- 同 partial 类内 `JingJie.cs` 可直接访问主 partial 的 `bagView` / `bagPresenter` / `EnsureBagPresenter()` / `SetTabText` / `SetOneLevelFrameVisible` / `PopUiStackWithHudRefresh`。

---

## 1. 改动清单

| 文件 | 位置 | 改动 |
|---|---|---|
| `unityclient/.../Core/ProjectXApp.JingJie.cs` | 字段区（`:24` 后） | 新增枚举 `JingJieSurfaceMode` + 状态字段 |
| 同上 | `ConfigureJingJieFrame()` `:400-423` | 由「隐藏 Button2」改为「启用两标签 + 绑定点击」 |
| 同上 | 新增 `ShowJingJieSurface()` / `ShowJingJieBag()` | 两个切页态的显隐与标签重绑 |
| 同上 | `TryHandleJingJieBack()` `:351-361` | 背包态先回境界态，再关整页 |
| `BagPresenter.cs` | 无 | **不改**（分类仅「全部」一项，无副作用） |
| 任意 `.prefab` / `.csd` | 无 | **不改**：`Button2_Runtime` 在 Jingjie 的 `OneLevelLayer` 实例上**不存在**，改为运行时从 `Button1` `Instantiate` 克隆（见 §2.2 / §7） |

---

## 2. 具体代码（复制即用）

### 2.1 新增字段 / 枚举（插入 `:24` `jingJieValidationRunning` 之后）

```csharp
        private enum JingJieSurfaceMode { JingJie, Bag }
        private JingJieSurfaceMode jingJieSurfaceMode = JingJieSurfaceMode.JingJie;
```

### 2.2 改写 `ConfigureJingJieFrame()`（原 `:400-423`）

原方法把 `Button2_Runtime.SetActive(false)`。改为启用两标签并绑定到新切页方法：

```csharp
        private void ConfigureJingJieFrame()
        {
            EnsureOneLevelFrame().Apply(OneLevelFrameMode.Standard);
            CocosUiBinding binding = oneLevelFrameView.Binding;
            RectTransform root = binding.transform as RectTransform;
            if (root != null)
            {
                root.pivot = new Vector2(0f, 1f);
                root.anchorMin = root.anchorMax = new Vector2(0f, 1f);
                root.anchoredPosition = Vector2.zero;
                root.localScale = Vector3.one;
            }
            Text title = binding.Find("Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
            if (title != null) title.text = "主角";
            Transform help = title?.transform.Find("Button_1");
            if (help != null) help.gameObject.SetActive(false);
            Transform first = binding.Find("Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button1")?.transform;
            Transform second = binding.Find("Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button2_Runtime")?.transform;
            if (second != null) second.gameObject.SetActive(true);   // 复开时激活已克隆节点
            SetJingJieTabs(first, second);                            // 默认停在「境界」
            RefreshStandardCurrencyHeader(binding, "Layer/GoldCheck");
            foreach (Transform child in binding.transform.GetComponentsInChildren<Transform>(true))
                if (child.name == "Prompt") child.gameObject.SetActive(false);
        }

        // 设置两标签文案/高亮并绑定点击（默认 selectedFirst=true 表示停在境界）
        // 修正：Button2_Runtime 在 Jingjie 的 frame 实例上并非预设节点，须运行时克隆。
        private void SetJingJieTabs(Transform first, Transform second, bool selectedFirst = true)
        {
            if (first != null)
            {
                SetTabText(first, "境界", selectedFirst);
                oneLevelFrameView.BindClick("Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button1",
                    ShowJingJieSurface, true);
            }
            // Button2_Runtime 不是预设节点 → 从 Button1 克隆（对齐 HeroCultivation 两标签范式）
            if (first != null && second == null)
            {
                second = Instantiate(first.gameObject, first.parent, false).transform;
                second.name = "Button2_Runtime";
            }
            if (second != null)
            {
                RectTransform firstRect = first as RectTransform;
                RectTransform secondRect = second as RectTransform;
                if (firstRect != null && secondRect != null)
                    secondRect.anchoredPosition = firstRect.anchoredPosition + new Vector2(0f, -100f);
                SetTabText(second, "背包", !selectedFirst);
                second.gameObject.SetActive(true);
                Button secondButton = EnsureRuntimeButton(second);
                secondButton.onClick.RemoveAllListeners();
                secondButton.onClick.AddListener(ShowJingJieBag);
            }
            jingJieSurfaceMode = selectedFirst ? JingJieSurfaceMode.JingJie : JingJieSurfaceMode.Bag;
        }
```

> 注：`SetTabText` 是主 partial 的 `private static` 方法（`:16493`），同 partial 类内可直接调用。

### 2.3 新增切页方法

```csharp
        // 境界态：显示 Jingjie 内容，隐藏背包，标签高亮「境界」
        private void ShowJingJieSurface()
        {
            bagView?.SetVisible(false);
            jingJieView?.SetVisible(true);
            jingJiePreviewView?.SetVisible(false);
            jingJieRenderBridge?.Show();
            Text title = oneLevelFrameView?.Binding.Find("Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
            if (title != null) title.text = "主角";
            Transform first = oneLevelFrameView?.Binding.Find("Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button1")?.transform;
            Transform second = oneLevelFrameView?.Binding.Find("Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button2_Runtime")?.transform;
            SetJingJieTabs(first, second, true);
        }

        // 背包态：显示背包内容，隐藏 Jingjie，标签高亮「背包」
        private void ShowJingJieBag()
        {
            EnsureBagPresenter();                       // 复用主 partial 的背包加载（bagView/bagPresenter）
            jingJieView?.SetVisible(false);
            jingJiePreviewView?.SetVisible(false);
            if (bagView == null) return;
            bagView.SetVisible(true);
            bagView.GameObject.transform.SetAsLastSibling();
            oneLevelFrameView.GameObject.transform.SetAsLastSibling();
            SetOneLevelFrameVisible(true);
            bagPresenter?.Render();                    // 刷新背包格子
            Text title = oneLevelFrameView?.Binding.Find("Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
            if (title != null) title.text = "背包";
            Transform first = oneLevelFrameView?.Binding.Find("Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button1")?.transform;
            Transform second = oneLevelFrameView?.Binding.Find("Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button2_Runtime")?.transform;
            SetJingJieTabs(first, second, false);     // Button1=境界(可回), Button2=背包(当前)
        }
```

### 2.4 改写 `TryHandleJingJieBack()`（原 `:351-361`）

```csharp
        private bool TryHandleJingJieBack()
        {
            if (jingJieRenderBridge?.IsPreviewVisible == true)
            {
                jingJieRenderBridge.HidePreview();
                return true;
            }
            if (!IsJingJieOpen || services?.UiStack.Current != oneLevelFrameView) return false;
            if (jingJieSurfaceMode == JingJieSurfaceMode.Bag)
            {
                ShowJingJieSurface();   // 背包态先退回境界态，仍留在 frame 内
                return true;
            }
            jingJieRenderBridge.Hide();
            return PopUiStackWithHudRefresh();
        }
```

---

## 3. 为什么这样可行（要点）

1. **单槽位冲突已解**：`Btn_ListView/Panel_10` 同时被 Jingjie（占 `Button1`）和 Bag（占 `Button1`=「全部」）需要。`ShowJingJieBag` 通过 `BindClick(..., true)`（内部 `RemoveAllListeners`）覆盖 `BagPresenter` 当初绑的 `tabClickCount++`，把 `Button1` 重新接管为「境界」模块标签。背包分类当前只有「全部」一项（`BagPresenter.cs:51`），放弃其分类入口无功能损失。
2. **不改 prefab**：`Button2_Runtime` 不是 Jingjie 的 `OneLevelLayer` 实例的预设节点（装备/碎片等模块的预设帧才带它）。本方案在运行时从 `Button1` `Instantiate` 克隆并 `name="Button2_Runtime"`（对齐 `HeroCultivation` 两标签范式 `ProjectXApp.cs:15494`），零美术/布局改动、零 prefab 改动。
3. **布局复用已验证路径**：`ShowJingJieBag` 的「显示 `bagView` + `SetAsLastSibling` + `SetOneLevelFrameVisible(true)` + `Render()`」与既有 `ReopenBagForRecruitRouteValidation`(`ProjectXApp.cs:6450`) 的背包显隐方式一致，frame 提供外壳、`bagView` 作为内容体叠加，是已工作的布局。
4. **状态机闭合**：`jingJieSurfaceMode` 保证「背包→关闭键→回境界→再关→退回主界面」两段式回退，`bagView` 在 `ShowJingJieSurface` 中被显式隐藏，不会残留。

---

## 4. 校验（建议补充到 `RunJingJieValidation`）

新增控制点 `JINGJIE-08-BAG-TAB`：
1. Head 真实 raycast 进 Jingjie（沿用 `JINGJIE-07-HEAD-ENTRY`）；
2. 真实 raycast 点击 `Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button2_Runtime`；
3. 断言：`bagView.GameObject.activeInHierarchy == true` 且 `jingJieView.GameObject.activeInHierarchy == false`，且 `bagPresenter.Validate(out _)` 通过、`title.text == "背包"`；
4. 真实 raycast 点击 `Button1`（境界），断言回到 `jingJieView` 可见、`bagView` 隐藏、`title.text == "主角"`。

---

## 5. 风险与已知限制（交接必读）

| 项 | 说明 | 处置 |
|---|---|---|
| `IsBagOpen` 语义 | `:646` 定义为 `UiStack.Current==bagView`；本方案在 Jingjie 内切背包**不推 `bagView` 入栈**（留在 frame），故 `IsBagOpen` 仍为 false | 需搜索确认无其他模块在「Jingjie-背包」态下读取 `IsBagOpen` 做分支；当前未见依赖 |
| 背包内「使用」按钮 | `BagPresenter` 的 use/close 回调会 `SetOneLevelFrameVisible(false); HandleBack()`（见 `EnsureBagPresenter` `:13763` 的 closeAction），在子视图内点「使用」会关掉整页而非仅切回境界 | 属可接受边角（用道具即收起面板）；若需「使用后留在背包态」，需把 `closeAction` 换成 `ShowJingJieBag()`，列为后续优化 |
| 重入干净度 | 多次进出需保证显隐复位 | `ShowJingJieSurface` 开头 `bagView?.SetVisible(false)` 已兜底；`ShowJingJie` 的 `HideOtherOneLevelChildren` 也会在重新进入时清掉残留 `bagView` |
| 视觉对齐 | `bagView` 为 frame 兄弟节点叠加，需确认其内容与 frame 外壳（标签/标题/货币栏）不错位 | 真机/编辑器实玩核对；与独立打开背包（`btn_Bag`）布局对比应一致 |
| 背包未来多分类 | 若后续 Bag 加「装备/法宝/碎片」多分类，会再占 `Button2+`，与模块标签冲突 | 现阶段只做「全部」；多分类需另开独立内部切页条（方案 C），本期不做 |

---

## 6. 落地检查单（对接 AI 自测）

- [ ] `ConfigureJingJieFrame` 启用 `Button2_Runtime` 且默认选中「境界」
- [ ] 点头像进 Jingjie → 左侧出现「境界 / 背包」两标签，默认「境界」高亮
- [ ] 点「背包」→ 显示背包格子、标题变「背包」、Jingjie 内容隐藏
- [ ] 点「境界」→ 回到境界内容、标题恢复「主角」
- [ ] 背包态按关闭键 → 先回境界；再按关闭键 → 退回主界面；`bagView` 无残留
- [ ] `RunJingJieValidation` 现有 6/6 不回归 + 新增 `JINGJIE-08-BAG-TAB` 通过
- [ ] 控制台 0 error

---

## 7. 实机回归缺陷与修复（2026-09-17）

### 7.1 现象
用户测试：点头像 `Head` 进 `DynamicUi_JingjieLayer`，**左侧没有「背包」标签**。

### 7.2 根因
本手稿原误判 `Button2_Runtime` 为 frame 预设节点，故 `SetJingJieTabs` 只做
`Find("...Button2_Runtime")` + `SetActive(true)` + `BindClick`。但 Jingjie 的
`OneLevelLayer` 实例上**根本不存在**该节点 → `Find` 返回 null → 后续整段静默 no-op，
标签永不创建，自然看不到。

正确范式（`ProjectXApp.cs:15480-15506` 的 `HeroCultivation` 碎片切页）是：
**运行时从 `Button1` `Instantiate` 克隆 → `name="Button2_Runtime"` → 位置偏移 `-100f` →
`EnsureRuntimeButton` → 绑定点击**。装备/碎片、神将/碎片等模块的预设帧才自带该节点；
Jingjie 的帧不带，必须克隆。

### 7.3 修复（`ProjectXApp.JingJie.cs` `SetJingJieTabs`）
```csharp
if (first != null && second == null)
{
    second = Instantiate(first.gameObject, first.parent, false).transform;
    second.name = "Button2_Runtime";
}
if (second != null)
{
    RectTransform firstRect = first as RectTransform;
    RectTransform secondRect = second as RectTransform;
    if (firstRect != null && secondRect != null)
        secondRect.anchoredPosition = firstRect.anchoredPosition + new Vector2(0f, -100f);
    SetTabText(second, "背包", !selectedFirst);
    second.gameObject.SetActive(true);
    Button secondButton = EnsureRuntimeButton(second);
    secondButton.onClick.RemoveAllListeners();
    secondButton.onClick.AddListener(ShowJingJieBag);
}
```

### 7.4 防回归说明
- `second` 由 `Find` 取得；首次打开为 null → 克隆并命名 `Button2_Runtime`（作为 `Panel_10`
  子节点持久存在）；再次打开 `Find` 命中已克隆节点 → 不再重复克隆（不会生成多份）。
- `HideOtherOneLevelChildren` 只隐藏 `DynamicUi_` 前缀子节点，`Button2_Runtime` 不受影响。
- 克隆用 `first.parent`（`Panel_10`）作为父级，`worldPositionStays=false`，与 `HeroCultivation`
  范式一致；`anchoredPosition` 下移 `-100f` 与既有两标签布局对齐。

### 7.5 待用户重测
按 §6 检查单复测：进 Jingjie → 左侧出现「境界 / 背包」两标签 → 点背包切到背包 →
点境界切回 → 关闭键两段式回退。

---

## 8. 实机回归（第二轮，2026-09-17）：背包无数据 + 境界切不回

### 8.1 现象（用户复测）
点头像进 Jingjie → 左侧两标签出现 → 点「背包」切过去**背包没有数据** → 点「境界」**没反应**（切不回）。

### 8.2 根因
`ShowJingJieBag` 自创了显隐/层级逻辑，未走代码库既有的 `ConfigureBagFrame()` 范式：
1. **无数据**：原代码先 `bagView.SetAsLastSibling()` 再 `oneLevelFrameView...SetAsLastSibling()`
   → 帧被抬到背包**之上**，帧的不透明 `Bg` 把背包格子盖住了 → 看不到数据；且 `bagView` 当时仍是
   Canvas 兄弟节点、未 `AttachContent` 挂进帧，未针对帧做布局。
2. **境界切不回**：`bagView` 以 Canvas 兄弟节点形式浮在帧上，覆盖左侧 `Btn_ListView` 切页条
   → `Button1`（境界）被背包全屏层挡住，点击到不了它。

正确范式（`ProjectXApp.cs:15368 ConfigureBagFrame` + `:6450 ReopenBagForRecruitRouteValidation`）：
`frame.AttachContent(bagView)` 把背包**挂进帧内**（作为帧子节点，随帧 0,0 布局），再
`frame.SetAsLastSibling(); bagView.SetAsLastSibling();` —— 背包在帧之上、但背包背景是透明的，
所以帧的标题/标签/货币栏透过背包背景可见且可点（装备/碎片等模块即此机制）。

### 8.3 修复（`ProjectXApp.JingJie.cs` `ShowJingJieBag`）
对齐 `ConfigureBagFrame` 路径，仅保留两标签差异（不隐藏 `Button2_Runtime`、标签设为 境界/背包）：
```csharp
EnsureBagPresenter();
oneLevelFrameView.BindClick("Layer/Panel_12/Title/CloseBtn", () => TryHandleJingJieBack(), true); // 覆盖 BagPresenter ctor 写的 closeAction
OneLevelFrameCoordinator frame = EnsureOneLevelFrame();
frame.Apply(OneLevelFrameMode.Standard);
frame.AttachContent(bagView);                 // 关键：挂进帧内 + 随帧布局
jingJieView?.SetVisible(false);
jingJiePreviewView?.SetVisible(false);
if (bagView == null) return;
bagView.SetVisible(true);
bagPresenter?.Render();                       // 数据此刻才正确渲染进帧内
SetOneLevelFrameVisible(true);
oneLevelFrameView.GameObject.transform.SetAsLastSibling();
bagView.GameObject.transform.SetAsLastSibling();   // 帧→背包 层级，镜像正常背包
Text title = oneLevelFrameView?.Binding.Find("Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
if (title != null) title.text = "背包";
Transform first = oneLevelFrameView?.Binding.Find("Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button1")?.transform;
Transform second = oneLevelFrameView?.Binding.Find("Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button2_Runtime")?.transform;
SetJingJieTabs(first, second, false);
```
补充修复：
- `BagPresenter` 构造时把帧 `CloseBtn` 绑到自己的 `closeAction`（关整页）；`ShowJingJieBag` 在
  `EnsureBagPresenter()` 之后**重新绑定** `CloseBtn → TryHandleJingJieBack`，保证背包态按 X 先回境界。
- 不 `Push(bagView)` 入 `UiStack`（维持 `IsJingJieOpen` 判定与 `TryHandleJingJieBack` 的
  `UiStack.Current==oneLevelFrameView` 检查，否则两段式回退失效），与 §5 原设计一致。

### 8.4 待用户重测
复测 §6：背包应显示道具格子；点「境界」应切回境界内容、标题恢复「主角」；背包态按 X → 先回境界。

## 9. 实机回归（第三轮，2026-09-17）：定位并闭环「背包无数据 + 境界切不回」

第二轮修复方向正确但仍未闭环。第三轮用 Unity MCP 实时探针逐层定位，确认**四个独立根因**，
全部修复后实机端到端通过。

### 9.1 根因 1：帧根未做 RectTransform 归一化 → 背包挂在视口外（无数据）

`ConfigureBagFrame()` 在 `AttachContent` 之后有一段帧根归一化，`ShowJingJieBag` **缺失**：

```csharp
RectTransform root = binding.transform as RectTransform;
if (root != null) {
    root.pivot = new Vector2(0f, 1f);
    root.anchorMin = root.anchorMax = new Vector2(0f, 1f);
    root.anchoredPosition = Vector2.zero;
    root.localScale = Vector3.one;
}
```

缺失后果：帧根保留非零 `anchoredPosition`，被重新挂接的背包落到 `bagLocalPos=(0,-750)`（屏幕外），
`Bag/TableView` 未激活 → **即使 store 有 245 件道具也不渲染**。

修复后实测：`bagLocalPos=(0,0)`、`Bag/TableView=active`、`Colorful Table` world y=120。

### 9.2 根因 2：内嵌背包从未请求 `/8` → store 为空

普通入口 `btn_Bag` → `HandleBagClick()` → `InvokeLuaOrFail(onBagClicked)` → Lua 发 `/8`
（`ROLE_PACKAGE`）→ 服务端回包填充 store。内嵌路径只渲染**本地空 store**，从未触发请求。

修复：`EnsureJingJieBagDataRequested()` 复用同一 `onBagClicked` 触发 `/8`；

```csharp
private void EnsureJingJieBagDataRequested()
{
    if (jingJieBagDataRequested) return;
    jingJieBagDataRequested = true;
    InvokeLuaOrFail(onBagClicked, "JingJie.BagSnapshot");
}
```

并在 `ProjectXApp.cs:EndBagUpdate()` 加守卫，防止 `/8` 回包走 `ConfigureBagFrame()`
把共享帧改标题为「道具背包」并禁用境界标签（劫持 Jingjie 界面）：

```csharp
if (IsDrawOpen || IsHeroOpen || IsHeroEquipmentSurfaceVisible || heroEquipmentOpenPending) return;
if (IsJingJieBagSurfaceActive) return;   // ← Jingjie 内嵌背包自有 surface
EnsureBagPresenter();
```

**关键澄清**：Slot07（洪哥 Lv50）`itemCount=0` 属**存档本身无道具**（`role_info.package`
解压 1000 字节全零），非代码缺陷；Slot01（007 Lv100）解压 1912 字节有 1821 非零 → 作为验证夹具。

### 9.3 根因 3：`IsJingJieOpen` 语义错误 → 背包态被判定为「已关闭」

原定义仅测 `jingJieView` 可见性；背包态下 `jingJieView` 已隐藏 → 恒 `False`
→ `IsJingJieBagSurfaceActive` 失效 → 普通背包路径劫持共享帧。

```csharp
public bool IsJingJieOpen =>
    jingJieView?.GameObject.activeInHierarchy == true
    || (jingJieSurfaceMode == JingJieSurfaceMode.Bag
        && bagView?.GameObject.activeInHierarchy == true
        && oneLevelFrameView != null && services?.UiStack.Current == oneLevelFrameView);
```

### 9.4 根因 4：两个切页标签的 raycast 被内嵌背包内容拦截（点境界无效）

三层叠加，MCP 射线探针 `_tabdeep.cs` 直接给出证据：

| 现象 | 探针证据 |
|---|---|
| 标签行与 `Panel_12` 共享 canvas，深度 ~1502 **低于**背包行 `RuntimeHitArea`（~1514） | `hits=[bg1_2/d1502]` |
| 克隆标签的自有 Image 被 Cocos「未选中」态禁用；`EnsureRuntimeButton` 合成的同名 `RuntimeHitArea` 被**误绑到背包行** | `interactable=False` |
| 选中态 `Button1` 同样未把自有 Graphic 设为 raycast target | `hits=[bg1_2/d1502/sib0]`（不是自己） |

对应修复（`SetJingJieTabs` + 两个新辅助方法）：

```csharp
// ① 标签行独立 override-sorting canvas，永远高于内嵌内容
private void EnsureTabSortingCanvas(Transform first)
{
    Transform panel = first?.parent; if (panel == null) return;
    Canvas canvas = panel.GetComponent<Canvas>() ?? panel.gameObject.AddComponent<Canvas>();
    canvas.overrideSorting = true;
    canvas.sortingOrder = 32000;
    if (panel.GetComponent<GraphicRaycaster>() == null)
        panel.gameObject.AddComponent<GraphicRaycaster>();
}

// ② 恢复标签自有 Graphic（含 ChooseBg），并显式把 targetGraphic 指回自身
private static void EnableOwnTabGraphic(Transform tab)
{
    if (tab == null) return;
    Graphic own = tab.GetComponent<Graphic>(); if (own != null) own.enabled = true;
    Transform chosen = tab.Find("ChooseBg"); if (chosen != null) chosen.gameObject.SetActive(true);
}
```

`SetJingJieTabs` 中对 **Button1 与 Button2_Runtime 对称处理**（各 `EnableOwnTabGraphic` +
`EnsureRuntimeButton` + `targetGraphic = ownGraphic` + `interactable = true`），末尾调用
`EnsureTabSortingCanvas(first)`。

### 9.5 验收结果（Slot01，真实 EventSystem raycast 输入，MCP 实测）

| 验证项 | 结果 |
|---|---|
| 点头像打开境界 | `headClick=True` → `jjOpen=True` |
| 两个标签存在 | `tab1=True t1text='境界'`；`tab2=True t2text='背包'` |
| 点背包切换 | `bagTabClick=True` |
| 背包数据渲染 | `rows=49 activeRows=49`，道具名可见（刷新令/体力丹/寻宝令/转盘钥匙/竞技场挑战令 ×999） |
| 背包位置 | `bagLocalPos=(0,0)`，`Bag/TableView` active |
| 标签射线命中 | `Button1 hits=[Button1/d0]`；`Button2_Runtime hits=[Button2_Runtime/d4]`（均在 `Panel_10 ovr=True ord=32000`） |
| **点境界切回** | `beforeBagSurface=True click=True` → `jingJieVisible=True bagVisible=False bagSurface=False title='主角'` |
| 二次进入背包（幂等） | `rows=49 activeRows=49` 正常 |
| 运行期错误 | console **0 error / 0 warning** |

### 9.6 已清理

- 移除临时诊断 `LogJingJieBagDiagnostics()`（原 `[JingJieBag]` 日志）及其调用点。
- 生产代码保留：`IsJingJieOpen` 新语义、`EnableOwnTabGraphic`、`EnsureTabSortingCanvas`、
  帧根归一化块、`EnsureJingJieBagDataRequested`、`EndBagUpdate` 守卫。

## 10. 实机回归（第四轮，2026-09-17）：上一轮引入的两个回归 + 修复

用户复测反馈两点：
> 「直接打开背包界面关不掉」
> 「从头像打开背包、境界和背包里面背包没有数据」

均为**第三轮修复自身引入的回归**，非原有缺陷。

### 10.1 回归 A：普通背包「关不掉」（我加的 sorting canvas 制造）

第三轮为解决标签遮挡，`EnsureTabSortingCanvas` 直接给 `Panel_10` 加了 `Canvas`：

```csharp
// ❌ 错误做法
Canvas canvas = panel.GetComponent<Canvas>() ?? panel.gameObject.AddComponent<Canvas>();
canvas.overrideSorting = true;
canvas.sortingOrder = 32000;
```

`Panel_10` 嵌套在帧内 → 该 Canvas 是**非根 Canvas**（`isRootCanvas=False`）。Unity 对非根
`overrideSorting` canvas 会按 screen-space-overlay 重新排序，把整个标签子树**提升到全 UI 最上层**，
且**不随页面关闭而消失** → 帧上残留可见/可射线的标签，页面永远关不掉。

**修复**：彻底放弃 canvas 方案，改用**纯兄弟顺序**。新增 `RaiseJingJieTabs(bool raise)`：

```csharp
private void RaiseJingJieTabs(bool raise)
{
    if (oneLevelFrameView == null) return;
    CocosUiBinding frameBinding = oneLevelFrameView.Binding;
    if (frameBinding == null) return;
    Transform frameRoot = frameBinding.transform;
    Transform panel12  = frameBinding.Find("Layer/Panel_12")?.transform;
    Transform goldCheck = frameBinding.Find("Layer/GoldCheck")?.transform;
    Transform layerBg   = frameBinding.Find("Layer/Bg")?.transform;
    if (raise)   // 背包态：Bg < bag < GoldCheck < Panel_12(最后 = 标题/标签/关闭)
    {
        if (layerBg != null) layerBg.SetSiblingIndex(0);
        if (goldCheck != null) goldCheck.SetAsLastSibling();
        if (panel12 != null) panel12.SetAsLastSibling();
    }
    else         // 境界态：还原 Bg < Panel_12 < GoldCheck
    {
        if (layerBg != null) layerBg.SetSiblingIndex(0);
        if (panel12 != null) panel12.SetSiblingIndex(Mathf.Min(1, frameRoot.childCount - 1));
        if (goldCheck != null) goldCheck.SetSiblingIndex(Mathf.Min(2, frameRoot.childCount - 1));
    }
}
```

`SetJingJieTabs` 末尾由 `EnsureTabSortingCanvas(first)` 改为 `RaiseJingJieTabs(!selectedFirst)`；
原 `RestoreJingJieFrameOrder()` 收敛为 `RaiseJingJieTabs(false)`；`EnsureTabSortingCanvas` 已删除。
背包行的 `RuntimeHitArea` 是全宽 Image 且兄弟序靠后，靠兄弟序即可稳定压过它。

### 10.2 回归 B：`ShowJingJieBag` 提前 return 留下「孤儿帧」

原代码先建帧、隐藏境界视图，**再**检查 `bagView == null` 并 `return`：

```csharp
// ❌ 顺序错误
EnsureBagPresenter();
frame.Apply(...); jingJieView?.SetVisible(false); jingJiePreviewView?.SetVisible(false);
if (bagView == null) return;   // ← 帧已开，没人关得掉
```

**修复**：把空值检查提到最前，`bagView` 不可用时**完全不碰帧**：

```csharp
EnsureBagPresenter();
if (bagView == null) return;   // 先判空，不产生孤儿帧
```

### 10.3 回归 C：A 与 B 叠加导致「关不掉」

即使帧成了孤儿，`CloseBtn` 仍绑定 `TryHandleJingJieBack`，而该方法有一道门槛：

```csharp
if (!IsJingJieOpen || services?.UiStack.Current != oneLevelFrameView) return false;   // ❌ 直接拒绝
```

普通背包态下 `IsJingJieOpen=False` → 返回 `false` → **X 按钮彻底失效**。而
`ShowJingJieBag` 已把 `BagPresenter` 原本的 `closeAction` 替换成了这个方法，两条关闭路径全断。

**修复**：帧在显示但未被 Jingjie 页面接管时，回退到普通背包关闭流程：

```csharp
bool frameVisible = oneLevelFrameView != null && oneLevelFrameView.GameObject.activeInHierarchy;
if (!IsJingJieOpen || services?.UiStack.Current != oneLevelFrameView)
{
    if (!frameVisible || bagView == null) return false;
    bagFlowPresenter?.CloseAll();
    SetOneLevelFrameVisible(false);
    HandleBack();          // 与 BagPresenter 自身 closeAction 同款收尾
    return true;
}
```

### 10.4 回归 D：内嵌背包「没数据」——`EndBagUpdate` 提前 return 不重绘

第三轮为防 `/8` 回包劫持共享帧，在 `EndBagUpdate` 加了 guard，但**只 return 不重绘**：

```csharp
services.Bag.Replace(pendingBagItems);      // 数据已写入 store
...
if (IsJingJieBagSurfaceActive) return;      // ❌ 直接返回，界面永不再画
```

时序：点「背包」标签 → `ShowJingJieBag()` 立即 `Render()`（此时 store 仍空）→ 之后 `/8` 回包
写入 store → 但被 guard 拦下且不重绘 → **界面永远是空**。

**修复**：guard 内补一次 `Render()`：

```csharp
if (IsJingJieBagSurfaceActive)
{
    EnsureBagPresenter();
    bagPresenter?.Render();     // 数据到位后重绘内嵌背包
    return;
}
```

### 10.5 第四轮验收（Slot01，真实 EventSystem raycast，MCP 实测）

| 场景 | 结果 |
|---|---|
| 普通背包 开→关 | `bagClick=True` → 49 行/245 件 → `closeClick=True` → `frame=False bagGO=False` |
| 头像→境界 | `headClick=True` → `jjOpen=True`，`JingjieLayer,act=True`，无孤儿背包 |
| 境界→背包 标签 | `bagTabClick=True` → `bagSurface=True`，兄弟序 `Bg<beibao<GoldCheck<Panel_12` |
| 内嵌背包数据 | **`rows=49 active=49 itemCount=245`**（刷新令/体力丹/寻宝令/天命石/修炼丹/图鉴升级卷轴…） |
| 背包→境界 标签 | `jjTabClick=True` → `bagSurface=False`，兄弟序还原 |
| 背包态 X | `closeClick=True` → **回到境界**（两段式，未关整页） |
| 境界态 X | `closeClick=True` → `frame=False bagGO=False jjGO=False`，主界面恢复可交互 |
| 完整回归 2 轮 | 全部通过 |
| console | **0 error / 0 warning** |

### 10.6 结论

第三轮「标签点击」问题的 canvas 方案是**错的**（非根 override canvas 会永久提升层级）；
已改为纯兄弟顺序，无任何会脱离帧生命周期的副作用。第四轮另修 3 处（孤儿帧、关闭门槛、回包不重绘）。
三轮累积教训：**共享外壳（OneLevelFrame）上，任何"提层"手段都必须与帧同生命周期**，
优先用 sibling index，避免 `Canvas` / `overrideSorting` / `SetAsLastSibling` 作用于帧根自身。

## 11. 实机回归（第五轮，2026-09-17）：内嵌背包「没数据」的真正根因 = 背包自身锚点未归一化

用户复测：`头像→境界→背包看数据 → 没有数据`（Play 停在背包页）。

### 11.1 探针证据（决定性）

MCP 实时探针显示 **数据、渲染、层级全都正常**，唯独位置不对：

```
jjOpen=True bagSurface=True; frame=True
children={0:Bg,act=True}{1:DynamicUi_beibao,act=True}{2:DynamicUi_JingjieLayer,act=False}
         {3:DynamicUi_Jingjieyulan,act=False}{4:GoldCheck,act=True}{5:Panel_12,act=True}
content=True act=True rows=49 active=49        ← 49 行全部渲染
table=True size=(585.00, 523.00) world=552,120 ← 表格在视口内
itemCount=245                                  ← 数据在
bagAct=True localPos=(0.00, -750.00)           ← ❌ 背包整体在帧下方 750
```

### 11.2 根因：子锚点与父 pivot 不一致

```
frameRect: pivot=(0,1) anchorMin=anchorMax=(0,1) anchoredPos=(0,0)  ← 帧根已归一化（上一轮的修复）
bagRect  : pivot=(0,0) anchorMin=anchorMax=(0,0) anchoredPos=(0,0)  ← ❌ 背包轴心/锚点仍在左下
           → localPos=(0,-750)
```

`AttachContent` 用的是 `SetParent(frame, false)`（`CocosUiView.cs:35`）——**`false` 只表示不保持世界坐标，
并不会重置子节点的 anchor**。于是背包带着导入态的 `(0,0)` 锚点进入了一个 `pivot=(0,1)` 的父级：

子锚点 `(0,0)` 对应父级的**左下角**，而父级 pivot 在**左上角**；此时 `anchoredPosition=(0,0)`
解析出的 `localPosition` 就是 `(0, -frameHeight)` = `(0,-750)` —— 整整一屏高度之下。

第四轮我只归一化了**帧根**（`rootRect`），漏了**背包自身**（`bagRect`）。普通背包入口之所以一直正常，
是因为那条路径下 `bagView` 早已被预设成正确锚点；只有"先开境界再切背包"这条新路径会带着导入态锚点进来。

### 11.3 修复（`ProjectXApp.JingJie.cs` `ShowJingJieBag`）

在帧根归一化之后补上背包自身的归一化，使两者锚点一致：

```csharp
// The BAG's own anchors must be normalised too. Imported prefabs can
// arrive with pivot/anchorMin/anchorMax = (0,0) (bottom-left), and when
// a child's anchor does not match its parent's pivot, anchoredPosition
// (0,0) resolves to localPosition (0,-750) — i.e. one full frame height
// BELOW the frame, off-screen.
RectTransform bagRect = bagView.GameObject.transform as RectTransform;
if (bagRect != null)
{
    bagRect.pivot = new Vector2(0f, 1f);
    bagRect.anchorMin = bagRect.anchorMax = new Vector2(0f, 1f);
    bagRect.anchoredPosition = Vector2.zero;
    bagRect.localScale = Vector3.one;
}
```

### 11.4 第五轮验收（Slot01，真实 EventSystem raycast，MCP 实测）

> ⚠️ **本节结论已被 §12 推翻，勿再引用。** 表中"头像→境界→背包 → 道具可见"那一行是**误判**：
> 我当时实际看的是普通背包入口（`btn_Bag`）的画面，不是境界内切页路径。该路径下内容区仍然是空白的，
> 真因见 §12（`Panel_12` 的羊皮纸底盖住了背包）。§11 的锚点归一化修复本身必要且保留。

| 路径 | localPos | rows | itemCount | 结果 |
|---|---|---|---|---|
| 头像→境界→背包 | `(0,0)` | 49/49 | 245 | ~~✅ 道具可见~~ → ❌ **实为空白，见 §12** |
| 背包态 X | — | — | — | ✅ 回境界（两段式） |
| 境界态 X | — | — | — | ✅ `frame=False` 关整页 |
| 普通背包入口 | `(0,0)` | 49/49 | 245 | ✅ 未受影响（此路径下背包在上层，正常） |
| console | — | — | — | **0 error / 0 warning** |

### 11.5 教训（已同步 MEMORY.md）

`AttachContent`（`SetParent(parent, false)`）**不重置子节点 anchor**。把任意 Prefab 挂到共享帧下时，
必须**同时**归一化「帧根」与「被挂入的内容」两者的 `pivot / anchorMin / anchorMax / anchoredPosition`，
否则锚点与父 pivot 不一致会让 `anchoredPosition=(0,0)` 解析到屏幕外，表现为"布局对了但什么都看不见"，
极易误判成"没有数据"。**排查此类问题先打印 `localPosition` 与 `pivot/anchor`，不要只看 activeInHierarchy。**

---

## 12. 实机回归（第六轮，2026-09-17）：真正的空白根因 = 共享帧羊皮纸底盖住了背包

### 12.1 我的错误结论（必须先自我更正）

§11 的验收表**不成立**。用户指出：那一轮我验证的"道具可见"是**普通背包入口（`btn_Bag`）**的画面，
不是**「头像→境界→背包」**这条路径。用户随后贴出截图（20:53）：境界外壳（标题「背包」、右侧「境界/背包」
两标签、顶部货币栏）全部正常，**内容区是一整块空白的米白色**。

也就是说：§11 修的 `localPos=(0,-750)` 屏外问题是**真实且必要的**（不修连框都跑出去），但它**不是**
"看不见道具"的最后一环。修好之后背包确实回到了屏幕内、`rows=49 active=49 itemCount=245`，
可**画面依旧空白**——探针与视觉长期矛盾，我一度卡在这里。

### 12.2 真因：`Panel_12` 排在最后，它的不透明羊皮纸把背包整个盖住了

把帧根 `DynamicUi_OneLevelLayer` 的子节点顺序 + 各自世界矩形打印出来，一切立刻清晰：

| 帧根子节点 | sibling | 世界矩形（1334×750 参考系） | 作用 |
|---|---|---|---|
| `Bg` | — | 全屏 | 帧背板 |
| `DynamicUi_beibao` | 1→5 | 根全屏，**实际绘制的只有** `beibao_layer/Bag/Image` X[545,1145] Y[90,668] 与 `Bag/TableView` X[552,1137] Y[120,643] | 背包内容 |
| `GoldCheck` | — | 顶部条 | 货币栏 |
| `Panel_12` | **最末** | 全屏 | 帧皮肤（标题/标签/关闭） |
| └ `Bg/bg1_0` | | X[108,1226] Y[66,684] | `ui_common_bg` 外框 |
| └ `Bg/bg1_2` | | **X[122,1148] Y[81,669]** | **`ui_common_yangpizhi_bg` 羊皮纸（不透明）** |
| └ `Bg/bg1_4` | | X[1145,1224] Y[85,644] | `ui_common_diwen_youyeqian` 右叶 |
| └ `Bg/Btn_ListView/Panel_10/Button1` | | X[1146,1224] Y[566,666] | 「境界」标签 |
| └ `Bg/Btn_ListView/Panel_10/Button2_Runtime` | | X[1146,1224] Y[466,566] | 「背包」标签 |
| └ `Title/TitleName` | | Y[697,750] | 标题 |

`Panel_12` 是**最后一个子节点 → 画在最上层**。它内部的 `bg1_2` 羊皮纸 `1026×588` 正好覆盖背包表格所在的
整片区域（`TableView` X[552,1137] Y[120,643] 完全落在 `bg1_2` X[122,1148] Y[81,669] 之内）。

**验证：** 对用户截图做像素边界提取（`PIL`，在 1031×582 图上扫描米白色区域 `r>235,g>225,b>205`），
得到内容框 `gameX ∈ [151,1122]`、`worldY ∈ [116,639]`（宽 971 × 高 523）。
`bg1_2` 是 X[122,1148] Y[81,669]，扣掉四周描边后的内区恰好 ≈ X[151,1122] Y[116,639] —— **完全吻合**。
反过来，全场景扫描"宽 850~1100、高 450~620"的矩形，**唯一命中**的就是
`Canvas/DynamicUi_OneLevelLayer/Panel_12/Bg/bg1_2`。截图里那块米白框就是它，与背包无关。

### 12.3 我自己上一轮引入的反向修复

§10 里我为了修"标签点不动"，写了 `RaiseJingJieTabs(true)` 把 `Panel_12` **提到最后一个**：

```csharp
// ❌ 错：把 Panel_12 提到最后 = 提到最上 = 羊皮纸盖住背包
if (panel12 != null) panel12.SetAsLastSibling();
```

方向**完全反了**。标签点不动的真实原因是背包行的 `RuntimeHitArea`（整行宽）在射线里赢过标签，
正确的解法是让背包**排到最后**（这样标签仍在 `Bag/Image` 之外，不被遮也不被挡），而不是把皮肤提到最上。

### 12.4 修复：对齐普通背包入口的既有做法

普通背包入口（`ProjectXApp.cs:5901-5902`）一直是这么写的，照着抄即可：

```csharp
oneLevelFrameView.GameObject.transform.SetAsLastSibling();
bagView.GameObject.transform.SetAsLastSibling();
```

`ProjectXApp.JingJie.cs` 的 `RaiseJingJieTabs` 改为：

```csharp
private void RaiseJingJieTabs(bool raise)
{
    if (oneLevelFrameView == null) return;
    CocosUiBinding frameBinding = oneLevelFrameView.Binding;
    if (frameBinding == null) return;
    Transform frameRoot = frameBinding.transform;
    Transform panel12    = frameBinding.Find("Layer/Panel_12")?.transform;
    Transform goldCheck  = frameBinding.Find("Layer/GoldCheck")?.transform;
    Transform layerBg    = frameBinding.Find("Layer/Bg")?.transform;
    Transform bagRoot    = bagView?.GameObject != null ? bagView.GameObject.transform : null;
    // 除背包外全部还原导入顺序：Bg(0) < Panel_12(1) < GoldCheck(2) < bag(last)
    if (layerBg   != null) layerBg.SetSiblingIndex(0);
    if (panel12   != null) panel12.SetSiblingIndex(Mathf.Min(1, frameRoot.childCount - 1));
    if (goldCheck != null) goldCheck.SetSiblingIndex(Mathf.Min(2, frameRoot.childCount - 1));
    if (raise)
    {
        // 背包态：背包排最后 —— 与普通背包入口 SetAsLastSibling() 一致
        if (bagRoot != null) bagRoot.SetAsLastSibling();
    }
    else
    {
        // 境界态：背包已隐藏，压在皮肤之下即可
        if (bagRoot != null) bagRoot.SetSiblingIndex(Mathf.Min(3, frameRoot.childCount - 1));
    }
}
```

同时删除 `ShowJingJieBag` 里那段手工排序（原 `layerBg.SetSiblingIndex(0)` +
`bagView.SetSiblingIndex(1)`），排序统一由 `SetJingJieTabs` → `RaiseJingJieTabs` 收口，避免两处口径打架。

**为什么这样不会再把标签盖住**：背包只绘制 `Bag/Image` X[545,1145] Y[90,668] 与 `TableView`
X[552,1137] Y[120,643]，而标签列在 **X[1146,1224]**、标题在 **Y[697,750]** —— 都在背包绘制区之外，
天然不重叠，不需要任何 Canvas / 排序覆盖。

### 12.5 第六轮验收（Slot01，MCP 实测）

帧根子节点顺序（背包态）：
```
[0] Bg                act=True
[1] Panel_12          act=True
[2] GoldCheck         act=True
[3] DynamicUi_JingjieLayer  act=False
[4] DynamicUi_Jingjieyulan  act=False
[5] DynamicUi_beibao        act=True      ← 最上
```
帧根子节点顺序（境界态）：`Bg(0) < Panel_12(1) < GoldCheck(2) < JingjieLayer(3,ON) < beibao(4,off)` ✅

`GraphicRaycaster` 真实判定：

| 探针（屏幕坐标） | `hits[0]` | depth | 结论 |
|---|---|---|---|
| 表格中心 (863,381) | `RuntimeHitArea` | 98 | ✅ 背包行在最上 |
| 行 0 (840,572) | `RuntimeHitArea` | 68 | ✅ |
| 「境界」标签 (1185,616) | `Button1` | 13 | ✅ 可点 |
| 「背包」标签 (1185,516) | `Button2_Runtime` | 17 | ✅ 可点 |

`InvokeEventSystemRaycastClick(Button1)` 返回 **True**（未被遮挡，真实派发成功），点击后正确切回境界态
（`beibao.act=False`、`JingjieLayer.act=True`）。

渲染数据：`rows=49 rowsWithVisibleGraphic=49`、`tvTop=643`、`row0 y[501,643]` / `row1 y[359,501]` /
`row2 y[217,359]`（均在首屏内）；`Bag/Image` `worldSize=600×578`、`worldBL=(545,90)`；
`TableView` `worldSize=585×523`、`worldBL=(552,120)`。console **0 error**。

### 12.6 教训（追加）

1. **共享帧的"皮肤层"（`Panel_12`）里可能带不透明底图**（本例 `ui_common_yangpizhi_bg`）。
   它一旦排在内容层之后就会整片盖住内容，且在 `activeInHierarchy` / 尺寸 / alpha / cull 探针里
   **全部正常**——只有把帧根子节点顺序和各自**世界矩形**一起打出来才能发现。
2. **用户截图的像素边界是可靠的锚**。当探针说"一切正常"而用户说"空白"时，把截图做像素级边界提取，
   再去全场景反查"哪个 RT 的世界矩形等于这个边界"，一次命中（本例 `bg1_2`）。这条比继续加探针快得多。
3. **不要用普通入口代替新路径做验收**。同一个 `bagView` 在两条路径下的 sibling 顺序不同，
   表现可以完全相反（普通入口：背包在上正常；境界切页：皮肤在上空白）。
   验收必须走用户实际操作的入口。
4. **`ScreenCapture.CaptureScreenshot` 在本机不可用**（GameView 非 focus 时反复写出同一张缓存图），
   画面结论以用户截图为准，不要用它自证。

### 12.7 已删除的错误方案（勿再尝试）

- `EnsureTabSortingCanvas`：给 `Panel_10` 加 Canvas → 嵌套非根 Canvas 被 Unity 按 overlay 重排，
  标签子树永久提到全 UI 最上层且不随页面销毁 → 页面关不掉。
- 把 `Panel_12` 提到最后（本轮删除）：羊皮纸盖住背包 → 内容区空白。

---

## 13. 实机回归（第七轮，2026-09-17）：标签选中/未选中态缺失

### 13.1 现象

用户截图：右侧两个标签「境界」「背包」**同时都亮着**（都显示选中底图），
且「首次打开境界界面，类别显示更是有问题」。

### 13.2 权威参照：装备/碎片的切页实现

`ProjectXApp.cs:15297 SelectHeroEquipmentTab` —— **只调 `SetTabText`，别的一概不碰**：

```csharp
private void SelectHeroEquipmentTab(Transform tabs, bool firstSelected)
{
    Transform panel = tabs?.Find("Panel_10");
    Transform first = panel?.Find("Button1");
    Transform second = panel?.Find("Button2_Runtime");
    if (first != null) SetTabText(first, "装备", firstSelected);
    if (second != null) SetTabText(second, "碎片", !firstSelected);
}
```

`SetTabText`（`ProjectXApp.cs:16509`）是选中态的**唯一权威**：

```csharp
Text normal = tab.Find("BtnName")?.GetComponent<Text>();
Text chosen = tab.Find("ChooseBg/BtnName")?.GetComponent<Text>();
if (normal != null) normal.text = value;
if (chosen != null) chosen.text = value;
Transform choose = tab.Find("ChooseBg");
if (choose != null) choose.gameObject.SetActive(selected);             // ← 选中底图开关
Image background = tab.GetComponent<Image>();
if (background != null && !selected) background.color = new Color(1f, 1f, 1f, 0f);  // ← 未选中：本底 alpha 0
Button button = tab.GetComponent<Button>();
if (button != null) button.interactable = !selected;
```

### 13.3 我们的三个偏差（全部是 `SetJingJieTabs` 自己引入的）

| # | 位置 | 偏差 | 后果 |
|---|---|---|---|
| 1 | `EnableOwnTabGraphic(tab)` | 无条件 `own.enabled = true` + **`ChooseBg.SetActive(true)`** | 未选中标签也显示选中底图 → **两个都亮** |
| 2 | 同上 | 从不应用 `!selected` 时的 `background.color = alpha 0` | 未选中标签 `alpha` 实测 = **1.00**（应 0） |
| 3 | `EnsureRuntimeButton` + `interactable = true` | 覆盖 `SetTabText` 的 `interactable = !selected` | 选中标签被重新启用 |

实测（修复前，背包态）：
```
Button1(境界,未选中)  alpha=1.000 ❌  interactable=True ❌  ChooseBg=True ❌
Button2(背包,已选中)  alpha=0.010 ✓  interactable=True ✓  ChooseBg=True ✓
```

根源是：**为了让标签能穿透背包行的 `RuntimeHitArea` 射线而做的一堆加固，把 `SetTabText` 的视觉状态全推翻了。**
（`EnsureRuntimeButton` 还有同名冲突：它在标签下找名为 `RuntimeHitArea` 的子节点，而背包行也创建同名节点，
导致标签的 `targetGraphic` 指到了背包行的 hit area → 那时才 "点不动"。）

### 13.4 修复

删除 `EnableOwnTabGraphic`，`SetJingJieTabs` 收敛为**只调 `SetTabText` 管视觉 + `EnsureTabClick` 管点击**：

```csharp
private static Button EnsureTabClick(Transform tab)
{
    Graphic own = tab.GetComponent<Graphic>();
    if (own != null) own.raycastTarget = true;
    Button button = tab.GetComponent<Button>();
    if (button == null) button = tab.gameObject.AddComponent<Button>();
    // 透明点击载体：alpha 0 + raycastTarget=true（不会被 CanvasRenderer cull）
    Transform carrier = tab.Find("RuntimeClickArea");
    Image carrierImage;
    if (carrier == null)
    {
        var go = new GameObject("RuntimeClickArea", typeof(RectTransform), typeof(Image));
        carrier = go.transform;
        carrier.SetParent(tab, false);
        carrierImage = go.GetComponent<Image>();
        RectTransform r = carrier as RectTransform;
        r.anchorMin = Vector2.zero; r.anchorMax = Vector2.one;
        r.offsetMin = Vector2.zero;  r.offsetMax = Vector2.zero;
    }
    else
    {
        carrierImage = carrier.GetComponent<Image>();
        if (carrierImage == null) carrierImage = carrier.gameObject.AddComponent<Image>();
    }
    carrierImage.color = new Color(0f, 0f, 0f, 0f);
    carrierImage.raycastTarget = true;
    carrier.SetAsLastSibling();
    // ⚠️ 关键：关掉 ColorTint 并把 targetGraphic 指向透明载体
    button.transition = Selectable.Transition.None;
    button.targetGraphic = carrierImage;
    return button;
}
```

**为什么必须关 `transition`（本轮新踩的坑）**：Cocos 导出的标签是 `transition = ColorTint` 且
`targetGraphic = 标签自身 Image`。这种配置下 `Selectable` 会在每次状态变化时用 `normalColor`（alpha **1**）
驱动标签 Image 的颜色，**把 `SetTabText` 刚设的 alpha 0 覆盖回去** → 未选中标签又变不透明。
把 `targetGraphic` 改指透明载体后，即使有 tint 也乘在 alpha 0 上 → 无视觉影响；
再顺手 `transition = None` 双保险，让标签的选中/未选中美术**完全由 `SetTabText` 独占**。

### 13.5 第七轮验收（Slot01，MCP 实测）

首次打开境界（`selectedFirst = true`）：
```
Button1(境界)  alpha=1.00  interactable=False  ChooseBg=True   target=RuntimeClickArea  ✅ 选中
Button2(背包)  alpha=0.00  interactable=True   ChooseBg=False  target=RuntimeClickArea  ✅ 未选中
```

点「背包」后：
```
Button1(境界)  alpha=0.00  interactable=True   ChooseBg=False  ✅ 未选中、可点
Button2(背包)  alpha=0.00  interactable=False  ChooseBg=True   ✅ 选中
```

再点「境界」切回：
```
Button1(境界)  alpha=0.00  interactable=False  ChooseBg=True   ✅ 选中
Button2(背包)  alpha=0.00  interactable=True   ChooseBg=False  ✅ 未选中
```

`GraphicRaycaster`：`tab1 → RuntimeClickArea depth=17`、`tab2 → RuntimeClickArea depth=20`
（均为 `hits[0]`）；背包态下 `tvc → RuntimeHitArea depth=98`（背包行在最上）。
`InvokeEventSystemRaycastClick` 两个标签往返均返回 `True`。console **0 error / 0 warning**。

### 13.6 教训（追加）

1. **共享帧里已有权威实现时，照抄它，不要自创。** 装备/碎片切页（`SelectHeroEquipmentTab`）
   只有两行 `SetTabText`；我为了修射线问题加了三层加固（`EnableOwnTabGraphic` /
   `EnsureRuntimeButton` / 手改 `raycastTarget`），把视觉状态全推翻了。
2. **`SetTabText` 的语义边界**：它只管 `BtnName` 文本、`ChooseBg` 显隐、自身 Image 的 alpha、`interactable`。
   任何在此之后的 `enabled = true` / `SetActive(true)` / `interactable = true` 都会**静默**破坏选中态。
3. **`Selectable.transition = ColorTint` 会覆盖手动设的 `targetGraphic` 颜色。**
   需要"手动控制 Graphic 的 alpha"时，必须同时 `transition = None` 或把 `targetGraphic` 移出那个 Graphic。
4. **点击问题的正解是"加一个透明射线载体"，不是"打开视觉图层"。**
   载体 alpha 0 + `raycastTarget=true` + `cull=false` 即可命中，且完全不影响美术。
