local FengShenShiLianUI = LUIBase:New()
FengShenShiLianUI.__index = FengShenShiLianUI

local animConfig = {
    [1] = {
        pos = {{x=517, y=425},{x=230, y=425},{x=150, y=425}},
        scale = {1,0.5},
    },
    [2] = {
        pos = {{x=917, y=425},{x=800, y=425},{x=517, y=425}},
        scale = {0.5,1},
    },
    [3] = {
        pos = {{x=517, y=462.5},{x=800, y=442.5},{x=917, y=425}},
        scale = {0.3,0.5},
        opacity = {51,255},
    },
    [4] = {
        pos = {{x=150, y=425},{x=350, y=445},{x=517, y=462.5}},
        scale = {0.5,0.3},
        opacity = {255,51},
    }
}

FengShenShiLianUI.IsHideInBattle = true

function FengShenShiLianUI:New(initTab)
    local o = {}
    setmetatable(o, FengShenShiLianUI)
    o:Init(initTab)
    return o
end

function FengShenShiLianUI:RegistMsgs()
    self.msgIds = 
    {
        LUIFengShenEvent.LoadDataEvent,
		LUIFengShenEvent.TiaoZhanDataEvent,
		LUIFengShenEvent.SaoDangDataEvent,
		LUIRedDotEvent.SetRedDotState,
    }
    self:RegistSelf(self, self.msgIds)
end

function FengShenShiLianUI:ProcessEvent(msg)
    if msg.msgId == LUIFengShenEvent.LoadDataEvent then
        --self:LoadData(msg.value)
        --self.m_isInit = false
	elseif msg.msgId == LUIFengShenEvent.TiaoZhanDataEvent then
		self:UpdateTiaoZhanData(msg.value)
	elseif msg.msgId == LUIFengShenEvent.SaoDangDataEvent then
		self:UpdateSaoDangData(msg.value)
	elseif msg.msgId == LUIRedDotEvent.SetRedDotState then
		self:DealUpdateRedDotState(msg.value)
		--self:UpdateRedDot()
    end
end

function FengShenShiLianUI:Init(initTab)
    self.Script = "Activity.FengShenShiLianUI"
	self.m_pUILayer = nil
    self.m_timeline = nil
	self.m_bossNodeVec = {}
    self.m_indexVec = {}
	self.m_isInit = true
	self.m_diffcultyVec = {}
	self.m_tabNodeVec = {}
	--self.m_choose = nil
	self.m_pDesc = nil
	self.m_pDay = nil

	self.m_pDifficultyList = nil
	self.m_pDifficultyModel = nil
	self.m_pRewardList = nil
    self.m_pRewardModel = nil
    self.m_pPetModel = nil
    self.m_pPetList = nil

    self:RegistMsgs()
    self:InitViewSize()
	self:InitUIControl()
    self:setCloseCallback()
	--LuaNetSendMsg:QueryFengshenShiLian()
	--LuaNetSendMsg:QueryFengShen(1)
	self:LoadData(LRoleDataMgr.m_fengshenshilianData)
end

function FengShenShiLianUI:InitViewSize()
     self.m_pUILayer = cc.CSLoader:createNode("csd/fengshen/fengshenshilian1.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    self.m_timeline = cc.CSLoader:createTimeline("csd/fengshen/fengshenshilian1.csb")
    self.m_timeline:pause()
    self.m_pUILayer:runAction(self.m_timeline)
	Utils:SendMsg(LUIRoleDataChangeEvent.BGVisible, false)

	LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.UI_Title_FengShenShiLian)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
	
	LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.BGChange, "res/UI/ui_bg/bg_fengshenshilian.png")
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

	local function closeCallback()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, self.Script)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
     Utils:SendMsg(LUIFClassBgEvent.HelpBtn,AppDef.FCBHelp.ShiLian)
end

function FengShenShiLianUI:LoadData(datas)
	self.mylevel = LRoleDataMgr.MyHeroInfo.level
    if datas then
		self:SortData(datas)
        local ncount = #self.m_bossNodeVec
        local dcount = #self.m_datas
        for i=1,math.max(ncount, dcount) do
			local data = self.m_datas[i]
            local mapdata = JsonConfig.m_FuBenMapConfig.getDefByID(data.shilianId)
			if mapdata then
				local ID = 30000 + (mapdata.Id % 3000 - 1) * 10
				local list = {}
				for i = 1, 6 do
					table.insert(list, ID + i)
				end
				table.insert(self.m_diffcultyVec, list)
				self:UpdateTabButton(self.m_tabNodeVec[i], mapdata)
				if i == 1 then
					self:ExchangeChoose(self.m_tabNodeVec[i])
				end
				--获取展示模型表数据
				local fightdata = JsonConfig.m_vecFightConfig.getDefByID(mapdata.fightID)
				self:UpdateItem(self.m_bossNodeVec[i], data)
			end
        end
        if self.m_isInit then
			self:PlayBossAnim(true)
        end
		self.m_isInit = false
		self:UpdateRedDot()
    end
end

function FengShenShiLianUI:UpdateTiaoZhanData(updatedata)
	local shilianId = updatedata.shilianId
	for i = 1, #self.m_datas do
		local data = self.m_datas[i]
		if data.shilianId == shilianId then
			local tiaozhanId = data.tiaozhanId
			data.tiaozhanId = updatedata.jiesuoId
			data.saodangId = tiaozhanId
			data.times = updatedata.times
			break
		end
	end
	self:UpdateRewardInfo()

	--展示奖励
	
end

function FengShenShiLianUI:UpdateSaoDangData(updatedata)
	local shiliandata = 0
	for i = 1, #self.m_datas do
		local data = self.m_datas[i]
		stageid = data.saodangId
		if data.shilianId == updatedata.shilianId then
			data.times = updatedata.times
			shiliandata = data
			break
		end
	end
	self:UpdateTiaoZhanBtn(true, shiliandata.times > 0, shiliandata.saodangId, shiliandata)
	--展示奖励
	Utils:InitUI("Common.SaoDangUI", AppDef.UIType.PopWindow, updatedata.itemlist)
	
end

function FengShenShiLianUI:TabClick(sender)
	if sender == nil then
        return
    end
    local tag = sender:getTag()
	local mapdata = JsonConfig.m_FuBenMapConfig.getDefByID(tag)

	if self.mylevel < mapdata.OpenLv then
		Utils:ShowScrollTips(mapdata.OpenLv.. GUITips.UI_JiKaiqi)
		return
	end
	self:ExchangeChoose(sender)
	local curind = self.m_indexVec[1]
	local selectind = math.fmod(tag, 3000)
	local len = math.abs(selectind - curind)
	local toRight = true
	if len == 2 then
		for i = 1, len do
		local ind = self.m_indexVec[#self.m_indexVec]
		table.remove(self.m_indexVec, #self.m_indexVec)
		table.insert(self.m_indexVec, 1, ind)
		end
	end
	if selectind - curind == 1 or  selectind - curind == -3 then
		local ind = self.m_indexVec[1]
        table.remove(self.m_indexVec, 1)
        table.insert(self.m_indexVec, ind)
		toRight = false
	end

	if selectind - curind == -1 or  selectind - curind == 3 then
		local ind = self.m_indexVec[#self.m_indexVec]
		table.remove(self.m_indexVec, #self.m_indexVec)
        table.insert(self.m_indexVec, 1, ind)
	end
	self:PlayCocosAnim("L_down")
    performWithDelay(self.m_pUILayer, function(sender)
        self:PlayBossAnim(toRight)
    end, 25/60)
end

function FengShenShiLianUI:ExchangeChoose(sender)
	--self.m_choose:retain()
	--self.m_choose:removeFromParent()
	--sender:addChild(self.m_choose)
	--local size = sender:getContentSize()
	--self.m_choose:setPosition(cc.p(size.width/2,size.height/2))
	--self.m_choose:setLocalZOrder(-1)
	for i = 1,#self.m_tabNodeVec do
		local option = self.m_tabNodeVec[i]
		option:getChildByName("Choose"):setVisible(false)
	end
	local choose = sender:getChildByName("Choose")
	choose:setVisible(true)
end

function FengShenShiLianUI:ExchangeDiffcultyChoose(sender)
	--self.m_diffcultychoose:retain()
	--self.m_diffcultychoose:removeFromParent()
	--sender:addChild(self.m_diffcultychoose)
	--local size = sender:getContentSize()
	--self.m_diffcultychoose:setPosition(cc.p(size.width/2,size.height/2))
	--self.m_diffcultychoose:setLocalZOrder(-1)
	for k,v in pairs(self.m_pDifficultyList:getChildren()) do
        v:getChildByName("Image_1"):setScale(1)
		v:getChildByName("Image_1"):getChildByName("choose"):setVisible(false)
    end
	local img = sender:getChildByName("Image_1")
	img:setScale(1.1)
	local choose = img:getChildByName("choose")
	choose:setVisible(true)
end

function FengShenShiLianUI:SortData(datas)
	local dcount = #datas

	Utils:FreeTable(self.m_datas)
    self.m_datas = nil
    self.m_datas = datas
end

function FengShenShiLianUI:UpdateTabButton(pOption, mapdata)
	pOption:setTag(mapdata.Id)
	pOption:addClickEventListener(handler(self, FengShenShiLianUI.TabClick))
	self:MarkIntaractCObj(pOption)
	local tabname = pOption:getChildByName("Name")
	tabname:setString(mapdata.Name)
	local choosename = pOption:getChildByName("Choose"):getChildByName("Name")
	choosename:setString(mapdata.Name)
	local prompt = pOption:getChildByName("Prompt")
	prompt:setVisible(false)
	local show = Utils:GetRedDotState(RedDotDef.ID.Shenjiang_tag)
end

function FengShenShiLianUI:UpdateItem(pItem, data)
    if pItem == nil or data == nil then
        return
    end
	--根据服务器数据显示不同试炼类型对应的难度模型
	local stageid = 0
	if data.tiaozhanId > 0 then
		stageid = data.tiaozhanId
	elseif data.saodangId > 0 then
		stageid = data.saodangId
	end
	local stagedata =  JsonConfig.m_stageNodeConfig.getDefByID(stageid)
	local fightdata = JsonConfig.m_vecFightConfig.getDefByID(stagedata.fightID)
	local bossdata = JsonConfig.m_MonsterBoss.getDefByID(fightdata.show)--LDataConstMgr:GetMonsterData(fightdata.show)
	if bossdata == nil then
		return
	end
    pItem:setVisible(true)
    -- dump({pItem:getName(), data.name}, "UpdateItem----->")
    ----------------------------------
    local pImageBase = pItem:getChildByName("ImageBase")
    local pImodNode = pImageBase:getChildByName("Node")

    pImodNode:removeAllChildren()
    local imod = Utils:CreateImod("Monster/btm"..bossdata.pic.."_zd_show", cc.p(0,0), pImodNode, 1)
    imod:PlayActionRepeat(0)
    ----------------------------------
	local pImageBase = pItem:getChildByName("ImageBase")
    local pNameBg = pItem:getChildByName("NameBg")
    local pName = pNameBg:getChildByName("Name")
    pName:setString(bossdata.name or "")
    ----------------------------------
    local pClose = pItem:getChildByName("Close")
    pClose:setVisible(not data.isOpen)
	if not data.isOpen then
		imod:setColor(CCGRAY)
		pImageBase:setColor(CCGRAY)
		pNameBg:setColor(CCGRAY)
		pName:setColor(CCGRAY_WHITE)
	end
    ----------------------------------
end

function FengShenShiLianUI:UpdateRewardInfo(stageid, update) --update是指否刷新难度列表（同一个试炼神将下选择难度不刷新难度列表）
	if self.m_datas == nil or self.m_indexVec == nil then
        return
    end
	if update == nil then update = true end
	local ind = self.m_indexVec[1]
    local data = self.m_datas[ind]
	local mapdata = JsonConfig.m_FuBenMapConfig.getDefByID(data.shilianId)
	if data == nil then
		return
	end

	local rewardtype = 0 -----1:挑战   2：扫荡 3：未解锁 4：不可扫荡 
	local diffcultOpen = false
	if stageid == nil then
		if data.tiaozhanId > 0 then
			local aaa = JsonConfig.m_stageNodeConfig.getDefByID(data.tiaozhanId)
			if self.mylevel < aaa.Levellimit then
				stageid = data.saodangId
				rewardtype = 2
				diffcultOpen = true
			else
				stageid = data.tiaozhanId
				rewardtype = 1
				diffcultOpen = true
			end
		elseif data.saodangId > 0 then
			stageid = data.saodangId
			rewardtype = 2
			diffcultOpen = true
		end
	else
		if stageid == data.tiaozhanId then
			rewardtype = 1
			diffcultOpen = true
		elseif stageid == data.saodangId then
			rewardtype = 2
			diffcultOpen = true
		elseif stageid > data.tiaozhanId then
			rewardtype = 3
			diffcultOpen = false
		elseif  stageid < data.saodangId then
			rewardtype = 4
			diffcultOpen = false
		end
	end

	local stagedata = JsonConfig.m_stageNodeConfig.getDefByID(stageid)
	local str = GUITips.RSI_COMMON_ZHOU

	
	self.m_pDesc:setString(stagedata.Des)
	local opentimes = mapdata.OpenTime
	local opendesc = ""
	local prefix = ","
	for i = 1,#opentimes do
		local value = opentimes[i]
		if i == #opentimes then
			prefix = ""
		end
		if value == 1 then
			opendesc = opendesc.."一"..prefix
		elseif value == 2 then
			opendesc = opendesc.."二"..prefix
		elseif value == 3 then
			opendesc = opendesc.."三"..prefix
		elseif value == 4 then
			opendesc = opendesc.."四"..prefix
		elseif value == 5 then
			opendesc = opendesc.."五"..prefix
		elseif value == 6 then
			opendesc = opendesc.."六"..prefix
		elseif value == 7 then
			opendesc = opendesc.."日"..prefix
		end
	end
	self.m_pDay:setString(str..opendesc)

	---------------diffculty-----------------
	if update == true then
		self.m_pDifficultyList:removeAllItems()
		local percent = 0
		local diffcultyList = self.m_diffcultyVec[ind]
		for i=1,#diffcultyList do
			local diffcultyData = JsonConfig.m_stageNodeConfig.getDefByID(diffcultyList[i])
			local pItem =self:createModel(self.m_pDifficultyModel, self.m_pDifficultyList, diffcultyData, 3)
			if pItem then
				self.m_pDifficultyList:pushBackCustomItem(pItem)
				if diffcultyList[i] == stageid then
					percent = 33.3*(i-1)
					self:ExchangeDiffcultyChoose(pItem)
				end
			end
		end
		Utils:DelayToCallFunc(self.m_pUILayer,0.5, function()
			self.m_pDifficultyList:forceDoLayout()
			self.m_pDifficultyList:scrollToPercentHorizontal(percent,1,true)
		end)
	end

	------------------reward-----------
	local rewardIds = {}
	if rewardtype == 1 or rewardtype == 3 then
		rewardIds = stagedata.first_reward
	elseif rewardtype == 2 or rewardtype == 4 then
		local rewardId = stagedata.rewardID
		local rewarddata = JsonConfig.m_Reward.getDefByID(rewardId)
		rewardIds = rewarddata.reward
	end
	self.m_pRewardList:removeAllItems()
    for i=1,#rewardIds do
        local pItem =self:createModel(self.m_pRewardModel, self.m_pRewardList, rewardIds[i], 2)
        local _ = pItem and self.m_pRewardList:pushBackCustomItem(pItem)
    end
    ----------------pet------------------
    --self.m_pPetList:removeAllItems()
	--dump(stagedata.RecommendHero, "================RecommendHero===================")
    --for i=1,#stagedata.RecommendHero do
    --    local pItem =self:createModel(self.m_pPetModel, self.m_pPetList, stagedata.RecommendHero[i], 1)
    --    local _ = pItem and self.m_pPetList:pushBackCustomItem(pItem)
    --end

	--------------------------------
	if data.isOpen == false then
		self.tiaozhanBtn:setVisible(false)
		self.weijiesuo:setVisible(true)
	else
		if diffcultOpen == true then	
			--分是否解锁
			if self.mylevel < stagedata.Levellimit then
				self.tiaozhanBtn:setVisible(false)
				self.weijiesuo:setVisible(true)
			else
				self.tiaozhanBtn:setVisible(true)
				self.weijiesuo:setVisible(false)
				if rewardtype == 1 then
				self:UpdateTiaoZhanBtn(false, true, stageid, data)
				elseif rewardtype == 2 then
					self:UpdateTiaoZhanBtn(true, data.times > 0 , stageid, data)
				end
			end
		else
			if rewardtype == 3 then
				--分是否解锁
				if self.mylevel < stagedata.Levellimit then
					self.tiaozhanBtn:setVisible(false)
					self.weijiesuo:setVisible(true)
				else
					self.tiaozhanBtn:setVisible(true)
					self.weijiesuo:setVisible(false)
					self:UpdateTiaoZhanBtn(false, false, stageid, data)
				end
			elseif rewardtype == 4 then
				self.tiaozhanBtn:setVisible(false)
				self.weijiesuo:setVisible(false)
			end
		end
	end
end

function FengShenShiLianUI:UpdateTiaoZhanBtn(issaodang, isbright, stageid, data)
	self.tiaozhanBtn:setTag(stageid)
	self.tiaozhanBtn:setBright(isbright)
	if issaodang == false then
		self.tiaozhanBtn:getChildByName("Text"):setString(GUITips.UI_Title_Arena_TabName1)
		local cishu = self.tiaozhanBtn:getChildByName("tiaozhancishu")
		cishu:setVisible(false)	
	else
		local stagedata = JsonConfig.m_stageNodeConfig.getDefByID(stageid)
		self.tiaozhanBtn:getChildByName("Text"):setString(GUITips.UI_Text_Copy_Sweep_Times)
		local cishu = self.tiaozhanBtn:getChildByName("tiaozhancishu")
		cishu:setVisible(true)
		cishu:getChildByName("Num"):setString(data.times .."/".. stagedata.AttackCount)
	end
	
end

function FengShenShiLianUI:InitUIControl()
	local pPanel = self.m_pUILayer:getChildByName("Panel")
	pPanel:setTouchEnabled(false)
	local pPetList = pPanel:getChildByName("PetList")
	local pBtnL = pPetList:getChildByName("BtnL")
    pBtnL:setTag(1)
    pBtnL:addClickEventListener(handler(self, FengShenShiLianUI.ArrawBtnClick))
	self:MarkIntaractCObj(pBtnL)
    local pBtnR = pPetList:getChildByName("BtnR")
    pBtnR:setTag(2)
    pBtnR:addClickEventListener(handler(self, FengShenShiLianUI.ArrawBtnClick))
	self:MarkIntaractCObj(pBtnR)

	local pUILayer = cc.CSLoader:createNode("csd/fengshen/fengshenshilian2.csb")
    pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(pUILayer)
	Utils:FreeTable(self.m_bossNodeVec, self.m_indexVec)
    self.m_indexVec = nil
    self.m_bossNodeVec = nil
    self.m_indexVec = {}
    self.m_bossNodeVec = {}
    for i=0,3 do
        local pBoss = pUILayer:getChildByName("PetBg_"..i)
        pBoss:setVisible(false)
        pBoss:retain()
        pBoss:removeFromParent(false)
        pPetList:addChild(pBoss)
        pBoss:release()
        table.insert(self.m_bossNodeVec, pBoss)
        table.insert(self.m_indexVec, i+1)
    end

	self:ResetZOrder()

	----------------------tab list----------------
	local descbg = pPanel:getChildByName("Desc"):getChildByName("DescBg")
	local list = descbg:getChildByName("List")
	--self.m_choose = list:getChildByName("Choose")
	for i=1, 4 do
		local pOption = list:getChildByName("Option_"..i)
		table.insert(self.m_tabNodeVec, pOption)
	end

	self.m_pDesc = descbg:getChildByName("Text")
    self.m_pDesc:setString("")
	self.m_pDay = descbg:getChildByName("day")
    self.m_pDay:setString("")
	----------------------reward list--------------------
	local pReward = pPanel:getChildByName("Reward")
    local pRewardBg = pReward:getChildByName("RewardBg")
	local title3 = pRewardBg:getChildByName("Title_3")
	self.m_pDifficultyList = title3:getChildByName("DiffcultyList")
	self.m_pDifficultyModel = title3:getChildByName("Item")
	--self.m_diffcultychoose = title3:getChildByName("Choose")

	local title1 = pRewardBg:getChildByName("Title_1")
	self.m_pRewardList = title1:getChildByName("RewardList")
    self.m_pRewardModel = title1:getChildByName("Item")

	--local title2 = pRewardBg:getChildByName("Title_2")
	--self.m_pPetList = title2:getChildByName("PetList")
	--self.m_pPetModel = title2:getChildByName("Item")

	self.tiaozhanBtn = pRewardBg:getChildByName("Btn_tiaozhan")
	self.tiaozhanBtn:addClickEventListener(handler(self, FengShenShiLianUI.TiaozhanClick))
	self:MarkIntaractCObj(self.tiaozhanBtn)
	self.weijiesuo = pRewardBg:getChildByName("weijiesuo")
end

function FengShenShiLianUI:createModel(pModel, parent, pData, pType)
    local pItem = pModel:clone()
    if pType == 1 then
        Utils:ShowPet(pData, parent, pItem, false)
        --宠物特效
        if (noEffect == nil or noEffect == false) then
            local data = LPetDataMgr:FindPetDataById(pData)
            if data and data.quality >= 3 then
                local posX = pItem:getContentSize().width / 2
                local posY = pItem:getContentSize().height / 2
                Utils:createAnimEffect(pItem, cc.p(posX, posY), "res2/fx/gaojiwupin")
            end
        end
    elseif pType == 2 then
    	item = Utils:ShowItemByConfigData(pData, pItem, nil, false, true)
        pItem.userObject = pData
        pItem:setTouchEnabled(true)
        pItem:addClickEventListener(handler(self, FengShenShiLianUI.ItemBtnClick))
        -- local item = Utils:GetItemCellValue(pItem, 0, pData[1], true, true, pData[3], nil, true)
        --物品特效
        if (noEffect == nil or noEffect == false) then
            local quality = Utils:getQualityByItem(item)
            if quality >= 5 then
                local posX = pItem:getContentSize().width / 2
                local posY = pItem:getContentSize().height / 2
                Utils:createAnimEffect(pItem, cc.p(posX, posY), "res2/fx/gaojiwupin")
            end
        end
	elseif pType == 3 then
		pItem:setTag(pData.ID)
		--local name = pItem:getChildByName("Name")
		--name:setString(pData.Name)
		local index = pData.ID % ((pData.mapid - 1) * 10)
		local img = pItem:getChildByName("Image_1")
		local path = "res/UI/ui_wanfa/ui_fengshenshilian_nandu_"..index..".png"
		Utils:SafeLoadTexture(img, path,ccui.TextureResType.plistType)
		local ind = self.m_indexVec[1]
		local data = self.m_datas[ind]
		local tips2 = pItem:getChildByName("tips2")
		tips2:setString(pData.Levellimit ..GUITips.RSI_FACTION_MSG69)
		if self.mylevel >= pData.Levellimit then
			tips2:setVisible(false)
		end
		local tips1 = pItem:getChildByName("tips1")
		if pData.ID > data.saodangId then
			tips1:setVisible(false)
		end
		pItem:addClickEventListener(handler(self, FengShenShiLianUI.DiffcultyBtnClick))
		self:MarkIntaractCObj(pItem)
    end
    pItem:setVisible(true)
    return pItem
end

function FengShenShiLianUI:DiffcultyBtnClick(sender)
	print("=========DiffcultyBtnClick=========", sender:getTag())
	self:ExchangeDiffcultyChoose(sender)
	self:UpdateRewardInfo(sender:getTag(), false)
end

function FengShenShiLianUI:ItemBtnClick(sender)
    local data = sender.userObject
    Utils:ShowItemSource(data)
end

function FengShenShiLianUI:ResetZOrder()
    local maxZOrder = #self.m_indexVec
    for i=1,#self.m_bossNodeVec do
        local ind = self:FindIndex(i)
        self.m_bossNodeVec[i]:setLocalZOrder(maxZOrder - ind)
        -- dump({maxZOrder - ind, ind, self.m_bossNodeVec[i]:getName()}, "zORder-->")
    end
    -- dump(self.m_indexVec, "self.m_indexVec-->")
end

function FengShenShiLianUI:FindIndex(tag)
    for i=1,#self.m_indexVec do
        if self.m_indexVec[i] == tag then
            return i
        end
    end
    return nil
end

function FengShenShiLianUI:ArrawBtnClick(sender)
    if sender == nil then
        return
    end
    local tag = sender:getTag()
    local toRight = tag == 1
    if toRight then
        -- dump(self.m_indexVec, "---------->")
        local ind = self.m_indexVec[#self.m_indexVec]
        table.remove(self.m_indexVec, #self.m_indexVec)
        table.insert(self.m_indexVec, 1, ind)
        -- dump(self.m_indexVec, "<-----------")
    else
        -- dump(self.m_indexVec, "---------->")
        local ind = self.m_indexVec[1]
        table.remove(self.m_indexVec, 1)
        table.insert(self.m_indexVec, ind)
        -- dump(self.m_indexVec, "<-----------")
    end
	local curind = self.m_indexVec[1]
	local pOption = self.m_tabNodeVec[curind]
	local mapdata = JsonConfig.m_FuBenMapConfig.getDefByID(pOption:getTag())
	if self.mylevel < mapdata.OpenLv then
		Utils:ShowScrollTips(mapdata.OpenLv.. GUITips.UI_JiKaiqi)
		return
	end
	self:ExchangeChoose(pOption)
    self:PlayCocosAnim("L_down")
    performWithDelay(self.m_pUILayer, function(sender)
        self:PlayBossAnim(toRight)
    end, 25/60)
end

function FengShenShiLianUI:PlayCocosAnim(key)
    if self.m_timeline == nil or key == nil then
        return
    end
    self.m_timeline:play(key, false)
end

function FengShenShiLianUI:PlayBossAnim(isReverse)
    for i=1,#self.m_bossNodeVec do
        local ind = self:FindIndex(i)
        if ind then
            if not isReverse then
                ind = math.fmod(ind, 4) + 1
            end
            -- dump({ind, self.m_bossNodeVec[i]:getName(), isReverse}, "ind------>")
            local ac = self:createCocosAnim(ind, animConfig[ind], self.m_bossNodeVec[i], isReverse)
            if ac then
                self.m_bossNodeVec[i]:stopAllActions()
                self.m_bossNodeVec[i]:runAction(ac)
            end
        end
    end
    self:ResetZOrder()
    performWithDelay(self.m_pUILayer, function(sender)
        self:PlayCocosAnim("L_up")
    end, 15/60)
	self:UpdateRewardInfo()
end

function FengShenShiLianUI:createCocosAnim(tag, cfg, pNode, isReverse)
    local action = nil
    local time = 15/60
    local viewsize = AppDef.frameSize
    if tag == 1 or tag == 2 then
        -----------------
        local start,mid,finish = 1,2,3
        if isReverse then
            start,finish = finish,start
        end
        local seqSubArr = {}
        table.insert(seqSubArr, cc.MoveTo:create(8/60, cc.p(cfg.pos[mid].x/1334*viewsize.width, cfg.pos[mid].y)))
        table.insert(seqSubArr, cc.MoveTo:create(7/60, cc.p(cfg.pos[finish].x/1334*viewsize.width, cfg.pos[finish].y)))
        -----------------
        local from,to = cfg.scale[1],cfg.scale[2]
        if isReverse then
            from,to = to,from
        end
        local spawnArr = {}
        table.insert(spawnArr, cc.Sequence:create(seqSubArr))
        table.insert(spawnArr, cc.ScaleTo:create(time, to))
        -----------------
        local seqArr = {}
        table.insert(seqArr, cc.CallFunc:create(function()
            pNode:setOpacity(255)
            pNode:setScale(from)
            pNode:setPosition(cc.p(cfg.pos[start].x/1334*viewsize.width, cfg.pos[start].y))
        end))
        table.insert(seqArr, cc.Spawn:create(spawnArr))
        local _ = callback and table.insert(seqArr, cc.CallFunc:create(callback))
        action = cc.Sequence:create(seqArr)
    else
        local start,mid,finish = 1,2,3
        if isReverse then
            start,finish = finish,start
        end
        local seqSubArr = {}
        table.insert(seqSubArr, cc.MoveBy:create(8/60, cc.p((cfg.pos[mid].x-cfg.pos[start].x)/1334*viewsize.width, 0)))
        table.insert(seqSubArr, cc.MoveBy:create(7/60, cc.p((cfg.pos[finish].x-cfg.pos[mid].x)/1334*viewsize.width, 0)))
        -----------------
        local from,to = cfg.scale[1],cfg.scale[2]
        if isReverse then
            from,to = to,from
        end
        local spawnArr = {}
        table.insert(spawnArr, cc.Sequence:create(seqSubArr))
        table.insert(spawnArr, cc.MoveBy:create(time, cc.p(0, cfg.pos[finish].y-cfg.pos[start].y)))
        table.insert(spawnArr, cc.ScaleTo:create(time, to))
        local fadeArr = {}
        local startOp,finishOp = cfg.opacity[1],cfg.opacity[2]
        if isReverse then
            startOp,finishOp = finishOp,startOp
        end
        if tag == 4 or (tag == 3 and isReverse) then
            table.insert(fadeArr, cc.DelayTime:create(8/60))
        end
        table.insert(fadeArr, cc.FadeTo:create(7/60, finishOp))
        if tag == 3 or (tag == 4 and isReverse) then
            table.insert(fadeArr, cc.DelayTime:create(8/60))
        end
        table.insert(spawnArr, cc.Sequence:create(fadeArr))
        -----------------
        local seqArr = {}
        table.insert(seqArr, cc.CallFunc:create(function()
            pNode:setOpacity(startOp)
            pNode:setScale(from)
            pNode:setPosition(cc.p(cfg.pos[start].x/1334*viewsize.width, cfg.pos[start].y))
        end))
        table.insert(seqArr, cc.Spawn:create(spawnArr))
        local _ = callback and table.insert(seqArr, cc.CallFunc:create(callback))
        action = cc.Sequence:create(seqArr)
    end
    return action,name
end

function FengShenShiLianUI:TiaozhanClick(sender)
	local tag = sender:getTag()
	local stagedata = JsonConfig.m_stageNodeConfig.getDefByID(tag)
	local ind = self.m_indexVec[1]
	local data = self.m_datas[ind]
	if self.mylevel < stagedata.Levellimit then
		--Utils:ShowScrollTips(GUITips.RSI_FENGSHEN_SHILIAN_TIP1)
		Utils:ShowScrollTips(stagedata.Levellimit.. GUITips.UI_JiKaiqi)
	else
		if data.tiaozhanId == tag then
			--LuaNetSendMsg:QueryFengshenTiaozhan()
			if not self:teamEvent() then
				LuaNetSendMsg:QueryFengshenTiaozhan(data.shilianId)
			end
		elseif data.saodangId == tag then
			if data.times <=0 then
				Utils:ShowScrollTips(GUITips.RSI_FENGSHEN_SAODANG_ZERO)
				return
			end
			LuaNetSendMsg:QueryFengshenSaoDang(data.shilianId)
		end
	end
	
end

function FengShenShiLianUI:teamEvent( ... )
    -- body
    if LRoleDataMgr.MyHeroInfo:IsTeam() then
        local function okFunc()
            LuaNetSendMsg:QueryLeaveTeam()
        end
        local function canelFunc()
            
        end
        Utils:ShowDialogOKCancel(GUITips.RSI_TARGET_RD_TIPS15, okFunc,canelFunc)
        return true
    end
    return false
end

function FengShenShiLianUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

function FengShenShiLianUI:onExit()
    self:Destory()
    self.Script = nil
    self.m_datas = nil
    Utils:FreeTable(self.m_bossNodeVec)
    self.m_bossNodeVec = nil
    self.m_timeline = nil
    Utils:FreeTable(self.m_indexVec)
    self.m_indexVec = nil
    self.m_isInit = nil
	LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.BGChange, "res/UI/ui_common_new/ui_bg_new.jpg")
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function FengShenShiLianUI:UpdateRedDot()
	LRedDotCheckMgr:FuBenRedDotCheck()
	local show = Utils:GetRedDotState(RedDotDef.ID.FengShengTab1)
	self.m_tabNodeVec[1]:getChildByName("Prompt"):setVisible(show)
	show = Utils:GetRedDotState(RedDotDef.ID.FengShengTab2)
	self.m_tabNodeVec[2]:getChildByName("Prompt"):setVisible(show)
	show = Utils:GetRedDotState(RedDotDef.ID.FengShengTab3)
	self.m_tabNodeVec[3]:getChildByName("Prompt"):setVisible(show)
	show = Utils:GetRedDotState(RedDotDef.ID.FengShengTab4)
	self.m_tabNodeVec[4]:getChildByName("Prompt"):setVisible(show)
end

function FengShenShiLianUI:DealUpdateRedDotState(data)
	local ind = 0
	if data.id == RedDotDef.ID.FengShengTab1 then
		ind = 1
	elseif data.id == RedDotDef.ID.FengShengTab2 then
		ind = 2
	elseif data.id == RedDotDef.ID.FengShengTab3 then
		ind = 3
	elseif data.id == RedDotDef.ID.FengShengTab4 then
		ind = 4
	end
	if ind == 0 then return end
	local option = self.m_tabNodeVec[ind]
	option:getChildByName("Prompt"):setVisible(data.isShow)
end
return FengShenShiLianUI