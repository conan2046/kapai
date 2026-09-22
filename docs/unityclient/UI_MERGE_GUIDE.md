# Unity UI 合并与共享页面切换规范

## 适用范围

适用于将多个旧入口、旧页面或旧功能合并到同一个 Unity UI 容器、共享页签和共享背景中的改造。

本次参考案例：

- 神将阵容
- 神将列表
- 神将碎片
- 境界
- 背包
- 神将养成、换将、回收、图鉴

核心结论：UI 合并不是简单调整父节点或复制按钮，而是要同时处理页面状态、共享节点、动态节点、层级、数据刷新、返回逻辑和旧代码引用。

## 一、合并前必须盘点

### 1. 节点资源

- 原始 Prefab 节点
- 动态加载节点
- 运行时复制节点
- 旧页签节点
- 旧背景和遮罩节点
- 关闭按钮、返回按钮、金币栏等共享节点

### 2. 代码引用

必须搜索以下内容：

- Prefab 路径常量
- `Binding.Find(...)`
- `transform.Find(...)`
- `SetActive(...)`
- `BindClick(...)`
- `BindClickNode(...)`
- 红点路径
- Presenter 初始化和销毁逻辑
- UI Stack Push/Pop
- 返回键处理
- 验证代码和自动化入口

### 3. 数据来源

确认每个页面的数据链：

```text
入口按钮
→ Lua 请求
→ 协议/本地数据
→ Store 状态
→ Presenter Render
→ 玩家可见 UI
```

不能只确认页面能打开，还要确认数据请求和渲染使用的是当前页面的数据源。

## 二、统一页面状态模型

共享 UI 必须明确当前页面所有者和当前页签，不能让多个 Presenter 同时控制同一组节点。

建议使用明确的状态枚举：

```csharp
private enum MergedTab
{
    Formation,
    Heroes,
    Fragments
}
```

同时维护：

```text
CurrentOwner：当前共享窗口由哪个功能占用
CurrentTab：当前选中的页签
CurrentContent：当前显示的内容节点
CurrentCloseAction：关闭按钮当前应执行的逻辑
```

本次神将合并使用了：

```text
HeroHubTab.Formation
HeroHubTab.Heroes
HeroHubTab.Fragments
```

所有切页统一通过一个入口处理：

```csharp
ShowHeroHubTab(tab);
```

不要让阵容、神将、碎片三个页面分别修改共享页签和共享背景。

## 三、切页标准流程

每次切换页签必须按以下顺序执行：

```text
1. 关闭旧内容
2. 关闭旧动态节点
3. 清理旧按钮监听
4. 恢复共享背景和遮罩状态
5. 设置目标页面所有者
6. 设置目标页签文本和选中状态
7. 绑定目标页签点击事件
8. 设置节点层级
9. 显示目标内容
10. 请求或读取权威数据
11. Render 当前页面
12. 重新绑定关闭/返回行为
```

对应的清理方法应集中管理，例如：

```csharp
HideHeroHubContent();
```

至少要处理：

- 阵容列表
- 阵容详情
- 神将列表
- 神将碎片
- 养成页面
- 换将页面
- 回收页面
- 图鉴页面
- 阵容弹窗
- 旧页签节点

## 四、运行时动态节点规则

### 1. 动态节点必须幂等创建

节点创建前先按固定名称查找：

```text
不存在：创建
存在：复用
```

禁止每次打开页面都无条件 `Instantiate`，否则会出现重复页签、重复列表和重复监听。

### 2. 动态节点使用固定命名

示例：

```text
Button1
Button2_Runtime
Button3_Runtime
```

每次初始化时都必须重新设置：

- 名称
- 文本
- 位置
- 是否选中
- 是否显示
- 是否可交互
- 点击监听

### 3. 共享节点切换必须关闭多余节点

本次实际问题：

```text
神将碎片页创建 Button3_Runtime
→ 切换到境界页
→ 境界页只配置 Button1、Button2_Runtime
→ Button3_Runtime 未关闭
→ 境界页多出“碎片”标签
```

处理方式：境界页只允许境界和背包两个标签，其余 `Panel_10` 子节点全部关闭。

通用写法：

```csharp
foreach (Transform child in tabPanel)
{
    if (child != first && child != second)
        child.gameObject.SetActive(false);
}
```

## 五、层级和显示顺序规则

共享页面必须同时检查两种顺序：

### 1. Hierarchy 逻辑顺序

例如：

```text
Bg
Panel_12
功能内容
GoldCheck
```

### 2. 实际渲染和 Raycast 顺序

Hierarchy 顺序正确不代表实际显示和点击一定正确。需要确认：

- 背景不会覆盖功能内容
- 功能内容不会覆盖页签
- 金币栏不会挡住内容
- 页签可以被 EventSystem 点击
- 动态列表不会覆盖关闭按钮
- 隐藏节点没有继续拦截 Raycast

如果一个节点既要保持逻辑位置，又要位于视觉顶层，应单独提供类似 `RaiseHeroHubChrome()` 的层级整理方法，不要依赖手工拖拽。

## 六、返回、关闭和 UI Stack

### 1. 共享窗口必须只有一个关闭所有者

境界、背包、神将 Hub 共用 `OneLevelLayer` 时，关闭按钮必须根据当前所有者执行不同逻辑：

```text
境界页：关闭境界并退出共享窗口
境界背包页：关闭背包并退出共享窗口
神将页：关闭神将 Hub
养成页：返回神将 Hub 当前页签
换将页：返回神将 Hub 当前页签
```

### 2. 不允许旧关闭逻辑覆盖新逻辑

旧 Presenter 可能会重新绑定：

```csharp
CloseBtn.onClick
```

因此每次打开共享页面后都要重新绑定当前页面的关闭行为，并确认旧监听已清理。

### 3. 返回后必须恢复页面状态

重点验证：

```text
碎片 → 养成 → 返回
神将 → 换将 → 关闭
神将 → 回收 → 关闭
神将图鉴 → 返回
境界 → 背包 → 关闭
关闭 → 重新打开
```

不能只验证首次打开。

## 七、旧入口和节点删除规则

删除节点前，先删除或注释代码绑定，再删除 Prefab 节点。

推荐顺序：

```text
搜索所有路径引用
→ 移除旧入口 BindClick
→ 移除旧红点映射
→ 将必需节点改为可选节点
→ 编译检查
→ Play 检查
→ 删除 Prefab 节点
→ 再次编译和 Play 检查
```

### 本次可以删除的旧入口

```text
UImainLayer_new/Bg/btn_Bag
UImainLayer_new/Bg/btn_shenjiangbeibao
UImainLayer_new/Bg/btn_renwu
UImainLayer_new/Main_UI/ButtonGroup3
UImainLayer_new/Main_UI/btn_online
```

### 本次不能直接删除的容器

```text
Main_UI/tankuang1
Main_UI/tankuang2
Main_UI/ButtonGroup4
Main_UI/ButtonGroup8
```

这些节点虽然可能处于隐藏状态，但仍被商店、装备、法宝、玩法或其他代码使用。

## 八、数据刷新规则

页面显示和数据刷新必须分开确认：

```text
显示目标页面
→ 请求数据或确认已有权威数据
→ 等待协议/Store 更新
→ Render
```

常见错误：

- 页面切换了，但仍显示上一个页面的列表
- 数据请求没有重新发起
- 旧列表没有清空
- 新页面使用旧 Presenter 的数据
- 重复订阅 `Store.Changed`
- 关闭页面后订阅没有解除

动态列表每次 Render 前应确认：

- 旧行是否清理
- 当前数据数量是否正确
- 当前列表容器是否属于当前页面
- 当前页面是否仍是 UI Stack 顶层

## 九、输入和验收要求

最终验收必须使用真实玩家路径：

- 真实 EventSystem 点击
- 真实 Raycast 命中
- 真实页面打开和关闭
- 真实数据请求和返回
- 真实 UI Stack Push/Pop

不能只使用以下方式作为最终验收：

- 直接调用 Presenter 方法
- 直接调用 `onClick.Invoke()`
- 只看静态截图
- 只看 Inspector 层级
- 只验证首次打开

## 十、合并 UI 回归清单

### 首次打开

- [ ] 默认页签正确
- [ ] 页签数量正确
- [ ] 页面标题正确
- [ ] 背景没有覆盖内容
- [ ] GoldCheck 显示正确
- [ ] 当前页面数据正确

### 连续切页

- [ ] 布阵 → 神将
- [ ] 神将 → 碎片
- [ ] 碎片 → 布阵
- [ ] 碎片 → 境界
- [ ] 境界 → 背包
- [ ] 背包 → 境界
- [ ] 不出现旧页签
- [ ] 不出现重复页签
- [ ] 不出现旧列表

### 子页面返回

- [ ] 神将 → 养成 → 返回
- [ ] 神将 → 换将 → 关闭
- [ ] 神将 → 回收 → 关闭
- [ ] 神将图鉴 → 返回
- [ ] 阵容弹窗 → 返回

### 重复进入

- [ ] 关闭后重新打开
- [ ] 连续打开同一页面 3 次
- [ ] 连续切换页签 5 次
- [ ] 动态节点数量不增长
- [ ] 点击监听不重复触发
- [ ] 数据行数量不重复

### 关闭和输入

- [ ] 关闭按钮可点击
- [ ] 返回键行为正确
- [ ] 页签可真实点击
- [ ] 功能按钮可真实点击
- [ ] 隐藏节点不拦截 Raycast

## 十一、推荐代码结构

```text
MergedPageCoordinator
├── CurrentOwner
├── CurrentTab
├── ShowTab(tab)
├── HideAllContent()
├── ConfigureTabs(tab)
├── ConfigureSiblingOrder(owner, tab)
├── BindClose(owner)
├── RefreshData(owner, tab)
└── Close(owner)
```

旧 Presenter 只负责自己的内容渲染，不直接控制共享页签、共享背景和 UI Stack。

## 十二、本次修复涉及的关键文件

- `unityclient/Assets/ProjectX/src/Core/ProjectXApp.HeroHub.cs`
- `unityclient/Assets/ProjectX/src/Core/ProjectXApp.JingJie.cs`
- `unityclient/Assets/ProjectX/src/Core/ProjectXApp.cs`
- `unityclient/Assets/ProjectX/src/UI/MainTaskTrackerPresenter.cs`
- `unityclient/Assets/ProjectX/src/UI/MainHudPresenter.cs`
- `unityclient/Assets/ProjectX/src/LuaRuntime/FirstPlayableLoopBridge.cs`

新 UI 合并任务开始前，应先阅读本文档，再进行节点、代码和运行时状态设计。
