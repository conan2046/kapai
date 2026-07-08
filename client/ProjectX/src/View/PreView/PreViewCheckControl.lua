local PreViewCheckControl = LUIBase:New()
PreViewCheckControl.__index = PreViewCheckControl
---------------------------------------------------
local m_previewId = 0 --当前预告
local m_completeIds = {} --已完成预告
local m_openFunctions = {} --已开启功能
local m_showFunctions = {} --已打开功能

local LEVELUP = 1--等级达到
local TASK = 2--任务完成
local LOGIN = 3--登录礼包领取
---------------------------------------------------	
function PreViewCheckControl:New(pBtn)
    local o = {}
    setmetatable(o, PreViewCheckControl)
    o:Init(pBtn)
    return o
end
---------------------------------------------------
function PreViewCheckControl:Init(pBtn)
	self.Script = "PreView.PreViewCheckControl"
	self.m_haveGetNetData = false
	-----------------------------------------------
	self.m_pUILayer = cc.Node:create()
	local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
	self.m_pBtn = pBtn
	if self.m_pBtn ~= nil then
		self.m_pBtn:retain()
		self.m_pBtn:setTag(0)
		self.m_pBtn:addClickEventListener(handler(self, PreViewCheckControl.ClickBtn))
		self:MarkIntaractCObj(self.m_pBtn)
		self.m_pBtn:setVisible(false)
	end
	-----------------------------------------------
	self:UpdatePreviewID(LUserConfigMgr:GetUserPreView())
	self:RegistMsgs()
	self:checkAllPreView()
	self:checkAllFunction(true, LEVELUP)
	self:ChangeMapSuccess()
end

function PreViewCheckControl:onExit()
    self:Destory()
    self.m_pUILayer = nil
	m_completeIds = nil
	m_completeIds = {}
	m_openFunctions = nil
	m_openFunctions = {}
	m_showFunctions = nil
	m_showFunctions = {}
	if self.m_pBtn ~= nil then
		self.m_pBtn:release()
		self.m_pBtn = nil
	end
	self.m_haveGetNetData = false
end
-------------------------------------
function PreViewCheckControl:RegistMsgs()
    self.msgIds = {
    	LUIRoleDataChangeEvent.LvUp,
    	LUIPetEvent.GotPetList,
    	LUIWingDataEvent.GetWingList,
    	LUIHorseEvent.GotHorseList,
    	LUIShenQiEvent.GotShenQiList,
    	LUIPetEvent.GetPet,
    	LUIShenQiEvent.ShenQiStateChanged,
    	LUIHorseEvent.HorseListChange,
    	LUIWingDataEvent.GotNewWing,
    	LUIFunctionEvent.GetFuncOpen,
    	LUITaskDataEvent.DeleteOneTask,
    	LUIMapEvent.ChangeMapSuccess,
    	LUILogicEvent.GetSettingStringInfo,
    	LUIRoleDataChangeEvent.ChangeUser,
    	LUIFunctionEvent.FunctionFly,
    	LUIFunctionEvent.GetFuncOpenList,
    }

    self:RegistSelf(self, self.msgIds)
end
-------------------------------------
function PreViewCheckControl:ProcessEvent(msg)
	if msg.msgId == LUIRoleDataChangeEvent.LvUp then
		self:checkAllPreView()
		self:checkAllFunction(false, LEVELUP)
	elseif msg.msgId == LUIPetEvent.GetPet then
		self:checkAllPreView()
		self:checkAllFunction(false, AppDef.AwrdItem.AWRD_ITEM_PET)
	elseif msg.msgId == LUIHorseEvent.HorseListChange then
		self:checkAllPreView()
		self:checkAllFunction(false, AppDef.AwrdItem.AWRD_ITEM_HORSE)
	elseif msg.msgId == LUIShenQiEvent.ShenQiStateChanged then
		self:checkAllPreView()
		self:checkAllFunction(false, AppDef.AwrdItem.AWRD_ITEM_ARTIFACT)
	elseif msg.msgId == LUIWingDataEvent.GotNewWing then
		self:checkAllPreView()
		self:checkAllFunction(false, AppDef.AwrdItem.AWRD_ITEM_WINDS)
	elseif msg.msgId == LUIPetEvent.GotPetList then
		self:checkAllPreView()
		self:checkAllFunction(true, AppDef.AwrdItem.AWRD_ITEM_PET)
	elseif msg.msgId == LUIWingDataEvent.GetWingList then
		self:checkAllPreView()
		self:checkAllFunction(true, AppDef.AwrdItem.AWRD_ITEM_WINDS)
	elseif msg.msgId == LUIHorseEvent.GotHorseList then
		self:checkAllPreView()
		self:checkAllFunction(true, AppDef.AwrdItem.AWRD_ITEM_HORSE)
	elseif msg.msgId == LUIShenQiEvent.GotShenQiList then
		self:checkAllPreView()
		self:checkAllFunction(true, AppDef.AwrdItem.AWRD_ITEM_ARTIFACT)
	elseif msg.msgId == LUIFunctionEvent.GetFuncOpen then
		self:getFuncOpen(msg.value)
	elseif msg.msgId == LUITaskDataEvent.DeleteOneTask then
		self:checkAllPreView()
		self:checkAllFunction(false, TASK)
	elseif msg.msgId == LUIMapEvent.ChangeMapSuccess then
		self:ChangeMapSuccess()
	elseif msg.msgId == LUILogicEvent.GetSettingStringInfo then
		self:dealServerData()
	elseif msg.msgId == LUIRoleDataChangeEvent.ChangeUser then
		self.m_haveGetNetData = false
		local _ = self.m_pBtn and self.m_pBtn:setTag(0)
	elseif msg.msgId == LUIFunctionEvent.FunctionFly then
		local fid = msg.value
		if fid then
			m_showFunctions[fid] = nil
		end
	elseif msg.msgId == LUIFunctionEvent.GetFuncOpenList then
        msg.value = msg.value or {}
        for k,v in pairs(m_showFunctions) do
        	if k and v then
        		msg.value[k] = true
        	end
        end
	end
end
-------------------------------------
function PreViewCheckControl:dealServerData()
	if self.m_haveGetNetData then
		return
	end
	local index = LRoleDataMgr:GetSettingStringConfig(AppDef.ServerSetIndex.SSI_CUR_PRE_FUNC)
	self:UpdatePreviewID(index)
	self.m_haveGetNetData = true
	self:checkAllPreView()
end
-------------------------------------
function PreViewCheckControl:UpdatePreviewID(index)
	m_previewId = m_previewId or 0
	if index and #index > 0 then
		local idx = tonumber(index)
		m_previewId = math.max(m_previewId, idx)
	end
end
-------------------------------------
function PreViewCheckControl:checkAllFunction(isInit, cType)
	local functios = LDataConstMgr:GetFLDataByCondition(cType)
	local newOpen = {}
	local allNewOpen = {}
	local allNotShowNewOpen = {}
	for k,v in pairs(functios) do
		local id = v
		local info = LDataConstMgr:GetFunctionLevelData(id)
		local isOpened = Utils:ToBool(m_openFunctions[id])
		-- print('isOpened->', isOpened, k)
		if not isOpened then
			if PreViewCheckControl.isMeetCompleteCondition(id) then
				m_openFunctions[id] = true
				if Utils:ToBool(info.OPEN_TIPS) then
					table.insert(newOpen, id)
				else
					table.insert(allNotShowNewOpen, id)
				end
				table.insert(allNewOpen, id)
			end
		end
	end

    -- dump(newOpen, 'newOpen->')
    -- dump(m_openFunctions, 'm_openFunctions->')
    -- print('myLevel->', LRoleDataMgr.MyHeroInfo.level)
    -- print('isInit-->', isInit)
    if LRoleDataMgr.m_bIsCrossServer then
    	local buffer = {
    		[AppDef.EModuleID.EMID_BANGPAI] = true,
    		[AppDef.EModuleID.EMID_JINGJI] = true,
    		[AppDef.EModuleID.EMID_HUODONG] = true,
    	}
    	local index = 1
    	for i=1,#newOpen do
    		if newOpen[index] and buffer[newOpen[index]] then
    			table.remove(newOpen, index)
    		else
    			index = index + 1
    		end
    	end
    end
	if (not Utils:ToBool(isInit)) and (#newOpen > 0) then
		for i=1,#newOpen do
			m_showFunctions[newOpen[i]] = true
		end
	    -- Utils:InitUI("PreView.OpenCheckUI",AppDef.UIType.PopWindow, newOpen)
	end
    Utils:SendMsg(LUIFunctionEvent.FunctionOpen, {m_openFunctions, isInit, newOpen, allNewOpen, allNotShowNewOpen}, true)
    if (not Utils:ToBool(isInit)) and #allNotShowNewOpen > 0 then
    	if self.m_soundDelay then
    		self.m_pUILayer:stopAction(self.m_soundDelay)
    	end
    	self.m_soundDelay = performWithDelay(self.m_pUILayer, function(sender)
    		self.m_soundDelay = nil
    		self:playSound(allNotShowNewOpen)
    	end, 1.5)
    end
end
-------------------------------------
function PreViewCheckControl:checkAllPreView()
	if not self.m_haveGetNetData then
		return
	end
	local cfg = LDataConstMgr:GetNovicePreviewConfig()
	local isFind = false
	for i=1,#cfg do
		local item = cfg[i]
		if item then
			local ret = self:checkById(item.id)
			if ret == 2 or item.id < m_previewId then
				m_completeIds[item.id] = true
			elseif ret == 1 then
				m_previewId = item.id
				isFind = true
				break
			end
		end
	end
	self:UpdatePreView(isFind)
end

function PreViewCheckControl:UpdatePreView(isFind)
	if self.m_pBtn == nil then
		return
	end
	
	if (not isFind) then
		self.m_pBtn:setTag(0)
		self.m_pBtn:setVisible(false)
		return
	end

	local id = m_previewId

	if id == self.m_pBtn:getTag() then
		return
	end
	if id <= 0 then
		self.m_pBtn:setTag(id)
		self.m_pBtn:setVisible(false)
		return
	end

	local index = LRoleDataMgr:GetSettingStringConfig(AppDef.ServerSetIndex.SSI_CUR_PRE_FUNC)
	local numIndex = index and tonumber(index) or 0
	do
		local str = tostring(id)
		if numIndex and numIndex < id then
			LRoleDataMgr:SetSettingStringConfig(AppDef.ServerSetIndex.SSI_CUR_PRE_FUNC, str)
			if self.m_haveGetNetData then
				LuaNetSendMsg:QuerySetSettingInfo(AppDef.ServerSetIndex.SSI_CUR_PRE_FUNC, str)
			end
		end
		LUserConfigMgr:SetUserPreView(str)
	end
	
	local config = LDataConstMgr:GetNovicePreviewData(id)
	if config == nil then
		self.m_pBtn:setVisible(false)
		return
	end

	local pTitle = self.m_pBtn:getChildByName("Title")
	pTitle:setString(config.name)

	local pCondition = self.m_pBtn:getChildByName("Condition")
	pCondition:setString(config.desc)

	local pNode = self.m_pBtn:getChildByName("Node")
	pNode:removeAllChildren()
	self:ShowNode(pNode, config)
	self.m_pBtn:setTag(id)

	local isShow = (LRoleDataMgr.MyHeroInfo.SceneType == AppDef.SceneType.MSI_NORMAL)
	self.m_pBtn:setVisible(isShow)
end

function PreViewCheckControl:ShowNode(pParent, config)
	local iconConfig = config.icon
	local iType = iconConfig[1]
	local iValue = iconConfig[2]
	if iType == 1 then--道具
		local path = string.format(AppDef.GUIRes.Res_Item_Path, iValue)
		local sp = cc.Sprite:create(path)
		if sp then
			pParent:addChild(sp)
		else
			Utils:Debug("ERROR Item!!!!!", iconConfig)
		end
	elseif iType == 2 then--图片
		local sp = cc.Sprite:createWithSpriteFrameName(iValue)
		if sp then
			sp:setAnchorPoint(cc.p(0.5, 0))
			pParent:addChild(sp)
		else
			Utils:Debug("ERROR picture!!!!!", iValue)
		end
	elseif iType == 3 then--碎图
		local sp = cc.Sprite:create(iValue)
		if sp then
			sp:setAnchorPoint(cc.p(0.5, 0))
			pParent:addChild(sp)
		else
			Utils:Debug("ERROR picture!!!!!", iValue)
		end
	elseif iType == AppDef.AwrdItem.AWRD_ITEM_PET then--宠物
		local pData = LDataConstMgr:GetPetData(iValue)
		if pData and pData.pic then
			local pAnim = ModelAniNode:create(AppDef.CEnum.ModelAniType.Monster, 0)
			pAnim:InitAni(AppDef.CEnum.ModelAniType.Monster, pData.pic)
		    pAnim:PlayStand(0)
		    pParent:addChild(pAnim)
		end
	elseif iType == AppDef.AwrdItem.AWRD_ITEM_HORSE then--坐骑
		local pAnim = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, 0)
		pAnim:InitAni(AppDef.CEnum.ModelAniType.Hero,0,0,0,0,iValue,0)
		pParent:addChild(pAnim)
	elseif iType == AppDef.AwrdItem.AWRD_ITEM_WINDS then--翅膀
		local pAnim = ModelAniNode:create(AppDef.CEnum.ModelAniType.Wing, 0)
		pAnim:InitAni(AppDef.CEnum.ModelAniType.Wing,0,0,0,iValue,0,0)
		pAnim:PlayStand(0)
		pParent:addChild(pAnim)
	elseif iType == AppDef.AwrdItem.AWRD_ITEM_ARTIFACT then--神器
		local pAnim = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, 0)
		pAnim:InitAni(AppDef.CEnum.ModelAniType.Hero,0,0,0,0,0,iValue)
		pAnim:setPosition(cc.p(30, -90))
		pParent:addChild(pAnim)
	end
end
--[[
预告根据Id检测
]]
-------------------------------------
function PreViewCheckControl:checkById(id)
	if PreViewCheckControl.isMeetOpenCondition(id) then
		if PreViewCheckControl.isPreComplete(id) then
			return 2--已开启，已完成
		else
			return 1--已开启，未完成
		end
	end
	return 0--未开启
end
--[[
功能是否开启
]]
function PreViewCheckControl.isMeetOpenCondition(id)
	local myLevel = LRoleDataMgr.MyHeroInfo.level
	local config = LDataConstMgr:GetNovicePreviewData(id)
	local openCondition = config.open_condition
	local rets = {}
	for i=1,#openCondition do
		local cType = openCondition[i].cType
		local cValue = openCondition[i].cValue
		if cType == LEVELUP then
			table.insert(rets, myLevel >= cValue)
		end
		if cType == TASK then
			table.insert(rets, Utils:ToBool(m_completeIds[cValue]))
		end
	end
	local ret = true
	for i=1,#rets do
		ret = ret and rets[i]
		if not ret then
			break
		end
	end
	return ret
end
--[[
是否存在此物品
]]
function PreViewCheckControl.isHaveItem(iType, iValue)
	if iType == AppDef.AwrdItem.AWRD_ITEM_PET then--怪物
		local petList = LRoleDataMgr.Pet.petlist
		if petList then
			for i=1,#petList do
				if petList[i].id == iValue then
					return true
				end
			end
		end
	elseif iType == AppDef.AwrdItem.AWRD_ITEM_HORSE then--坐骑
		local myHorse = LRoleDataMgr.MyHeroInfo.Horse
		if myHorse then
			for i=1,#myHorse do
				if myHorse[i].id == iValue then
					return true
				end
			end
		end
	elseif iType == AppDef.AwrdItem.AWRD_ITEM_WINDS then--翅膀
		local myWing = LRoleDataMgr.MyHeroInfo.MyChiBangVec
		if myWing then
			for i=1,#myWing do
				if myWing[i][1] == iValue then
					return myWing[i][2]
				end
			end
		end
	elseif iType == AppDef.AwrdItem.AWRD_ITEM_ARTIFACT then--神器
		local myShenQi = LRoleDataMgr:GetShenQiDataById(iValue)
		return (myShenQi and {myShenQi.state > 0} or {false})[1]
	end
	return false
end
--[[
整合结果
]]
function PreViewCheckControl.getRet(rets, isAnd)
	if rets == nil then
		return false
	end
	local ret = false
	if isAnd then
		ret = true
		for i=1,#rets do
			ret = ret and rets[i][2]
			if not ret then
				break
			end
		end
	else
		ret = false
		for i=1,#rets do
			ret = ret or rets[i][2]
			if ret then
				break
			end
		end
	end
	-- print('ret->', ret)
	return ret
end
--[[
根据条件获取结果
]]
function PreViewCheckControl.getRetsByCondition(condition)
	if condition == nil then
		return nil
	end
	local myLevel = LRoleDataMgr.MyHeroInfo.level
	local rets = {}
	for i=1,#condition do
		local cType = condition[i][1]
		local cValue = condition[i][2]
		if cType == LEVELUP then
			table.insert(rets, {cType, myLevel >= cValue, cValue})
		elseif cType == TASK then
			table.insert(rets, {cType, LRoleDataMgr.Task:isTaskComplete(cValue), cValue})
		elseif cType == LOGIN then
			local isHaveGet = LRoleDataMgr.MyHeroInfo:IsLoginGiftHaveGet(cValue)
			table.insert(rets, {cType, isHaveGet, cValue})
		else
			local isHaveItem = PreViewCheckControl.isHaveItem(cType, cValue)
			table.insert(rets, {cType, isHaveItem, cValue})
		end
	end
	return rets
end

--[[
预告是否完成
]]
function PreViewCheckControl.isPreComplete(id)
	local config = LDataConstMgr:GetNovicePreviewData(id)
	if config == nil then
		return false
	end
	if m_completeIds[id] then
		return true
	end
	local rets = PreViewCheckControl.getRetsByCondition(config.condition)
	local ret = PreViewCheckControl.getRet(rets, false)
	-- print('ret->', ret)
	return ret
end
--[[
功能是否开启
]]
function PreViewCheckControl.isMeetCompleteCondition(functionId)
	if m_openFunctions == nil then
		return false
	end
	
	local ret = Utils:ToBool(m_openFunctions[functionId])
	if ret then
		return true
	end
	local config = LDataConstMgr:GetFunctionLevelData(functionId)
	if config == nil then
		return false, nil, nil
	end
	local rets = PreViewCheckControl.getRetsByCondition(config.open_condition)
	local ret = PreViewCheckControl.getRet(rets, Utils:ToBool(config.type))
	-- print('ret->', ret)
	local limitType = nil
	local limitValue = nil
	if not ret then
		for i=1,#rets do
			if not rets[i][2] then
				limitType = rets[i][1]
				limitValue = rets[i][3]
				break
			end
		end
	end
	return ret,limitType,limitValue
end

function PreViewCheckControl:ClickBtn(sender)
	local tag = sender:getTag()
	if tag and tag > 0 then
	    Utils:InitUI("PreView.PreViewDetailUI",AppDef.UIType.PopWindow, tag)
	end
end

function PreViewCheckControl:getFuncOpen(ret)
	-- dump(m_openFunctions)
	-- dump(ret)
	if type(ret) == "table" then
		ret.open = Utils:ToBool(m_openFunctions[ret.id])
	end
end

function PreViewCheckControl:ChangeMapSuccess()
	if self.m_pBtn and self.m_pBtn:getTag() > 0 then
		local isShow = (LRoleDataMgr.MyHeroInfo.SceneType == AppDef.SceneType.MSI_NORMAL)
		self.m_pBtn:setVisible(isShow)
	end
end

function PreViewCheckControl:playSound(list)
	local function _checkSingle(fid)
		local cfg = LDataConstMgr:GetFunctionLevelData(fid)
		if cfg == nil or cfg.sound == nil or #cfg.sound == 0 then
			return
		end
		LGameMsg.m_audioMsg:Change(LAudioEvent.PlayEffect, cfg.sound)
		self:SendMsg(LGameMsg.m_audioMsg)
	end

	for i=1,#list do
		_checkSingle(list[i])
	end
end

---------------------------------------------------
return PreViewCheckControl