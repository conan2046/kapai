--[[
lua里面的UI逻辑控制
]]

LUILogic = LUIBase:New()
LUILogic.__index = LUILogic
require("ObjectPool.LObjPoolMgr")
--local this = LTcpSocket
function LUILogic:New()
	--------print("LUILogic:New")
	local o = LUIBase:New()
	setmetatable(o,LUILogic)
	o:Init()
	return o
end

function LUILogic:Init()
	--------print("LUILogic:Init")
	self.msgIds = 
	{
		LUILogicEvent.InitUI,
		LUILogicEvent.InitUIInBattle,
		LUILogicEvent.ShowUI,
		LUILogicEvent.HideUI,
		LUILogicEvent.DeleteUI,
		LUILogicEvent.Clear,
		LUILogicEvent.PlotChatModel,
		LUILogicEvent.ShowFloatNotice,
		LUILogicEvent.ShowLabaNotice,
		LUILogicEvent.ShowItemInfo,
		LUILogicEvent.ShowItemSource,
		LUILogicEvent.ShowSrcollTips,
		LUILogicEvent.ShowSrcollTipsAtferBattle,
		LUILogicEvent.ShowPowerChangeEffect,
		LUILogicEvent.ChangeScene,
		LUILogicEvent.ShowItemListUI,
		LUILogicEvent.ShowNumInputUI,
		LUILogicEvent.ShowCommomBtnList,
		LUILogicEvent.ShowFlyItems,
		LUILogicEvent.TaskAccept,
		LUILogicEvent.TaskComplete,
		LUILogicEvent.InitBagBtnPos,
		LUILogicEvent.InitHeroBtnPos,
		LUILogicEvent.EnterBattle,
		LUILogicEvent.ExitBattle,
		LUILogicEvent.ShowFiristAwardUI,
		LUILogicEvent.ShowPetInfo,
		LUILogicEvent.ShowBestStrong,
		LUILogicEvent.ShowGuide,
		LUILogicEvent.HideGuide,
		LUILogicEvent.CheckLayerExist,
		LUILogicEvent.CanAutoPath,
		LUILogicEvent.CloseAllPopup,
		LUILogicEvent.ShowItemWearTips,
        LUILogicEvent.ShowPetEquipTips,
        LUILogicEvent.ShowMonsterInfo,
        LUILogicEvent.ShowEquipGetUI,
        LUILogicEvent.CloseHighPopup,
	}
	self:RegistSelf(self,self.msgIds)
	self:InitData()
	LObjPoolMgr.Awake()
end

function LUILogic:onExit()
	self:Destory()
end

function LUILogic:InitCocos()
	AppDef.Director = AppDef.Director or cc.Director:getInstance()
	AppDef.frameSize = AppDef.frameSize or AppDef.Director:getVisibleSize()
	AppDef.spriteFrameCache = AppDef.spriteFrameCache or cc.SpriteFrameCache:getInstance()
	AppDef.textureCache = AppDef.textureCache or cc.Director:getInstance():getTextureCache()
end

--[[
初始化一下UI数据，比如UI的父节点之类
]]
function LUILogic:InitData()
	self:InitCocos()
	local director = AppDef.Director
	director:getTextureCache():removeTextureForKey("csd/Plist/ui_commonPlist.png")

	AppDef.spriteFrameCache:removeSpriteFramesFromFile("csd/Plist/ui_commonPlist.plist")
	AppDef.spriteFrameCache:addSpriteFrames("csd/Plist/ui_commonPlist.plist", "csd/Plist/ui_commonPlist.png")

	director:getTextureCache():removeTextureForKey("csd/Plist/ui_huobi.png")
	AppDef.spriteFrameCache:removeSpriteFramesFromFile("csd/Plist/ui_huobi.plist")
	AppDef.spriteFrameCache:addSpriteFrames("csd/Plist/ui_huobi.plist", "csd/Plist/ui_huobi.png")
	AppDef.spriteFrameCache:removeSpriteFramesFromFile("csd/Plist/ui_wanfaPlist.plist")
	AppDef.spriteFrameCache:addSpriteFrames("csd/Plist/ui_wanfaPlist.plist", "csd/Plist/ui_wanfaPlist.png")
	self.m_pScene = director:getRunningScene()
	--UI节点
	self.m_pUINode = cc.Node:create()
	self.m_pScene:addChild(self.m_pUINode,AppDef.GameZOrder.UILayer)
	
	local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUINode:registerScriptHandler(onNodeEvent)


	--UI缓存
	self.m_pUIBuffer = {}
	self.m_bIsInBattle = false
	self.m_pFCBuff = {}--一级弹框显示缓存
	self.m_pPFCBuff = {}--一级弹框显示缓存
	self.m_flyScheduler = nil
	self.m_pFlyItems = {}

	self.m_pMainUIBagPos = nil--主界面背包位置
	self.m_pMainUIHeroPos = nil--主界面英雄头像位置
	--[[
	一些需要战斗后播放的东西，先缓存起来，等战斗后调用
	]]
	self.m_pAfterBattleBuff = {}

	self.m_pHideUIs = {}
	

	
	self:InitUI("Common.MsgBoxUI",AppDef.UIType.MsgBox)
	self:InitUI("Common.WaitAniUI",AppDef.UIType.WaitLoading)
	self:InitUI("Common.LoadingUI",AppDef.UIType.WaitLoading)
	self:InitUI("Common.PowerChangedUI",AppDef.UIType.MsgBox)
	
	if self.m_pScene then
    	local function InitCommonBgUI()
	        self:InitCommonBgUI()
	    end
    	Utils:DelayToCallFunc(self.m_pScene,0.5,InitCommonBgUI)
    end
end

function LUILogic:Clear()
	local startInd = 1
	local function CheckDeleteUI()
		local needCheck = false
		for i = startInd,#(self.m_pUIBuffer) do
			needCheck = false
			if self.m_pUIBuffer[i] then
				if self.m_pUIBuffer[i]["luaScript"] ~= "Common.MsgBoxUI"
					and self.m_pUIBuffer[i]["luaScript"] ~= "Common.WaitAniUI"
					and self.m_pUIBuffer[i]["luaScript"] ~= "Common.LoadingUI"
					and self.m_pUIBuffer[i]["luaScript"] ~= "Battle.BattleUI" then
					local uilayer = self.m_pUIBuffer[i]["uilayer"]
					if uilayer ~=nil then
						if uilayer.isUseResBuffer then
							LGameMsg.m_baseMsgWithOne:Change(LResEvent.UnusedCsb,{uilayer.csbFilePath,uilayer.m_pUILayer})
							self:SendMsg(LGameMsg.m_baseMsgWithOne)
						else
							uilayer.m_pUILayer:removeFromParent()
						end
						--uilayer.m_pUILayer:removeFromParent()
					end
					if self.m_pUIBuffer[i]["uilayer"].layerType == AppDef.UIType.FirstClassLayer then
						self:DeleteFCBuff(self.m_pUIBuffer[i]["luaScript"])
					end
					
					self.m_pUIBuffer[i]["uilayer"] = nil
					self.m_pUIBuffer[i]["luaScript"] = nil
					table.remove(self.m_pUIBuffer, i)
					startInd = i
					needCheck = true
					break
				elseif self.m_pUIBuffer[i]["uilayer"].layerType == AppDef.UIType.MsgBox then
					self.m_pUIBuffer[i]["uilayer"].m_pUILayer:setVisible(false)
				end
			end
		end
		if needCheck then
			CheckDeleteUI()
		end
	end
	
	CheckDeleteUI()
	self.m_pFirstClassBg:SetBgVisible(false)
	self.m_pSecondClassBg:SetBgVisible(false)
end

function LUILogic:InitCommonBgUI()
	--一级弹框
	self.m_pFirstClassBg = require("View.Background.FirstClassBg"):New()
	self.m_pUINode:addChild(self.m_pFirstClassBg.m_pUILayer,AppDef.UIType.FirstClassLayer)
	self.m_pFirstClassBg:SetBgVisible(false)


	self.m_pPopFirstClassBg = require("View.Background.PopFirstClassBg"):New()
	self.m_pUINode:addChild(self.m_pPopFirstClassBg.m_pUILayer, AppDef.UIType.PopFirstClassLayer)
	self.m_pPopFirstClassBg:SetBgVisible(false)

	self.m_pSecondClassBg = require("View.Background.SecondClassBg"):New()
	self.m_pUINode:addChild(self.m_pSecondClassBg.m_pUILayer,AppDef.UIType.SecondClassLayer)
	self.m_pSecondClassBg:SetBgVisible(false)

	-- local uibuff = {}
	-- uibuff["luaScript"] = luaScript
	-- uibuff["uilayer"] = uilayer
	-- table.insert(self.m_pUIBuffer, uibuff)
end


function LUILogic:ProcessEvent(msg)
	local msdId = msg:GetMsgId()
	if msdId == LUILogicEvent.InitUI then
		--------print("ProcessEvent",msg.m_uiType)
		self:InitUI(msg.m_pScript,msg.m_uiType, msg.userData)
	elseif msdId == LUILogicEvent.InitUIInBattle then
		self:InitUIInBattle(msg.m_pScript,msg.m_uiType, msg.userData)
	elseif msdId == LUILogicEvent.DeleteUI then
		if msg.m_pScript then
			self:DeleteUI(msg.m_pScript)
		elseif msg.value then
			self:DeleteUI(msg.value)
		end
	elseif msdId == LUILogicEvent.HideUI then
		self:HideUI(msg.m_pScript, false)
	elseif msdId == LUILogicEvent.ShowUI then
		self:HideUI(msg.m_pScript, true)
	elseif msdId == LUILogicEvent.Clear then
		self:Clear()
	elseif msdId == LUILogicEvent.ShowSrcollTipsAtferBattle then
		local tipMsg = msg.m_strTips
		if tipMsg == nil or #tipMsg == 0 then
			return
		end

		local tmpMsg = {tipMsg}
		self:InitUI("Common.ScrollTipsUI",AppDef.UIType.ScrollTips,tmpMsg,false)

	elseif msdId == LUILogicEvent.ShowSrcollTips then
		local tipMsg = msg.m_strTips
		if tipMsg == nil or #tipMsg == 0 then
			tipMsg = msg.value
		end
		if tipMsg == nil or #tipMsg == 0 then
			return
		end

		local tmpMsg = {tipMsg}
		self:InitUI("Common.ScrollTipsUI",AppDef.UIType.MsgBox,tmpMsg)
	elseif msdId == LUILogicEvent.ShowPowerChangeEffect then
		local tmpMsg = {msg.value[1],msg.value[2] }
		-- local function delayShowTips()
		-- 	self:InitUI("Common.PowerChangedUI",AppDef.UIType.PopWindow,tmpMsg)
		-- end
		-- Utils:DelayToCallFunc(self.m_pUINode, 0.2,delayShowTips)

		self:InitUI("Common.PowerChangedUI",AppDef.UIType.MsgBox,tmpMsg)
	elseif msdId == LUILogicEvent.ShowItemInfo then
		local layer = self:InitUI("Common.ItemInfoUI",AppDef.UIType.PopWindow)
		layer:ShowItem(msg.value)
    elseif msdId == LUILogicEvent.ShowPetEquipTips then
    	local layer = self:InitUI("Common.PetEquipTipsUI",AppDef.UIType.PopWindow)
		layer:ShowItem(msg.value)
    elseif msdId == LUILogicEvent.ShowItemWearTips then
        local layer = self:InitUI("Common.ItemWearUI",AppDef.UIType.PopWindow)
        layer:ShowTips(msg.value)
    elseif msdId == LUILogicEvent.ShowItemSource then
    	local layer = self:InitUI("Common.ItemSourceUI",AppDef.UIType.PopWindow)
    	layer:ShowItem(msg.value)
	elseif msdId == LUILogicEvent.PlotChatModel then
		self:SetPlotChatMode(msg.value)
	elseif msdId == LUILogicEvent.ShowFloatNotice then
		-- local tipMsg = msg.m_strTips
		-- local function delayShowNotice()
		-- 	local layer = self:InitUI("Common.FloatNoticeUI",AppDef.UIType.PopWindow)
		-- 	if layer ~= nil then 
		-- 	   layer:SetTexts(tipMsg)
		-- 	end
		-- end
		-- Utils:DelayToCallFunc(self.m_pUINode, 0.2,delayShowNotice)

		local layer = self:InitUI("Common.FloatNoticeUI",AppDef.UIType.PopWindow)
		if layer ~= nil then 
		   layer:SetTexts(msg.m_strTips)
		end
	elseif msdId == LUILogicEvent.ShowLabaNotice then
		local tipMsg = msg.m_strTips
--		print("LUILogicEvent.ShowLabaNotice 222222222222222222")
		local function delayShowNotice()
			local layer = self:InitUI("Common.LabaScroolTips", AppDef.UIType.PopWindow)
			if layer ~= nil then 
			   layer:SetTexts(tipMsg)
			end
		end
		Utils:DelayToCallFunc(self.m_pUINode, 0.2,delayShowNotice)
	elseif msdId == LUILogicEvent.ChangeScene then
		self:ChangeScene()
    elseif msdId == LUILogicEvent.ShowItemListUI then
		local layer = self:InitUI("Common.ItemListUI",AppDef.UIType.PopWindow,msg.value)
	elseif msdId == LUILogicEvent.ShowNumInputUI then
		self:InitUI("Common.InputNumUI",AppDef.UIType.MsgBox,msg.value)
	elseif msdId == LUILogicEvent.ShowCommomBtnList then
		self:InitUI("Common.BtnBoxUI",AppDef.UIType.PopWindow,msg.value)
	elseif msdId == LUILogicEvent.ShowFlyItems then
		--抽卡界面不显示飞入效果
		local uilayer = self:GetUIInBuffer("LuckyDraw.LuckyDrawUI")
		if uilayer then
			return
		end

		local flyItems = msg.value
		-- local function delayFlyItems()
		-- 	self:CheckFlyItems(flyItems)
		-- end
		-- Utils:DelayToCallFunc(self.m_pUINode, 0.2,delayFlyItems)
		self:CheckFlyItems(flyItems)
	elseif msdId == LUILogicEvent.TaskAccept then
		self:ShowTaskAcceptEffect()
    elseif msdId == LUILogicEvent.TaskComplete then
    	self:ShowTaskCompleteEffect()
	elseif msdId == LUILogicEvent.InitBagBtnPos then
		self.m_pMainUIBagPos = msg.value
	elseif msdId == LUILogicEvent.InitHeroBtnPos then
		self.m_pMainUIHeroPos = msg.value
	elseif msdId == LUILogicEvent.EnterBattle then
		-- self.m_bIsInBattle = true
		-- self.m_pUINode:setVisible(false)
		self:EnterBattle()
	elseif msdId == LUILogicEvent.ExitBattle then
		self:DoExitBattle()
    elseif  msdId == LUILogicEvent.ShowFiristAwardUI then
        self:InitUI("FirstAward.FristAward",AppDef.UIType.PopWindow,msg.value)
    elseif  msdId == LUILogicEvent.ShowPetInfo then
        self:InitUI("KaPaiPet.PetPreview",AppDef.UIType.PopFirstClassLayer,msg.value)
    elseif  msdId == LUILogicEvent.ShowBestStrong then
        self:InitUI("Common.BestStrongUI",AppDef.UIType.SecondClassLayer)
	elseif msdId == LUILogicEvent.ShowGuide then
		local data = msg.value
		if self.m_bIsInBattle then
			self:InitUIInBattle("Guide.GuideLayer", AppDef.UIType.Guide, data)
		else
			local temp = {
				[GuideDef.StepId.Guide_FuBen] = true,
			    [GuideDef.StepId.Guide_Pet_11] = true,
			    [GuideDef.StepId.Guide_FuBen2_11] = true,
			    [GuideDef.StepId.Guide_FuBen3_11] = true,
			    [GuideDef.StepId.Guide_Equip_10] = true,
			    [GuideDef.StepId.Guide_Pet1_Finish] = true,
			    --------------------------------------------------------------------------
			    [GuideDef.StepId.Guide_Pet_6] = true,
			    [GuideDef.StepId.Guide_FuBen2_4] = true,
			    [GuideDef.StepId.Guide_FuBen3_4] = true,
			    [GuideDef.StepId.Guide_Equip_2] = true,
			    [GuideDef.StepId.Guide_Pet1_2] = true,
			    --------------------------------------------------------------------------
			    [GuideDef.StepId.Guide_Arena_2] = true,
			    [GuideDef.StepId.Guide_XunBao_2] = true,
			    [GuideDef.StepId.Guide_XunBao_9] = true,
			    [GuideDef.StepId.Guide_XunBao_Finish] = true,
			    --------------------------------------------------------------------------
			    [GuideDef.StepId.Guide_Pet_2] = true,
			    [GuideDef.StepId.Guide_Tujian_1] = true,
			}
			if Utils:ToBool(temp[data.stepId]) then
				self:CloseAllPopup()
				Utils:SendMsg(LUIChatEvent.ShowOrCloseChatPanel, false)
			end
			if data.stepId == GuideDef.StepId.Guide_FuBen3_2 then
				Utils:scheduleOnce(function()
		            Utils:DeleteUI("HappyDraw.SingleDrawResultUI")
		        end, 0.3)
		    elseif data.stepId == GuideDef.StepId.Guide_XunBao_6 then
		    	Utils:scheduleOnce(function()
		            Utils:DeleteUI("WanFa.XunBaoResultUI")
		        end, 0.3)
			elseif data.stepId == GuideDef.StepId.Guide_Arena or data.stepId == GuideDef.StepId.Guide_XunBao then
				Utils:scheduleOnce(function()
		            Utils:DeleteUI("FuBenMap.SaoDangResultUI")
		        end, 0.3)
		    elseif data.stepId == GuideDef.StepId.Guide_Tujian_1 then
		    	Utils:scheduleOnce(function()
		            Utils:DeleteUI("FuBenMap.FuBenDetailUI")
		            Utils:DeleteUI("FuBenMap.NormalFuBenUI")
		        end, 0.3)
			end
			self:InitUI("Guide.GuideLayer", AppDef.UIType.Guide, data)
		end
	elseif msdId == LUILogicEvent.HideGuide then
		self:DeleteUI("Guide.GuideLayer")
	elseif msdId == LUILogicEvent.CheckLayerExist then
		local ret = msg.value or {}
		if ret.script then
		    local uilayer = self:GetUIInBuffer(ret.script)
			ret.isExist = (uilayer ~= nil)
		end
	elseif msdId == LUILogicEvent.CanAutoPath then
		msg.value = self:CanAutoPath()
	elseif msdId == LUILogicEvent.CloseAllPopup then
		self:CloseAllPopup({"BangPaiZone.BangPaiZoneUI"})
	elseif msdId == LUILogicEvent.ShowMonsterInfo then
		self:InitUI("Pet.MonsterInfoUI", AppDef.UIType.SecondClassLayer, msg.value)
	elseif msdId == LUILogicEvent.ShowEquipGetUI then
		self:InitUI("PetEquip.EquipGetUI", AppDef.UIType.PopWindow, {msg.value1,msg.value2})
	elseif msdId == LUILogicEvent.CloseHighPopup then
		self:CloseHighPopup(msg.value)	
	end 
end

function LUILogic:CanAutoPath()
	for i = 1, #self.m_pUIBuffer do
		if self.m_pUIBuffer[i] then
			local uilayer = self.m_pUIBuffer[i]["uilayer"]
			local script = self.m_pUIBuffer[i]["luaScript"]
			if uilayer.m_pUILayer:isVisible() then
				if script == "Guide.GuideLayer" or script == "LuckyDraw.LDSingleRetUI" or script == "PreView.OpenCheckUI" or script == "ImproveUI.ShowWingHorseUI" or script == "Recharge.FirstRechargeUI" then
					--dump(script)
					return false
				end
			end
		end
	end
	return true
end

function LUILogic:EnterBattle()
	-- print("--------------------------EnterBattle-------------------------------")
	self.m_bIsInBattle = true
	--self:HideVisibleUI()
	local hasFirstLayer = false
	local hasSecondLayer = false
	for i = 1, #self.m_pUIBuffer do
		if self.m_pUIBuffer[i] then
			local uilayer = self.m_pUIBuffer[i]["uilayer"]
			local script = self.m_pUIBuffer[i]["luaScript"]
			if uilayer ~=nil and uilayer.m_pUILayer:isVisible()
			and script ~= "Common.PowerChangedUI" then
				local isNeedHide = uilayer.IsHideInBattle or false
				if isNeedHide then
					if uilayer.layerType == AppDef.UIType.FirstClassLayer then
						hasFirstLayer = false
					elseif uilayer.layerType == AppDef.UIType.SecondClassLayer then
						hasSecondLayer = false
					end
					uilayer.m_pUILayer:setVisible(false)	
					table.insert(self.m_pHideUIs, self.m_pUIBuffer[i]["luaScript"])
				else
					if uilayer.layerType == AppDef.UIType.FirstClassLayer then
						hasFirstLayer = true
					elseif uilayer.layerType == AppDef.UIType.SecondClassLayer then
						hasSecondLayer = true
					end
				end
			end
		end
	end
	if not hasFirstLayer then
		self.m_pFirstClassBg:SetBgVisible(false,false, false)
	end

	if not hasSecondLayer then
		self.m_pSecondClassBg:SetBgVisible(false,false)
	end


end

function LUILogic:HideUI(luaScript, bool)
	print("==================hide UI====================>", luaScript)
	local uiInd = self:GetUIInBufferInd(luaScript)
	if uiInd == 0 then
		return
	end
	--------print("DeleteUI uiInd",uiInd)

	local uilayer = self.m_pUIBuffer[uiInd]["uilayer"]
	if uilayer ~=nil then
		if uilayer.layerType == AppDef.UIType.FirstClassLayer then
			self.m_pFirstClassBg:SetBgVisible(bool)
		elseif uilayer.layerType == AppDef.UIType.PopFirstClassLayer then
			 self.m_pPopFirstClassBg:SetBgVisible(bool,false)
		elseif uilayer.layerType == AppDef.UIType.SecondClassLayer then
			self.m_pSecondClassBg:SetBgVisible(bool)
		end
		uilayer.m_pUILayer:setVisible(bool)
		if bool then
			table.remove(self.m_pHideUIs,1)
			LGameMsg.m_baseMsg:ChangeEventId(LUIFClassBgEvent.UpdateUI)
			self:SendMsg(LGameMsg.m_baseMsg)
		else
			table.insert(self.m_pHideUIs, self.m_pUIBuffer[uiInd]["luaScript"])
		end
	end
end

--[[
隐藏所有打开的UI
]]
function LUILogic:HideVisibleUI()
	for i = 1, #self.m_pUIBuffer do
		if self.m_pUIBuffer[i] then
			local uilayer = self.m_pUIBuffer[i]["uilayer"]
			local script = self.m_pUIBuffer[i]["luaScript"]
			if uilayer ~=nil 
			and uilayer.m_pUILayer:isVisible()
			and script ~= "Chat.ChatMiniShowLayer"
			and script ~= "Chat.MainChatUI"
			and script ~= "Common.PowerChangedUI"
			and script ~= "Chat.VoiceWindowUI"
			and script ~= "Common.LabaScroolTips"
			and ((self.m_bIsInBattle and script ~= "Guide.GuideLayer") or not self.m_bIsInBattle) then
				----print("script",script)
				uilayer.m_pUILayer:setVisible(false)	
				table.insert(self.m_pHideUIs, self.m_pUIBuffer[i]["luaScript"])
			end
		end
	end
	self.m_pFirstClassBg:SetBgVisible(false,false,false)
	self.m_pPopFirstClassBg:SetBgVisible(false,false,false)
	self.m_pSecondClassBg:SetBgVisible(false,false)
end

--[[
显示之前隐藏的UI
]]
function LUILogic:ReShowHideUI()
	----print("ReShowHideUI")
	-- for i = 1, #self.m_pHideUIs do
	-- 	----print(self.m_pHideUIs[i])
	-- 	local uiInd = self:GetUIInBufferInd(self.m_pHideUIs[i])
	-- 	if uiInd > 0 then
	-- 		local uibuff = self.m_pUIBuffer[uiInd]
	-- 		uibuff["uilayer"].m_pUILayer:setVisible(true)
	-- 		if uibuff["uilayer"].layerType == AppDef.UIType.FirstClassLayer then
	-- 			self.m_pFirstClassBg:SetBgVisible(true)
	-- 		elseif uibuff["uilayer"].layerType == AppDef.UIType.SecondClassLayer then
	-- 			self.m_pSecondClassBg:SetBgVisible(true)
	-- 		end
	-- 	end
	-- end
	-- self.m_pHideUIs = {}
	while #self.m_pHideUIs > 0 do
		local uiInd = self:GetUIInBufferInd(self.m_pHideUIs[1])
		if uiInd > 0 then
			local uibuff = self.m_pUIBuffer[uiInd]
			uibuff["uilayer"].m_pUILayer:setVisible(true)
			if uibuff["uilayer"].layerType == AppDef.UIType.FirstClassLayer then
				self.m_pFirstClassBg:SetBgVisible(true)
			elseif uibuff["uilayer"].layerType == AppDef.UIType.SecondClassLayer then
				self.m_pSecondClassBg:SetBgVisible(true)
			elseif uibuff["uilayer"].layerType == AppDef.UIType.PopFirstClassLayer then
				self.m_pPopFirstClassBg:SetBgVisible(true)
			end
		end
		table.remove(self.m_pHideUIs,1)
	end
end

function LUILogic:DeleteAfterBattleBuff()

	for i,v in ipairs(self.m_pAfterBattleBuff) do
	    if v[3] == 1 then
	        table.remove(self.m_pAfterBattleBuff, i)
	    end
	end
end

function LUILogic:DoExitBattle()
	self.m_bIsInBattle = false
	self:ReShowHideUI()
	------print("self.m_pAfterBattleBuff=",#self.m_pAfterBattleBuff)
	local function DelayShowUI()
		while #self.m_pAfterBattleBuff > 0 do
			local funcName = self.m_pAfterBattleBuff[1][1]
			----print("funcName=",funcName,unpack(self.m_pAfterBattleBuff[i][2]))
			funcName(unpack(self.m_pAfterBattleBuff[1][2]))
			table.remove(self.m_pAfterBattleBuff,1)
		end
		-- for i = 1, #self.m_pAfterBattleBuff do
		-- 	local funcName = self.m_pAfterBattleBuff[i][1]
		-- 	----print("funcName=",funcName,unpack(self.m_pAfterBattleBuff[i][2]))
		-- 	funcName(unpack(self.m_pAfterBattleBuff[i][2]))
		-- end
		--self.m_pAfterBattleBuff = {}
	end
	Utils:DelayToCallFunc(self.m_pUINode, 0.2,DelayShowUI)
end

--[[
显示任务开始效果
]]
function LUILogic:ShowTaskAcceptEffect()
	if self.m_bIsInBattle then
		local function AfterBattleCallback()
			self:ShowTaskAcceptEffect()
		end
		table.insert(self.m_pAfterBattleBuff,{AfterBattleCallback,{},0})
		return
	end


	local function callback(texture)
		local function delayShowEffect()
			local ani = ImodAnim:createWithFileSync("res2/fx/jieshourenwu")
			ani:setPosition(cc.p(AppDef.frameSize.width/2,AppDef.frameSize.height*0.8))
			self.m_pUINode:addChild(ani,AppDef.UIType.WaitLoading)

			local function AniPlayEnd(sender)
				sender:removeFromParent()
			end
			ani:PlayNewAction(0)
			ani:registerScriptEndCBHandler(AniPlayEnd)
		end
		Utils:DelayToCallFunc(self.m_pUINode, 0.2,delayShowEffect)
    end
	AppDef.Director:getTextureCache():addImageAsync("res2/fx/jieshourenwu.png", callback) 
end

--[[
显示任务完成效果
]]
function LUILogic:ShowTaskCompleteEffect()
	if self.m_bIsInBattle then
		local function AfterBattleCallback()
			self:ShowTaskAcceptEffect()
		end
		table.insert(self.m_pAfterBattleBuff,{AfterBattleCallback,{},0})
		return
	end

	local function callback(texture)
		local function delayShowEffect()
			local ani = ImodAnim:createWithFileSync("res2/fx/wancheng")
			ani:setPosition(cc.p(AppDef.frameSize.width/2,AppDef.fraameSize.height*0.8))
			self.m_pUINode:addChild(ani,AppDef.UIType.WaitLoading)

			local function AniPlayEnd(sender)
				sender:removeFromParent()
			end
			ani:PlayNewAction(0)
			ani:registerScriptEndCBHandler(AniPlayEnd)
		end
		Utils:DelayToCallFunc(self.m_pUINode, 0.2,delayShowEffect)
    end
	AppDef.Director:getTextureCache():addImageAsync("res2/fx/wancheng.png", callback) 

	
end

function LUILogic:CheckFlyItems(flyItem)
	--宠物副本内不飞图标（百花、锻造礼盒飞图标延后）
    local sid = LRoleDataMgr.MyHeroInfo.sid
    if sid == 162 or sid == 164 or LRoleDataMgr.m_isShowRandPetUI then 
    	flyItem:Delete()
    	flyItem = nil
        return
    end
	
	if self.m_bIsInBattle then
		local function AfterBattleCallback(flyItem)
			self:CheckFlyItems(flyItem)
		end
		table.insert(self.m_pAfterBattleBuff,{AfterBattleCallback,{flyItem},0})
		return
	end

	local function PopFlyItems()
		if #self.m_pFlyItems == 0 then
			self:DeleteFlyScheduler()
			return
		end
		local data = self.m_pFlyItems[1]
		table.remove(self.m_pFlyItems,1)
		self:ShowFlyItems(data)
		data:Delete()
	end
	if self.m_flyScheduler == nil then
		self.m_flyScheduler = AppDef.Director:getScheduler():scheduleScriptFunc(PopFlyItems, 0.5, false)
	end
	
	table.insert(self.m_pFlyItems,flyItem)
end


function LUILogic:ShowFlyItems(flyData)
	local flyType = flyData.flyType
	local value = flyData.flyValue
	local imgName = nil
	local endPos
	if flyType == LFlyItem.FlyType.Money then
		imgName = "item/equip3006.png"
		endPos = self.m_pMainUIBagPos
	elseif flyType == LFlyItem.FlyType.Item then
		local citem = LItemMgr:getItem(value)
		if citem ~= nil then
		    if (citem.type == 2 or (citem.type >= 7 and citem.type <= 10))then
		        imgName = "res2/Monster_Bust/" .. citem.pic.. "_tou.png"
		    else
		        imgName = string.format("item/equip%d.png",citem.pic)
		    end			
			endPos = self.m_pMainUIBagPos
		end
	elseif flyType == LFlyItem.FlyType.Qianneng then
		imgName = "item/equip3006.png"
		endPos = self.m_pMainUIHeroPos
		LRedDotCheckMgr:MainSkillCheck()
	elseif flyType == LFlyItem.FlyType.XinXiuJingHua then
		imgName = "item/equip3019.png"
		endPos = self.m_pMainUIBagPos
		LRedDotCheckMgr:MainSkillCheck()
	end
	if imgName == nil or endPos == nil then
		return
	end
	local sp = cc.Sprite:create()
	Utils:AsyncLoadImg(sp,imgName)
	--local sp = cc.Sprite:create(imgName)
	if sp == nil then
		return
	end
	self.m_pUINode:addChild(sp,AppDef.UIType.WaitLoading)
	sp:setPosition(cc.p(AppDef.frameSize.width/2,AppDef.frameSize.height/2))
	local moveTo = cc.MoveTo:create(1,endPos)
	local moveEffect = cc.EaseSineInOut:create(moveTo)
	local function FlyEffectEnd(sender)
		--音效
        --LGameMsg.m_audioMsg:Change(LAudioEvent.PlayEffect, AppDef.SysBGM.Get_Itme)
        --self:SendMsg(LGameMsg.m_audioMsg)
        --print("FlyEffectEnd",imgName)
        Utils:UnbindAsyncImg(imgName)
		sender:removeFromParent()
	end
	local func = cc.CallFunc:create(FlyEffectEnd)
	sp:runAction(cc.Sequence:create(moveEffect, func))
end

function LUILogic:DeleteFlyScheduler()
	if self.m_flyScheduler ~= nil then
        --没有了
        AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_flyScheduler)
        self.m_flyScheduler = nil
    end
end

--[[
处理UI跳转地图相关的逻辑
]]
function LUILogic:ChangeScene()
	-- self:CloseAllPopup({"ImproveUI.LItemOrSkillRecvUI"})
	self:DeleteAfterBattleBuff()
end

function LUILogic:SetPlotChatMode(isInPlot)
	if isInPlot == true then
		self:EnterPlotChatMode()		
	else
		self:ExitPlotChatMode()
	end
end

function LUILogic:EnterPlotChatMode()
	------print("EnterPlotChatMode",self.m_bIsInBattle)
	if self.m_bIsInBattle then
		local function AfterBattleCallback()
			self:EnterPlotChatMode()
		end
		table.insert(self.m_pAfterBattleBuff,{AfterBattleCallback,{},1})
		return
	end
	for i = 1,#(self.m_pUIBuffer) do
		if self.m_pUIBuffer[i] then
			if self.m_pUIBuffer[i]["uilayer"].layerType == AppDef.UIType.Plot then
				return
			end
		end
	end
	self:HideVisibleUI()
	-- for i = 1,#(self.m_pUIBuffer) do
	-- 	if self.m_pUIBuffer[i] then
	-- 		if self.m_pUIBuffer[i]["uilayer"].layerType ~= AppDef.UIType.WaitLoading 
	-- 			and self.m_pUIBuffer[i]["uilayer"].layerType ~= AppDef.UIType.MsgBox
	-- 			and self.m_pUIBuffer[i]["uilayer"].layerType ~= AppDef.UIType.Plot then
	-- 			self.m_pUIBuffer[i]["uilayer"].m_pUILayer:setVisible(false)
	-- 		end
	-- 	end
	-- end
	-- self.m_pFirstClassBg:SetBgVisible(false)
	-- self.m_pSecondClassBg:SetBgVisible(false)
end

function LUILogic:ExitPlotChatMode()
	------print("ExitPlotChatMode",self.m_bIsInBattle)
	if self.m_bIsInBattle then
		local function AfterBattleCallback()
			self:ExitPlotChatMode()
		end
		table.insert(self.m_pAfterBattleBuff,{AfterBattleCallback,{},1})
		return
	end
	self:ReShowHideUI()
	-- for i = 1,#(self.m_pUIBuffer) do
	-- 	if self.m_pUIBuffer[i] then
	-- 		if self.m_pUIBuffer[i]["uilayer"].layerType ~= AppDef.UIType.WaitLoading 
	-- 			and self.m_pUIBuffer[i]["uilayer"].layerType ~= AppDef.UIType.MsgBox
	-- 			and self.m_pUIBuffer[i]["uilayer"].layerType ~= AppDef.UIType.Battle then
	-- 			self.m_pUIBuffer[i]["uilayer"].m_pUILayer:setVisible(true)
	-- 			if self.m_pUIBuffer[i]["uilayer"].layerType == AppDef.UIType.FirstClassLayer then
	-- 				self.m_pFirstClassBg:SetBgVisible(true)
	-- 			elseif self.m_pUIBuffer[i]["uilayer"].layerType == AppDef.UIType.SecondClassLayer then
	-- 				self.m_pSecondClassBg:SetBgVisible(true)
	-- 			end
	-- 		end
	-- 	end
	-- end
end

function LUILogic:DeleteUI(luaScript)
	--------print("DeleteUI",luaScript)
	
	local uiInd = self:GetUIInBufferInd(luaScript)
	if uiInd == 0 then
		return
	end
	--------print("DeleteUI uiInd",uiInd)

	local uilayer = self.m_pUIBuffer[uiInd]["uilayer"]
	local isDeleteRes = false
	if uilayer ~=nil then
		if uilayer.layerType == AppDef.UIType.FirstClassLayer then
			local isIsBg = self:DeleteFCBuff(luaScript)
            if not isIsBg then
                self.m_pFirstClassBg:SetBgVisible(false)
            end
			self:ShowLastFCLayer()
			isDeleteRes = true
		elseif uilayer.layerType == AppDef.UIType.PopFirstClassLayer then
			local isIsBg = self:DeletePFCBuff(luaScript)
            if not isIsBg then
                self.m_pPopFirstClassBg:SetBgVisible(false)
            end
			self:ShowLastPFCLayer()
			isDeleteRes = true
		elseif uilayer.layerType == AppDef.UIType.SpecialLayer  or uilayer.layerType == AppDef.UIType.Normal then
			isDeleteRes = true
		elseif uilayer.layerType == AppDef.UIType.SecondClassLayer then
			self.m_pSecondClassBg:SetBgVisible(false)
		end
		if uilayer.isUseResBuffer then
			LGameMsg.m_baseMsgWithOne:Change(LResEvent.UnusedCsb,{uilayer.csbFilePath,uilayer.m_pUILayer})
			self:SendMsg(LGameMsg.m_baseMsgWithOne)
		else
			uilayer.m_pUILayer:removeFromParent()
		end
		
		--uilayer:DeleteUIRes()
		--ModelUI.ShowTopModel()
	end
	self.m_pUIBuffer[uiInd]["uilayer"] = nil
	if self.m_pUIBuffer[uiInd]["luaScript"] then
		local filePath = "View." .. self.m_pUIBuffer[uiInd]["luaScript"]
		--package.loaded[filePath] = nil
		self.m_pUIBuffer[uiInd]["luaScript"] = nil
	end
	table.remove(self.m_pUIBuffer, uiInd)
	if isDeleteRes == true then
		Utils:SendMsg(LResEvent.DeleteUnUsedImg)
		--display.removeUnusedSpriteFrames()
		AppDef.textureCache:removeUnusedTextures()
	end
end

function LUILogic:InitUIInBattle(luaScript,zorder,userData)
	return self:ShowUI(luaScript,zorder,userData)
end

function LUILogic:ShowUI(luaScript,zorder,userData)
	local uilayer = self:GetUIInBuffer(luaScript)
	if uilayer ~=nil then
		if uilayer.UpdateUserData then
			uilayer:UpdateUserData(userData)
		end
		return uilayer
	end

	
	
	if zorder == AppDef.UIType.FirstClassLayer then
		self:HideLastFCLayer()
		self:AddFCBuff(luaScript)
	end
	if zorder == AppDef.UIType.PopFirstClassLayer then
		self:HideLastPFCLayer()
		self:AddPFCBuff(luaScript)
	end
	local uiscript = require("View." .. luaScript)
	uilayer = uiscript:New(userData)

	self.m_pUINode:addChild(uilayer.m_pUILayer,zorder)
	if uilayer.isUseResBuffer then
		uilayer.m_pUILayer:release()
	end
	uilayer.layerType = zorder

	if uilayer.layerType == AppDef.UIType.FirstClassLayer then	
		self.m_pFirstClassBg:SetBgVisible(true)
		--音效
		LGameMsg.m_audioMsg:Change(LAudioEvent.PlayBTEffect, AppDef.SysBGM.Open_UI)
		self:SendMsg(LGameMsg.m_audioMsg)
	elseif uilayer.layerType == AppDef.UIType.PopFirstClassLayer then
		self.m_pPopFirstClassBg:SetBgVisible(true)
		--音效
		LGameMsg.m_audioMsg:Change(LAudioEvent.PlayBTEffect, AppDef.SysBGM.Open_UI)
		self:SendMsg(LGameMsg.m_audioMsg)
	elseif uilayer.layerType == AppDef.UIType.SecondClassLayer then
		self.m_pSecondClassBg:SetBgVisible(true)
	end
	local uibuff = {}
	uibuff["luaScript"] = luaScript
	uibuff["uilayer"] = uilayer
	table.insert(self.m_pUIBuffer, uibuff)

	AppDef.spriteFrameCache:addSpriteFrames("csd/Plist/ui_huobi.plist", "csd/Plist/ui_huobi.png")
	-- AppDef.spriteFrameCache:addSpriteFrames("csd/Plist/ui_mainPlist.plist", "csd/Plist/ui_mainPlist.png")
	return uilayer
end

--[[
显示一个UI
]]
function LUILogic:InitUI(luaScript,zorder,userData,isShowInBattle)
	------print(" LUILogic:InitUI",luaScript,zorder,userData,self.m_bIsInBattle)
	------print("--------------------------InitUI-------------------------------",self.m_bIsInBattle)
    if isShowInBattle == nil then
        isShowInBattle = true
    end
	--isShowInBattle = isShowInBattle or true
	local uiscript = require("View." .. luaScript)
	local hideInBattle = uiscript.IsHideInBattle or false
    if isShowInBattle == false then
        hideInBattle = true
    end
	if hideInBattle and 
		self.m_bIsInBattle and luaScript ~= "MainUI" then

		local function AfterBattleCallback(luaScript,zorder,userData)
			self:InitUI(luaScript,zorder,userData)
		end
		table.insert(self.m_pAfterBattleBuff,{AfterBattleCallback,{luaScript,zorder,userData},0})
		return
	end
	local layer = self:ShowUI(luaScript,zorder,userData)
	if self.m_bIsInBattle and luaScript == "MainUI" then
		local uiInd = self:GetUIInBufferInd(luaScript)
		local uilayer = self.m_pUIBuffer[uiInd]["uilayer"]
		local script = self.m_pUIBuffer[uiInd]["luaScript"]

		uilayer.m_pUILayer:setVisible(false)	
		table.insert(self.m_pHideUIs, self.m_pUIBuffer[uiInd]["luaScript"])
	end
	return layer
end

function LUILogic:ShowLastPFCLayer()
	if #self.m_pPFCBuff == 0 then
		return
	end
	local script = self.m_pPFCBuff[#self.m_pPFCBuff][1]
	--[[
	主动隐藏的UI不显示出来
	]]
	-- if self:IsInHideList(script) then
	-- 	return
	-- end
	local uilayer = self:GetUIInBuffer(script)
	if uilayer ~= nil then
		local data = self.m_pPFCBuff[#self.m_pPFCBuff][2]
		if data ~= nil then
			uilayer.m_pUILayer:setVisible(true)
			self.m_pPopFirstClassBg:SetBgVisible(true)
			self.m_pPopFirstClassBg:ResetBgData(data)
			if uilayer.OnEnter then
				uilayer:OnEnter()
			end
			self.m_pPFCBuff[#self.m_pPFCBuff][2] = nil
		end

		if self.m_bIsInBattle then
			local isNeedHide = uilayer.IsHideInBattle or false
			if isNeedHide then
				if uilayer.layerType == AppDef.UIType.FirstClassLayer then
					self.m_pFirstClassBg:SetBgVisible(false,false)
				elseif uilayer.layerType == AppDef.UIType.PopFirstClassLayer then
					self.m_pPopFirstClassBg:SetBgVisible(false,false)
				elseif uilayer.layerType == AppDef.UIType.SecondClassLayer then
					self.m_pSecondClassBg:SetBgVisible(false,false)
				end

				uilayer.m_pUILayer:setVisible(false)	
				table.insert(self.m_pHideUIs, script)
			end
		end
	end
end

function LUILogic:ShowLastFCLayer()
	if #self.m_pFCBuff == 0 then
		return
	end
	local script = self.m_pFCBuff[#self.m_pFCBuff][1]
	--[[
	主动隐藏的UI不显示出来
	]]
	-- if self:IsInHideList(script) then
	-- 	return
	-- end
	local uilayer = self:GetUIInBuffer(script)
	if uilayer ~= nil then
		local data = self.m_pFCBuff[#self.m_pFCBuff][2]
		if data ~= nil then
			uilayer.m_pUILayer:setVisible(true)
			self.m_pFirstClassBg:SetBgVisible(true)
			self.m_pFirstClassBg:ResetBgData(data)
			if uilayer.OnEnter then
				uilayer:OnEnter()
			end
			self.m_pFCBuff[#self.m_pFCBuff][2] = nil
		end

		if self.m_bIsInBattle then
			local isNeedHide = uilayer.IsHideInBattle or false
			if isNeedHide then
				if uilayer.layerType == AppDef.UIType.FirstClassLayer then
					self.m_pFirstClassBg:SetBgVisible(false,false)
				elseif uilayer.layerType == AppDef.UIType.PopFirstClassLayer then
					self.m_pPopFirstClassBg:SetBgVisible(false,false)
				elseif uilayer.layerType == AppDef.UIType.SecondClassLayer then
					self.m_pSecondClassBg:SetBgVisible(false,false)
				end

				uilayer.m_pUILayer:setVisible(false)	
				table.insert(self.m_pHideUIs, script)
			end
		end
	end
end

--[[
是否在隐藏列表中
战斗中关闭一个一级界面后显示上个一级界面的时候判断一下在不在隐藏列表
在隐藏列表就不显示出来
]]
function LUILogic:IsInHideList(luaScript)
	for i = 1, #self.m_pHideUIs do
		----print(self.m_pHideUIs[i])
		if self.m_pHideUIs[i] == luaScript then
			return true
		end
	end
	return false
end

function LUILogic:DeleteUIInHideUIs(luaScript)
	for i = 1, #self.m_pHideUIs do
		if self.m_pHideUIs[i] == luaScript then
			table.remove(self.m_pHideUIs,i)
			return
		end
	end
end

function LUILogic:CloseFCLayer()
end

function LUILogic:HideLastPFCLayer()
	if #self.m_pPFCBuff == 0 then
		return
	end
	local script = self.m_pPFCBuff[#self.m_pPFCBuff][1]

	local uilayer = self:GetUIInBuffer(script)
	if uilayer ~= nil then
		self:DeleteUIInHideUIs(script)
		uilayer.m_pUILayer:setVisible(false)
		local data = {}
		local v1,v2,v3,v4,v5 = self.m_pPopFirstClassBg:GetBgData()
		table.insert(data,v1)
		table.insert(data,v2)
		table.insert(data,v3)
		table.insert(data,v4)
		table.insert(data,v5)
		self.m_pPFCBuff[#self.m_pPFCBuff][2] = data
		self.m_pPopFirstClassBg:SetBgVisible(false)
	end
end

function LUILogic:AddPFCBuff(luaScript)
	for i = 1,#self.m_pPFCBuff do
		if self.m_pPFCBuff[i] == luaScript then
			table.remove(self.m_pPFCBuff,i)
			break
		end
	end
	table.insert(self.m_pPFCBuff,{luaScript})
end


function LUILogic:HideLastFCLayer()
	if #self.m_pFCBuff == 0 then
		return
	end
	local script = self.m_pFCBuff[#self.m_pFCBuff][1]

	local uilayer = self:GetUIInBuffer(script)
	if uilayer ~= nil then
		self:DeleteUIInHideUIs(script)
		uilayer.m_pUILayer:setVisible(false)
		local data = {}
		local v1,v2,v3,v4,v5 = self.m_pFirstClassBg:GetBgData()
		table.insert(data,v1)
		table.insert(data,v2)
		table.insert(data,v3)
		table.insert(data,v4)
		table.insert(data,v5)
		self.m_pFCBuff[#self.m_pFCBuff][2] = data
		self.m_pFirstClassBg:SetBgVisible(false)
	end
end

function LUILogic:AddFCBuff(luaScript)
	for i = 1,#self.m_pFCBuff do
		if self.m_pFCBuff[i] == luaScript then
			table.remove(self.m_pFCBuff,i)
			break
		end
	end
	table.insert(self.m_pFCBuff,{luaScript})
end

--[[
删除一级UI缓存
return:是
]]

function LUILogic:DeleteFCBuff(luaScript)
    local isInBg = false--是否在缓存里面
	for i = 1,#self.m_pFCBuff do
		if self.m_pFCBuff[i][1] == luaScript then
            if self.m_pFCBuff[i][2] ~= nil then
                isInBg = true
            end
			table.remove(self.m_pFCBuff,i)
			return isInBg
		end
	end
    return isInBg
end

--[[
删除一级UI缓存
return:是
]]

function LUILogic:DeletePFCBuff(luaScript)
    local isInBg = false--是否在缓存里面
	for i = 1,#self.m_pPFCBuff do
		if self.m_pPFCBuff[i][1] == luaScript then
            if self.m_pPFCBuff[i][2] ~= nil then
                isInBg = true
            end
			table.remove(self.m_pPFCBuff,i)
			return isInBg
		end
	end
    return isInBg
end

function LUILogic:GetUIInBufferInd(luaScript)
	for i = 1,#(self.m_pUIBuffer) do
		if self.m_pUIBuffer[i]["luaScript"] == luaScript then
			return i
		end
	end
	return 0
end

--[[
检查要显示的UI在不在加载队列中
]]
function LUILogic:GetUIInBuffer(luaScript)
	for i = 1,#(self.m_pUIBuffer) do
		if self.m_pUIBuffer[i]["luaScript"] == luaScript then
			return self.m_pUIBuffer[i]["uilayer"]
		end
	end
	return nil
end

function LUILogic:CloseAllPopup(ignoreList)
	ignoreList = ignoreList or {}
	local startInd = 1
	local function CheckDeleteUI()
		local needCheck = false
		for i = startInd,#(self.m_pUIBuffer) do
			needCheck = false
			if self.m_pUIBuffer[i] then
				if self.m_pUIBuffer[i]["uilayer"].layerType == AppDef.UIType.FirstClassLayer
					or self.m_pUIBuffer[i]["uilayer"].layerType == AppDef.UIType.PopFirstClassLayer
					or self.m_pUIBuffer[i]["uilayer"].layerType == AppDef.UIType.SpecialLayer
					or self.m_pUIBuffer[i]["uilayer"].layerType == AppDef.UIType.SecondClassLayer
					or self.m_pUIBuffer[i]["uilayer"].layerType == AppDef.UIType.ThirdClassLayer
					or self.m_pUIBuffer[i]["uilayer"].layerType == AppDef.UIType.PopWindow 
					then
					local luaScript = self.m_pUIBuffer[i]["luaScript"]
					if not Utils:containValue(ignoreList, luaScript) then
						local uilayer = self.m_pUIBuffer[i]["uilayer"]
						if uilayer ~=nil then
							if uilayer.isUseResBuffer then
								LGameMsg.m_baseMsgWithOne:Change(LResEvent.UnusedCsb,{uilayer.csbFilePath,uilayer.m_pUILayer})
								self:SendMsg(LGameMsg.m_baseMsgWithOne)
							else
								uilayer.m_pUILayer:removeFromParent()
							end
							--uilayer.m_pUILayer:removeFromParent()
						end
						if self.m_pUIBuffer[i]["uilayer"].layerType == AppDef.UIType.FirstClassLayer then
							self:DeleteFCBuff(self.m_pUIBuffer[i]["luaScript"])
						elseif self.m_pUIBuffer[i]["uilayer"].layerType == AppDef.UIType.PopFirstClassLayer then
							self:DeletePFCBuff(self.m_pUIBuffer[i]["luaScript"])
						end
						
						self.m_pUIBuffer[i]["uilayer"] = nil
						self.m_pUIBuffer[i]["luaScript"] = nil
						table.remove(self.m_pUIBuffer, i)
						startInd = i
						needCheck = true
						break
					end
				elseif self.m_pUIBuffer[i]["uilayer"].layerType == AppDef.UIType.MsgBox then
					self.m_pUIBuffer[i]["uilayer"].m_pUILayer:setVisible(false)
				end
			end
		end
		if needCheck then
			CheckDeleteUI()
		end
	end
	CheckDeleteUI()
	self.m_pFirstClassBg:SetBgVisible(false)
	self.m_pPopFirstClassBg:SetBgVisible(false)
	self.m_pSecondClassBg:SetBgVisible(false)
end

function LUILogic:CloseHighPopup(layerType)
	ignoreList = ignoreList or {}
	local startInd = 1
	local function CheckDeleteUI()
		local needCheck = false
		for i = startInd,#(self.m_pUIBuffer) do
			needCheck = false
			if self.m_pUIBuffer[i] then
				if self.m_pUIBuffer[i]["uilayer"].layerType > layerType then
					if self.m_pUIBuffer[i]["uilayer"].layerType == AppDef.UIType.MsgBox then
						self.m_pUIBuffer[i]["uilayer"].m_pUILayer:setVisible(false)
					else
						local luaScript = self.m_pUIBuffer[i]["luaScript"]
						local uilayer = self.m_pUIBuffer[i]["uilayer"]
						if uilayer ~=nil then
							if uilayer.isUseResBuffer then
								LGameMsg.m_baseMsgWithOne:Change(LResEvent.UnusedCsb,{uilayer.csbFilePath,uilayer.m_pUILayer})
								self:SendMsg(LGameMsg.m_baseMsgWithOne)
							else
								uilayer.m_pUILayer:removeFromParent()
							end
							--uilayer.m_pUILayer:removeFromParent()
						end
						if self.m_pUIBuffer[i]["uilayer"].layerType == AppDef.UIType.FirstClassLayer then
							self:DeleteFCBuff(self.m_pUIBuffer[i]["luaScript"])
						elseif self.m_pUIBuffer[i]["uilayer"].layerType == AppDef.UIType.PopFirstClassLayer then
							self:DeletePFCBuff(self.m_pUIBuffer[i]["luaScript"])
						end
						
						self.m_pUIBuffer[i]["uilayer"] = nil
						self.m_pUIBuffer[i]["luaScript"] = nil
						table.remove(self.m_pUIBuffer, i)
						startInd = i
						needCheck = true
						break
					
					end
				end
			end
		end
		if needCheck then
			CheckDeleteUI()
		end
	end
	CheckDeleteUI()
	if layerType < AppDef.UIType.FirstClassLayer then
		self.m_pFirstClassBg:SetBgVisible(false)
	end
	if layerType < AppDef.UIType.PopFirstClassLayer then
		self.m_pPopFirstClassBg:SetBgVisible(false)
	end
	if layerType < AppDef.UIType.SecondClassLayer then
		self.m_pSecondClassBg:SetBgVisible(false)
	end
end
LUILogic:Init()