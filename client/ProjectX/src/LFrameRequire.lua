require "Common.Tips"
require "core.AppDef"
require "core.GameSdk"
require "core.GameSdkIOS"
require "core.GameSdkYiJie"
require "core.GamePlatform"
require "Frame.Define"


--工具库
require "Common.Utils"
--每个模块的Base类
require "Frame.Base.LUIBase"
--require "Frame.Base.LAudioBase"
require "Frame.Base.LNetBase"
require "Frame.Base.LGameBase"
require "Frame.Base.LDataBase"

--消息转发中心
require "Frame.LMsgCenter"

--消息号
--require "Frame.Asset.LAssetEvent"
require "Frame.LEventNode"
require "Event.LTCPEvent"
require "Event.LUIEvent"
require "Event.LGameEvent"
require "Event.LDataEvent"
require "Event.LAudioEvent"
--消息结构
require "Frame.LMsgBase"
--require "Frame.Asset.LAssetMsg"
require "Frame.Net.LTCPMsg"
require "Msg.LUIMsg"
require "Msg.LDataMsg"
require "Msg.LSocketMsg"

--缓存一些常用的消息结构
require "Msg.LGameMsg"


--各个模块的管理类
require "Frame.Manager.LManagerBase"
require "Frame.Manager.LUIManager"
--require "Frame.Manager.LAssetManager"
require "Frame.Manager.LNetManager"
require "Frame.Manager.LGameManager"
require "Frame.Manager.LDataManager"
require "Frame.Manager.LAudioManager"