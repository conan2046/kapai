-- local function RequireFrames()
-- 	"Common.Tips"
-- 	"core.AppDef"
-- 	"core.GameSdk"
-- 	"core.GamePlatform"
-- 	"Frame.Define"


-- 	--工具库

-- 	"Common.Utils"
-- 	--每个模块的Base类
-- 	"Frame.Base.LUIBase"
-- 	"Frame.Base.LAudioBase"
-- 	"Frame.Base.LNetBase"
-- 	"Frame.Base.LGameBase"
-- 	"Frame.Base.LDataBase"

-- 	--消息转发中心
-- 	"Frame.LMsgCenter"

-- 	--消息号
-- 	--"Frame.Asset.LAssetEvent"
-- 	"Frame.LEventNode"
-- 	"Event.LTCPEvent"
-- 	"Event.LUIEvent"
-- 	"Event.LGameEvent"
-- 	"Event.LDataEvent"
-- 	"Event.LAudioEvent"
-- 	--消息结构
-- 	"Frame.LMsgBase"
-- 	--"Frame.Asset.LAssetMsg"
-- 	"Frame.Net.LTCPMsg"
-- 	"Msg.LUIMsg"
-- 	"Msg.LDataMsg"
-- 	"Msg.LSocketMsg"

-- 	--缓存一些常用的消息结构
-- 	"Msg.LGameMsg"


-- 	--各个模块的管理类
-- 	"Frame.Manager.LManagerBase"
-- 	"Frame.Manager.LUIManager"
-- 	"Frame.Manager.LAssetManager"
-- 	"Frame.Manager.LNetManager"
-- 	"Frame.Manager.LGameManager"
-- 	"Frame.Manager.LDataManager"
-- 	"Frame.Manager.LAudioManager"
-- end


-- local function RequireNetWork()
-- 	--游戏用到的网络结构
-- 	"NetWork.LuaNetCmd"
-- 	"NetWork.LuaNetRecvdMsg"
-- 	"NetWork.LuaNetSendMsg"
-- end

-- local function RequireData()
-- 	"Data.LMapData"
-- 	--
-- 	"Data.LArtifactData"
-- 	"Data.LActivityData"
-- 	"Data.LKunLunShan"
-- 	"Data.LVipData"
-- 	"Data.LCopyData"
-- 	"Data.LXueMaiData"
-- 	"Data.LConvoyData"
-- 	"Data.LFactionData"
-- 	"Data.LChiBangData"
-- 	"Data.LHorseData"
-- 	"Data.LPetData"
-- 	"Data.LDiscountShopInfo"
-- 	"Data.LSkillData"
-- 	"Data.LItemData"
-- 	"Data.LTaskData"
-- 	"Data.LTeamData"
-- 	"Data.LHeroDetailData"
-- 	"Data.LMonopolyData"
-- 	"Data.Player.LRoleData"
-- 	"Data.LNPCChatData"
-- 	"Data.LDataConstMgr"
-- 	"Data.LUserConfigMgr"
-- 	"Data.LChatData"
-- 	"Data.LFriendsData"
-- 	"Data.LCoupleData"
-- 	"Data.LMedalInfo"
-- 	"Data.LRoleDataMgr"
-- 	"Data.LMailData"
-- 	"Data.LChallengeDataMgr"
-- 	"Data.XML.LActivityManager"
-- 	"Data.LMarketInfo"
-- 	"Data.LDailySignData"
-- 	"Data.LBattleData"
-- 	"Data.LBTFormationData"
-- 	"Data.LLuckyDrawInfo"
-- 	"Data.LImproveItem"
-- 	"Data.LRechargeDataMgr"
-- end

-- local function RequireCommonUI()
-- 	"View.Global.ItemCellUI"
-- 	"View.Global.SkillCellUI"
-- 	"View.Forge.ForgeFunction"
-- 	"View.Common.EffectUtils"
-- 	"View.Common.PetIcon"

-- 	"View.ImproveUI.ImproveDef"
-- end

-- local scene = cc.Director:getInstance():getRunningScene()

-- scene:runAction(cc.Sequence:create(
-- 							cc.DelayTime:create(0.1), cc.CallFunc:create(RequireFrames),
-- 							cc.DelayTime:create(0.1), cc.CallFunc:create(RequireNetWork),
-- 							cc.DelayTime:create(0.1), cc.CallFunc:create(RequireData),
-- 							cc.DelayTime:create(0.1), cc.CallFunc:create(RequireCommonUI))
-- 				)

local requireArr = {
	"Common.Tips",
	"Common.BaseModel",
	"core.AppDef",
	"core.GameSdk",
	"core.GameSdkIOS",
	"core.GameSdkYiJie",
	"core.GamePlatform",
	"Frame.Define",


	--工具库

	"Common.Utils",
	--每个模块的Base类
	"Frame.Base.LUIBase",
	"Frame.Base.LAudioBase",
	"Frame.Base.LNetBase",
	"Frame.Base.LGameBase",
	"Frame.Base.LDataBase",

	--消息转发中心
	"Frame.LMsgCenter",

	--消息号
	--"Frame.Asset.LAssetEvent"
	"Frame.LEventNode",
	"Event.LTCPEvent",
	"Event.LUIEvent",
	"Event.LGameEvent",
	"Event.LDataEvent",
	"Event.LAudioEvent",
	--消息结构
	"Frame.LMsgBase",
	--"Frame.Asset.LAssetMsg"
	"Frame.Net.LTCPMsg",
	"Msg.LUIMsg",
	"Msg.LDataMsg",
	"Msg.LSocketMsg",

	--缓存一些常用的消息结构
	"Msg.LGameMsg",


	--各个模块的管理类
	"Frame.Manager.LManagerBase",
	"Frame.Manager.LUIManager",
	--"Frame.Manager.LAssetManager",
	"Frame.Manager.LNetManager",
	"Frame.Manager.LGameManager",
	"Frame.Manager.LDataManager",
	"Frame.Manager.LAudioManager",

	--游戏用到的网络结构
	"NetWork.LuaNetCmd",
	"NetWork.LuaNetRecvdMsg",
	"NetWork.LuaNetSendMsg",

	"Data.LMapData",
	--
	"Data.LArtifactData",
	"Data.LActivityData",
	"Data.LKunLunShan",
	"Data.LVipData",
	"Data.LCopyData",
	"Data.LXueMaiData",
	"Data.LConvoyData",
	"Data.LFactionData",
	"Data.LChiBangData",
	"Data.LHorseData",
	"Data.LJingJieData",
	"Data.LBufferData",
	"Data.LPetData",
	"Data.LDiscountShopInfo",
	"Data.LSkillData",
	"Data.LItemData",
	"Data.LTaskData",
	"Data.LTeamData",
	"Data.LHeroDetailData",
	"Data.LMonopolyData",
	--"Data.LYouLiData",
	"Data.LOnLineData",
	"Data.Player.LRoleData",
	"Data.LNPCChatData",
	"Data.JsonConfig",
	"Data.LDataConstMgr",
	"Data.LUserConfigMgr",
	"Data.LChatData",
	"Data.LFriendsData",
	"Data.LGroupData",
	"Data.LCoupleData",
	"Data.LMedalInfo",
	"Data.LAccountData",
	"Data.LSocialData",
	"Data.LOfflineRewardData",
	"Data.LRoleDataMgr",
	"Data.LMailData",
	"Data.LChallengeDataMgr",
	"Data.XML.LActivityManager",
	"Data.LMarketInfo",
	"Data.LDailySignData",
	"Data.LBattleData",
	"Data.LBTFormationData",
	"Data.LLuckyDrawInfo",
	"Data.LImproveItem",
	"Data.LRechargeDataMgr",
	"Data.LFastShopDataMgr",
    "Data.LBangPaiWarDataMgr",
    "Data.LNationalRankData",

    "Data.LFuBenData",
    "Data.LMisstionDialog",
    "Data.PetkaPaiManager",
    

	"View.Global.HeroCellUI",
	"View.Global.ItemCellUI",
	"View.Global.SkillCellUI",
	"View.Global.PetCellUI",
	--"View.Forge.ForgeFunction",
    "View.Activity.ActivityFunction",
	"View.Common.EffectUtils",
	"View.Common.PetIcon",

	"View.ImproveUI.LCheckImproveMgr",
	"View.ImproveUI.ImproveDef",
	"View.ImproveUI.RedDotDef",
	"View.ImproveUI.LRedDotCheckMgr",
	"View.Guide.GuideDef",
	"View.Social.LVoiceDataMgr",
	"View.ZhengBa.LWWDXMgr",
}

local function LoadCommonRequire(completeCallback)
	-- local scheduler = nil 
	-- local function requireCallback(dt)
	-- 	if #requireArr > 0 then
	-- 		require(requireArr[1])
	-- 		table.remove(requireArr,1)
	-- 	else
	-- 		cc.Director:getInstance():getScheduler():unscheduleScriptEntry(scheduler)
	-- 		scheduler = nil
	-- 		if completeCallback then
	-- 			completeCallback()
	-- 		end
	-- 	end
	    
	-- end 

	-- scheduler = cc.Director:getInstance():getScheduler():scheduleScriptFunc(requireCallback, 0, false)
	for i = 1,#requireArr do
		require(requireArr[i])
	end
	requireArr = nil
	if completeCallback then
		completeCallback()
	end
end

return LoadCommonRequire

-- local scene = cc.Director:getInstance():getRunningScene()

-- scene:runAction(cc.Sequence:create(
-- 							cc.DelayTime:create(0.1), cc.CallFunc:create(RequireFrames),
-- 							cc.DelayTime:create(0.1), cc.CallFunc:create(RequireNetWork),
-- 							cc.DelayTime:create(0.1), cc.CallFunc:create(RequireData),
-- 							cc.DelayTime:create(0.1), cc.CallFunc:create(RequireCommonUI))
-- 				)