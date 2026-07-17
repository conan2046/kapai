# 底层、登录与主界面

## 范围

- Bootstrap 启动场景、登录、创角、选角、断线/重连、切换账号。
- App 状态、xLua 生命周期、协议注册、请求上下文、错误边界。
- 主界面 HUD、返回栈、设置、资源、服务器时间、Loading、Toast、Reward。

## 主要实现

| 能力 | 入口 |
|---|---|
| App | `Assets/ProjectX/src/Core/ProjectXApp.cs` |
| 服务容器 | `Assets/ProjectX/src/Core/GameServices.cs` |
| 启动参数 | `Assets/ProjectX/src/Core/AppLaunchOptions.cs` |
| 协议 | `Assets/ProjectX/src/Network/ProtocolRegistry.cs` |
| Lua 启动 | `Assets/ProjectX/Resources/Lua/Bootstrap.txt` |
| 场景装配 | `Assets/ProjectX/src/Editor/BootstrapSceneBuilder.cs` |
| 自动化 | `Assets/ProjectX/src/Editor/BootstrapAppRunner.cs` |

## 已验证

- 正式 Bootstrap：登录、选角、主界面、背包入口闭环。
- 自动重连和手动重连；Esc 返回；切换账号回到断开状态登录 UI。
- Player/Currency：`/1004、/18、/226、/321`。
- ServerTime：`/206` 的 `todaySeconds + unixSeconds`。
- 设置音量持久化、Loading、Toast、MessageBox、RewardPresenter。

## 关键坑

- Windows 协议必须保持 UTF-16LE、旧长度语义、合法零载荷包和每 socket send queue。
- 销毁顺序必须避免 UiStack 二次访问已销毁对象。
- Unity 调用可能异步返回，自动化使用 `Start-Process -Wait`。
- 结果文件必须在每次 Runner 前删除并校验时间戳。

## 遗留

- 正式登录服、发布配置、协议回放、完整错误码、AudioService、红点树深化、资源异步与内存预算。
