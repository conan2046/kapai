# ProjectX Cocos2d-x Lua Client Maintenance Guide

本文档用于后续二次开发和维护时快速理解项目结构、启动链路、主要模块职责和常见改动入口。

## 1. 项目定位

这是一个老式 Cocos2d-x Lua 手游客户端工程。

- 引擎：Cocos2d-x 3.17
- 脚本语言：Lua
- UI 工具：Cocos Studio 3.10
- Windows 开发环境：VS2015
- 主体工程目录：`ProjectX`

整体职责划分：

- Lua 层负责 UI、业务逻辑、协议收发包装、数据模型、配置表加载。
- C++/原生层负责引擎、平台工程、网络底层、SDK 接入、打包和部分桥接对象。
- `simulator/win32` 是 Windows 模拟器运行目录，包含已拷贝的 `src/res` 和 `ProjectX.exe`。

根目录的 `新老项目说明.txt` 说明该项目从老 C++ 项目迁移到 Lua，很多老类名被 Lua 类替代，例如：

- `ItemMgr` -> `LItemMgr`
- `SkillMgr` -> `LSkillMgr`
- `DATA_MGR` -> `LRoleDataMgr`
- `DataConst` -> `LDataConstMgr`
- `UserConfig` -> `LUserConfigMgr`
- C++ 宏和枚举大多迁移到 `src/core/AppDef.lua`

## 2. 顶层目录

```text
client/
  Android/                         # 当前基本为空，可能是历史目录
  ProjectX/                         # Cocos2d-x Lua 主工程
  新老项目说明.txt
```

`ProjectX` 主要目录：

```text
ProjectX/
  config.json                       # 模拟器/工程启动配置，入口为 src/main.lua
  .cocos-project.json               # Cocos 工程信息
  copy_lua_to_simulator.bat         # 拷贝 Lua 到 win32 模拟器
  src/                              # Lua 代码主目录
  res/                              # 图片、csd、音频、配置等资源
  frameworks/                       # Cocos2d-x 引擎与原生平台工程
  simulator/win32/                  # Windows 模拟器运行目录
```

## 3. 启动链路

入口配置位于 `ProjectX/config.json`：

```json
{
  "init_cfg": {
    "isLandscape": true,
    "width": 1334,
    "height": 750,
    "entry": "src/main.lua"
  }
}
```

实际启动流程：

1. `src/main.lua`
   - 设置 Lua 搜索路径。
   - 先添加热更目录：
     - `writablePath/package/src/`
     - `writablePath/package/res/`
   - 再添加本地目录：
     - `src/`
     - `res/`
   - 加载 `config`、`cocos.init`。
   - 创建并运行 `View.LogoScene`。

2. `src/View/LogoScene.lua`
   - 显示登录背景图。
   - Windows 模拟器环境直接进入 `View.GameScene`。
   - 非 Windows 环境进入 `View.UpdateScene`，通常用于热更/更新检查。

3. `src/View/GameScene.lua`
   - 初始化背景和加载提示。
   - Windows 下初始化游戏版本信息。
   - 预加载通用 plist 资源。
   - 调用 `LCommonRequire` 加载基础脚本。

4. `src/LCommonRequire.lua`
   - 批量 require 框架、事件、消息、管理器、网络、数据、通用 UI。
   - 加载完成后回调 `GameScene:GameStart()`。

5. `GameScene:GameStart()`
   - 继续加载运行时逻辑：
     - `Frame.Net.LTCPSocket`
     - `Logic.LUILogic`
     - `Logic.LResLogic`
     - `Logic.LSoundLogic`
     - `Logic.LBattleLogic`
     - `Logic.LGameLogic`

6. `Logic.LGameLogic`
   - 初始化登录 UI。
   - 加载本地配置。
   - 负责登录服/游戏服连接、切图、战斗、跨服等主流程。

## 4. Lua 目录职责

`ProjectX/src` 下主要目录：

```text
src/
  app/                  # Cocos 默认模板残留，当前主流程基本不用
  cocos/                # Cocos Lua framework 文件
  Common/               # 通用工具、提示、时间、对象池等
  ConfigData/           # Lua 格式配置表，文件名一般为 xxx_dat.lua
  core/                 # 全局定义、SDK、平台桥接
  Data/                 # 数据模型、配置管理、玩家数据、业务数据缓存
  Event/                # Lua 事件 ID 定义
  Frame/                # 自建框架层：消息、管理器、基类、网络包装
  Logic/                # 核心逻辑控制器：UI、游戏、战斗、音频、资源
  Manifest/             # 热更/资源清单相关
  Msg/                  # Lua 消息结构
  NetWork/              # 协议号、发包、收包解析
  ObjectPool/           # 对象池
  packages/             # quick/mvc 等辅助包
  sdkInterface/         # SDK 接口相关 Lua
  View/                 # 业务 UI 层
```

## 5. 核心模块

### 5.1 `core`

关键文件：

- `core/AppDef.lua`
- `core/AppBTDef.lua`
- `core/AppHeroDef.lua`
- `core/AppUIDef.lua`
- `core/AppSettingDef.lua`
- `core/GameSdk.lua`
- `core/GameSdkIOS.lua`
- `core/GameSdkYiJie.lua`
- `core/GamePlatform.lua`

职责：

- 定义全局常量、枚举、UI 层级、战斗常量、平台标识。
- 维护服务器地址、渠道号、AppId、开关配置。
- 封装 Android/iOS 原生调用。
- 处理 SDK 登录、支付、渠道回调等。

注意：

- `AppDef.ipAdrr` 和 `AppDef.ipPort` 当前写在 `AppDef.lua`。
- `AppDef.APPID_DOUSHENWUSHUANG`、`AppDef.APPID_JIANZHENGZHUXIAN` 用于区分产品/包体逻辑。

### 5.2 `Frame`

这是 Lua 自建框架层，核心是消息分发。

关键文件：

- `Frame/LMsgCenter.lua`
- `Frame/LMsgBase.lua`
- `Frame/LEventNode.lua`
- `Frame/Define.lua`
- `Frame/Base/*`
- `Frame/Manager/*`
- `Frame/Net/*`

消息流大致如下：

```text
业务对象
  -> SendMsg(msg)
  -> 对应 Manager
  -> LMsgCenter
  -> 根据 msg:GetManager() 分发到 LUIManager/LNetManager/LGameManager/LDataManager/LAudioManager
```

`LMsgCenter` 还会接收原生层回调：

```lua
LuaAndCMsgCenters:GetInstance():SettingLuaCallBack(handleMsg)
```

如果消息不属于 Lua 管理器，会转发回原生层：

```lua
self.msgCenter:SendToMsg(tmpMsg)
```

### 5.3 `Logic`

运行时主逻辑集中在这里。

关键文件：

- `Logic/LUILogic.lua`
- `Logic/LGameLogic.lua`
- `Logic/LBattleLogic.lua`
- `Logic/LSoundLogic.lua`
- `Logic/LResLogic.lua`

职责：

- `LUILogic`：UI 初始化、打开、关闭、隐藏、弹窗层级、战斗内 UI、通用弹窗。
- `LGameLogic`：登录/选服/进服/切图/战斗/跨服/前后台等游戏主流程。
- `LBattleLogic`：战斗播放、技能、动作、单位、战斗 UI、自动战斗等。
- `LSoundLogic`：背景音乐、音效。
- `LResLogic`：资源使用和释放，CSB 复用等。

### 5.4 `NetWork`

网络协议 Lua 层主要在：

- `NetWork/LuaNetCmd.lua`：协议号定义。
- `NetWork/LuaNetSendMsg.lua`：发包接口。
- `NetWork/LuaNetRecvdMsg.lua`：收包解析和分发。

底层 Socket 由原生层实现，Lua 通过 `Frame.Net.LTCPSocket` 包装事件：

- `LTCPEvent.LoginConnect`
- `LTCPEvent.LoginSendMsg`
- `LTCPEvent.GameConnect`
- `LTCPEvent.GameSendMsg`
- `LTCPEvent.GameDisConnect`

常见发包写法在 `LuaNetSendMsg.lua`：

```lua
self.m_pStream:WriteUShort(LuaNetCmd.MSG_XXX)
self.m_pStream:WriteInt(...)
self.m_pStream:WriteString(...)
```

### 5.5 `Data`

数据层包含两类内容：

- 运行时数据模型，例如角色、背包、宠物、任务、邮件、帮派等。
- 本地配置表加载和缓存。

关键文件：

- `Data/JsonConfig.lua`
- `Data/LDataConstMgr.lua`
- `Data/LRoleDataMgr.lua`
- `Data/Player/LRoleData.lua`

配置加载方式有两种：

1. Lua 表配置：

```lua
local objs = require("ConfigData." .. info.jsonName .. "_dat")
```

2. dat 文件读取：

```lua
local stream = StreamBase:CreateReadStreamFromFile("ConfigData/xxx.dat")
```

### 5.6 `View`

业务 UI 都在 `src/View`，按功能拆目录。

常见目录：

```text
View/
  Login/
  Main/
  Battle/
  Pet/
  Role/
  Shop/
  Welfare/
  WelfareActivity/
  WorldMap/
  Team/
  Chat/
  Mail/
  Rank/
  Tower/
  XueZhan/
  ZhengBa/
```

UI 通常由 Lua 脚本配合 `res/csd` 下的 `.csb` 文件实现。

打开 UI 常见入口：

```lua
LGameMsg.m_initUIMsg:Change("Login.LoginBgUI", AppDef.UIType.Normal)
self:SendMsg(LGameMsg.m_initUIMsg)
```

最终由 `LUILogic:InitUI()` require 对应 `View.xxx` Lua 脚本，并创建 UI 层。

## 6. 资源目录

`ProjectX/res` 主要包含：

```text
res/
  csd/             # Cocos Studio 导出的 csb/plist/png 等
  UI/              # UI 图片资源
  ConfigData/      # dat 配置文件
  Default/         # 默认粒子等
  hero/ item/ Skill/ Monster/ NPC/ ...
```

常见通用资源在 `GameScene:PreloadCommonRes()` 中预加载：

- `csd/Plist/ui_loginPlist`
- `csd/Plist/ui_commonPlist`
- `csd/Plist/ui_mainPlist`
- `csd/Plist/ui_zhandouPlist`
- `csd/Plist/ui_huobi`
- `csd/Plist/ui_wanfaPlist`

## 7. 平台工程和模拟器

原生工程目录：

```text
ProjectX/frameworks/runtime-src/
  proj.win32/
  proj.android/
  proj.android_ad1/
  proj.android_ad3/
  proj.android_ad4/
  proj.android_ad998/
  proj.android_ad999/
  proj.ios_mac/
  proj.linux/
```

Windows 工程：

```text
ProjectX/frameworks/runtime-src/proj.win32/ProjectX.sln
```

Windows 模拟器运行目录：

```text
ProjectX/simulator/win32/
  ProjectX.exe
  src/
  res/
  config.json
  *.dll
```

脚本：

```bat
ProjectX/copy_lua_to_simulator.bat
```

只拷贝 `src` 到模拟器：

```bat
xcopy src\* simulator\win32\src /D /E /I /F /Y
```

```bat
ProjectX/simulator/win32/copy_lua_to_simulator.bat
```

拷贝 `src/res` 并启动模拟器：

```bat
xcopy ..\..\src\* src /D /E /I /F /Y
xcopy ..\..\res\* res /D /E /I /F /Y
START ProjectX.exe
```

## 8. 二次开发常见入口

### 8.1 新增或修改 UI

常见步骤：

1. 在 `res/csd` 或相关资源目录添加/更新 Cocos Studio 导出的 `.csb`、图片、plist。
2. 在 `src/View/业务模块/` 下新增或修改 Lua UI 脚本。
3. 如需打开 UI，通过 `LUILogicEvent.InitUI` 或封装工具发消息。
4. 如需新增 UI 类型/层级，查看 `core/AppUIDef.lua` 和 `core/AppDef.lua`。
5. 如需通用入口按钮，通常改 `View/Main` 或相关功能模块入口。

### 8.2 新增协议

常见步骤：

1. 在 `NetWork/LuaNetCmd.lua` 添加协议号。
2. 在 `NetWork/LuaNetSendMsg.lua` 添加发包方法。
3. 在 `NetWork/LuaNetRecvdMsg.lua` 添加收包解析方法。
4. 将解析结果写入 `Data` 层对应数据对象。
5. 通过消息事件通知 `View` 或 `Logic` 刷新。

### 8.3 新增配置表

Lua 表配置：

1. 在 `src/ConfigData` 添加 `xxx_dat.lua`。
2. 在 `Data/JsonConfig.lua` 的 `JsonConfig.initConfig()` 中通过 `JsonConfig.SetConfig()` 加载。
3. 在业务模块中通过 `JsonConfig.m_xxx` 或封装 getter 使用。

dat 配置：

1. 在 `res/ConfigData` 添加 `.dat`。
2. 在 `Data/LDataConstMgr.lua` 里添加读取逻辑。
3. 注意读取字段顺序必须和导表格式一致。

### 8.4 修改登录/选服/进游戏流程

重点看：

- `View/Login/*`
- `Logic/LGameLogic.lua`
- `core/GameSdk.lua`
- `core/GamePlatform.lua`
- `NetWork/LuaNetSendMsg.lua`
- `NetWork/LuaNetRecvdMsg.lua`

登录服连接入口：

```lua
LGameLogic:ConnectLoginSocket()
```

游戏服连接入口：

```lua
LGameMsg.m_tcpMsg:Change(LTCPEvent.GameConnect, LGameNetEvent.TcpGameBack, ip, port)
```

### 8.5 修改战斗

重点看：

- `Logic/LBattleLogic.lua`
- `View/Battle/*`
- `Data/LBattleData.lua`
- `core/AppBTDef.lua`
- `res/ConfigData/battle/*`

战斗模块很大，建议先按事件或协议号搜索，再沿着数据对象和 UI 刷新链路改。

## 9. 开发注意事项

### 9.1 文件编码

很多 Lua 文件中的中文注释在当前环境读取时会乱码，说明老文件大概率是 GBK/ANSI 编码。修改老文件时要注意编辑器编码，避免整文件被错误转码。

建议：

- 小改动优先保持原编码。
- 不要无意义格式化全文件。
- 不要批量转换编码，除非先统一验证运行环境。

### 9.2 Lua 下标

项目说明中特别提醒：Lua 数组默认从 1 开始，服务端很多数据从 0 开始。协议解析和 UI 列表展示时要特别小心 off-by-one 问题。

### 9.3 全局变量很多

`config.lua` 中 `CC_DISABLE_GLOBAL = false`，项目允许全局变量。老代码大量使用全局单例，例如：

- `AppDef`
- `GameSdk`
- `LGameMsg`
- `LDataConstMgr`
- `LRoleDataMgr`
- `JsonConfig`
- `LuaNetSendMsg`
- `LuaNetRecvdMsg`

新增代码时尽量沿用现有风格，但要避免无意污染全局命名。

### 9.4 模拟器目录是拷贝产物

`ProjectX/simulator/win32/src` 和 `ProjectX/simulator/win32/res` 是运行用拷贝。正常开发应优先修改：

- `ProjectX/src`
- `ProjectX/res`

然后用脚本同步到模拟器。

不要把模拟器目录里的拷贝当作唯一源文件。

### 9.5 Android assets 也可能是发布拷贝

`frameworks/runtime-src/proj.android_*` 下可能包含 `assets/src`、`assets/res` 这类发布产物。维护时应优先确认源头是否在 `ProjectX/src` 和 `ProjectX/res`。

## 10. 推荐排查方法

按功能排查时：

1. 先从 UI 文本、按钮名、csb 名、协议号搜索。
2. 找到 `View/模块名` 下对应 UI。
3. 查 UI 中调用的 `LuaNetSendMsg:*`。
4. 根据协议号去 `LuaNetRecvdMsg` 找响应解析。
5. 看解析结果写入哪个 `Data` 对象。
6. 再看通过哪个事件通知 UI 刷新。

常用搜索命令：

```powershell
rg -n "关键字" ProjectX/src
rg -n "MSG_协议名" ProjectX/src/NetWork
rg -n "UI脚本名" ProjectX/src ProjectX/res
rg -n "LUILogicEvent" ProjectX/src/View ProjectX/src/Logic
```

## 11. 快速索引

```text
启动入口              ProjectX/src/main.lua
启动场景              ProjectX/src/View/LogoScene.lua
游戏加载场景          ProjectX/src/View/GameScene.lua
批量 require          ProjectX/src/LCommonRequire.lua
全局定义              ProjectX/src/core/AppDef.lua
UI 定义               ProjectX/src/core/AppUIDef.lua
消息中心              ProjectX/src/Frame/LMsgCenter.lua
UI 逻辑               ProjectX/src/Logic/LUILogic.lua
游戏主逻辑            ProjectX/src/Logic/LGameLogic.lua
战斗逻辑              ProjectX/src/Logic/LBattleLogic.lua
协议号                ProjectX/src/NetWork/LuaNetCmd.lua
发包                  ProjectX/src/NetWork/LuaNetSendMsg.lua
收包                  ProjectX/src/NetWork/LuaNetRecvdMsg.lua
配置表管理            ProjectX/src/Data/JsonConfig.lua
旧式 dat 配置管理     ProjectX/src/Data/LDataConstMgr.lua
业务 UI               ProjectX/src/View
Lua 表配置            ProjectX/src/ConfigData
资源                  ProjectX/res
Win32 工程            ProjectX/frameworks/runtime-src/proj.win32/ProjectX.sln
Win32 模拟器          ProjectX/simulator/win32/ProjectX.exe
```

