--[[
lua里面的游戏逻辑控制

userData数据结构：
{     
    （必选二选一1）itemData:
    （必选二选一2）id:
    （可选）pos:   装备栏的位置,下标从1开始
    （可选）petId: 神将Id
     (可选）showFrom:显示来源按钮，默认显示
     (可选）showCorrTips:显示对比Tips，默认不显示
    （可选）showBtn:显示按钮，默认显示
    ...后续按需要添加
}
]]
local PetUIDef = require "View.Pet.PetUIDef"
local ShopDef = require("View.Shop.ShopDef")
local PetEquipTipsUI = LUIBase:New()
PetEquipTipsUI.__index = PetEquipTipsUI
--local this = LTcpSocket
function PetEquipTipsUI:New(userData)
	local o = LUIBase:New()
	setmetatable(o,PetEquipTipsUI)	
    o:Init(userData)
	return o
end


function PetEquipTipsUI:Init(userData)
    --self.m_pNode = cc.Node:create()

    self.m_pUILayer = cc.CSLoader:createNode("csd/ItemInfoLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
   -- self:addChild(self.m_pUILayer)
   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:InitData()
    self:InitTouchEvt()
    self:RegistMsgs()
    self:ShowItem(userData)
    --self:ShowVersion()
end

function PetEquipTipsUI:InitData()
    self.m_bgClosePanel = self.m_pUILayer:getChildByName("Panel")
    local panel = self.m_pUILayer:getChildByName("Panel_1")
    panel:setTouchEnabled(false)
    self.m_bgPanel = panel:getChildByName("Panel_1_0")
    self.m_pItemIconPanel = self.m_bgPanel:getChildByName("Image_2")
    self.m_bgPanel:getChildByName("Image_4"):setVisible(false)
    self.m_bgPanel:getChildByName("Image_3"):setVisible(false)
    self.m_pNameLabel = self.m_bgPanel:getChildByName("nameLabel")
    self.m_pNameLabel:disableEffect()
    self.m_pTypeLabel = self.m_bgPanel:getChildByName("typeLabel")
    self.m_bgPanel:getChildByName("powerLabel"):setVisible(false)
    self.m_pInfoListView = self.m_bgPanel:getChildByName("infoListView")
    self.m_pInfoListView:setItemsMargin(5)
    self.m_pLineImg = self.m_bgPanel:getChildByName("Line")
    self.m_pLineImg:retain()
    self.m_pLineImg:removeFromParent()
    self.m_pCloseBtn = self.m_bgPanel:getChildByName("closeBtn")
    self.m_pBtnListPanel = self.m_bgPanel:getChildByName("Btn_ListView")
    self.m_pBtmBtnListPanel = self.m_bgPanel:getChildByName("Btn_ListView_0")
    self.m_pBaseBtn = self.m_pBtnListPanel:getChildByName("commonBtn1")
    self.m_pBaseBtn:retain()
    self.m_pBaseBtn:removeFromParent()
    self.m_pFromPanel = self.m_bgPanel:getChildByName("Btn_ListView2") 
    self.m_pFromLabel = self.m_pFromPanel:getChildByName("Text")
    self.m_pFromList = self.m_pFromPanel:getChildByName("List")
    self.m_pFromBtn = self.m_bgPanel:getChildByName("SystemBtn")
    self.m_pFromBtn:getChildByName("Name"):setVisible(false)
    self.m_pFromBtn:setAnchorPoint(0,0)
    self.m_pFromBtn:retain()
    self.m_pFromBtn:removeFromParent()

    self.m_id = 0
    self.m_itemData = nil
    self.m_isShowFrom = true
    self.m_isShowCorrTips = false
    self.m_isShowBtn = false
    self.m_pos = 0
    self.m_petId = 0
end

function PetEquipTipsUI:InitTouchEvt()
    local function closeCallback(sender)
        self:CloseUI()
    end
    self.m_pCloseBtn:addClickEventListener(closeCallback)
	self:MarkIntaractCObj(self.m_pCloseBtn)
    self.m_bgClosePanel:addClickEventListener(closeCallback)
	self:MarkIntaractCObj(self.m_bgClosePanel)
end

function PetEquipTipsUI:ShowItem(userData)
    if userData == nil then
        return
    end
    self.m_id = userData["id"] or 0
    if self.m_id > 0 then
        self.m_itemCfgData = LDataConstMgr:GetPetEquipCfgData(self.m_id)
        self.m_star = userData["star"] or 1
    else
        self.m_itemData = userData["itemData"]
        self.m_pos = userData["pos"] or 0
        self.m_isShowBtn = userData["showBtn"] == nil and true or userData["showBtn"]
        self.m_petId = userData["petId"] or 0
        self.m_isShowCorrTips = userData["showCorrTips"] or false
        self.m_itemCfgData = LDataConstMgr:GetPetEquipCfgData(self.m_itemData.m_id)
    end
    self.m_isShowFrom = userData["showFrom"] or true
    
    userData["id"] = nil
    userData["itemData"] = nil
    userData["pos"] = nil
    userData["petId"] = nil
    userData["showFrom"] = nil
    userData["showBtn"] = nil
    userData["showCorrTips"] = nil
    userData["star"] = nil

    if self.m_itemCfgData == nil then return end

    --对比Tips   
    self:ShowCorrTips() 
    --当前Tips
    self:InitItemBtns()
    if self.m_id > 0 then
        local label = self:AddLabel(self.m_itemCfgData.unKnowDesc,AppDef.FNT_NAMEC, AppDef.UIFONTSIZELB, UICOLOR_YELLOW_PALE,self.m_pInfoListView)
        self:TextLineFeed(label,305)
    end
    local level,equipStar,quality = self:GetQuality()
	if self.m_itemData ~= nil and self.m_isShowBtn == true then
		self.m_bgPanel:getChildByName("Image_3"):setVisible(self.m_pos > 0)
	end
    self:ShowEquipBaseInfo(self.m_itemCfgData.name,quality,level,self.m_pNameLabel)
    self:ShowEquipIcon(self.m_pItemIconPanel,quality,equipStar,self.m_itemCfgData.pic, level,self.m_itemCfgData.suitType)
    if self.m_id == 0 then
        self:ShowDetailInfo(self.m_itemData,self.m_pInfoListView)
    end
    self:ShowSuitInfo(self.m_itemCfgData.suitType,self.m_pInfoListView)   
end

function PetEquipTipsUI:AddLabel(str,fontname,fontsize,color,infoListView)
    if infoListView == nil then return nil end
    local label = ccui.Text:create(str,fontname,fontsize)
    label:setColor(color)
    infoListView:pushBackCustomItem(label)
    return label
end

function PetEquipTipsUI:AddSubLabel(parent, str,fontname,fontsize,color, pos)
    local label = ccui.Text:create(str,fontname,fontsize)
    label:setAnchorPoint(cc.p(0, 0.5))
    label:setColor(color)
    parent:addChild(label)
    label:setPosition(pos)
    return label
end

--[[
显示物品详细信息
]]
function PetEquipTipsUI:ShowDetailInfo(itemData,infoListView)
    if self.m_id > 0 or itemData == nil then return end
    --基础属性
    for i = 1, #itemData.m_baseTypes do
        local contentStr = LDataConstMgr:GetItemAttrName(itemData.m_baseTypes[i]) .." "
        if itemData.m_baseTypes[i] > AppDef.EAttrType.EAT_RESISIT_CRIT then    
            contentStr = contentStr ..string.format("%.2f",itemData.m_baseValues[i]/100) .."%"
        else
            contentStr = contentStr ..itemData.m_baseValues[i]
        end
        local label = self:AddLabel(contentStr, AppDef.FNT_NAMEC, AppDef.UIFONTSIZELB, UICOLOR_YELLOW_PALE,infoListView)

        local stoneStr = ""
        local cfgData = LDataConstMgr:GetPetEquipQHCfgData(itemData.m_stoneLevel)
        if cfgData ~= nil then
            local tempAttr = math.floor(itemData.m_baseValues[i]*cfgData.upRatio/10000)
            if itemData.m_baseTypes[1] > AppDef.EAttrType.EAT_RESISIT_CRIT then
                stoneStr = "+"..string.format("%.2f",tempAttr/100).."%"
            else
                stoneStr = "+"..tempAttr
            end
            local parentSize = label:getContentSize()
            self:AddSubLabel(label,stoneStr, AppDef.FNT_NAMEC, AppDef.UIFONTSIZELB, UICOLOR_GREEN_TIPS,cc.p(parentSize.width + 4, parentSize.height/2))
        end
    end
 
    --附加属性
    self:AddLine(infoListView)
    self:AddLabel(GUITips.RSI_PET_SUIT_TIPS5, AppDef.FNT_NAMEC, AppDef.UIFONTSIZELB, UICOLOR_PURPLE_TIPS,infoListView)

    for i = 1, #itemData.m_addTypes do
        local attrType = itemData.m_addTypes[i]
        local attrVal = itemData.m_addValues[i]
        local contentStr = LDataConstMgr:GetItemAttrName(attrType) .." "
        if attrType > AppDef.EAttrType.EAT_RESISIT_CRIT then    
            contentStr = contentStr ..string.format("%.2f",attrVal/100).."%"
        else
            contentStr = contentStr..attrVal
        end
        self:AddLabel(contentStr, AppDef.FNT_NAMEC, AppDef.UIFONTSIZELB, UICOLOR_WHITE_TIPS,infoListView)
    end
end

--文本换行
function PetEquipTipsUI:TextLineFeed(label,maxWidth)
   if label == nil then
       return 0
   end
   local size = label:getAutoRenderSize()
   local row = math.ceil(size.width/maxWidth)
   label:ignoreContentAdaptWithSize(false)
   local height = row*size.height+size.height/2
   label:setContentSize(cc.size(maxWidth,height))
   return height
end

function PetEquipTipsUI:AddLine(infoListView)
    if infoListView == nil then return end
    local line = self.m_pLineImg:clone()
    infoListView:addChild(line)
end

function PetEquipTipsUI:InitItemBtns()
    if self.m_isShowBtn == false or self.m_id > 0 then
        self.m_pBtnListPanel:setVisible(false)
        self.m_pBtmBtnListPanel:setVisible(false)
	return
    end
    if self.m_pBtnListPanel then
        self.m_pBtnListPanel:removeAllItems()
    end
    if self.m_pBtmBtnListPanel then
        self.m_pBtmBtnListPanel:removeAllItems()
    end
    
    if self.m_pos == 0 then 
        if self.m_petId > 0 then
            self:AddBagEquipBtns() 
            self:AddStrengthenBtns()
            self:AddBagDisCardBtns()
			self:AddLockedFromBtns()
        end
    else
        self:AddStrengthenBtns()
        self:AddEquipedBtns()
		self:AddLockedFromBtns()
    end
    if self.m_itemCfgData ~= nil and #self.m_itemCfgData.from > 0 and self.m_isShowFrom then
        self:AddBagFromBtns()
    end

    self:SetBtnList(self.m_pBtnListPanel)
    self:SetBtnList(self.m_pBtmBtnListPanel)
end

function PetEquipTipsUI:SetBtnList(list)
    if list == nil then
        return
    end
    local num = list:getChildrenCount()
    list:setVisible(num > 0)
    if list:isVisible() then
        list:setContentSize(cc.size(self.m_pBaseBtn:getContentSize().width, self.m_pBaseBtn:getContentSize().height * num +(num - 1) * 5))
    end
end

function PetEquipTipsUI:CloseUI()
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Common.PetEquipTipsUI")
    self:SendMsg(LGameMsg.m_initUIMsg)
end

function PetEquipTipsUI:PetEquipRedDot()
    local signs = LPetDataMgr:GetPetEquipRedDot()
    if signs ~= nil and next(signs) ~= nil then
	    local send = LPetDataMgr:DelPetSuitRedDot(self.m_itemData.m_suitType,self.m_itemData.m_uid)
        if send then
            local msg = LUIMsg1.New(LUILogicEvent.InitUI)
            msg:Change(LUIPetEvent.PetEquipAdd,self.m_itemData.m_suitType)
            self:SendMsg(msg)      
        end
    end
end
--[[
添加已装备道具的按钮事件
]]
function PetEquipTipsUI:AddEquipedBtns()
    if self.m_pos == nil or self.m_pos < 1 then
        return
    end
    local function unEquipCallback(sender)
        LuaNetSendMsg:QueryPetEquip(3,self.m_itemData.m_uid,self.m_petId)
        self:CloseUI()
    end
    local btn = self.m_pBaseBtn:clone()
    btn:setTitleText(GUITips.UI_Btn_Equip_PutOff)
    self.m_pBtnListPanel:pushBackCustomItem(btn)
    btn:addClickEventListener(unEquipCallback)
	self:MarkIntaractCObj(btn)
end

--[[
添加背包内装备道具的按钮事件
]]
function PetEquipTipsUI:AddBagEquipBtns()
    local function unEquipCallback(sender)
        LuaNetSendMsg:QueryPetEquip(2,self.m_itemData.m_uid,self.m_petId)
        self:PetEquipRedDot()
        self:CloseUI()
    end
    local btn = self.m_pBaseBtn:clone()
    btn:setTitleText(GUITips.UI_Btn_Equip_PutOn)
    self.m_pBtnListPanel:pushBackCustomItem(btn)
    btn:addClickEventListener(unEquipCallback)
	self:MarkIntaractCObj(btn)
end

--[[
添加背包内道具的分解按钮事件
]]
function PetEquipTipsUI:AddBagDisCardBtns()
    local function DisCardCallback(sender)
        local function  cancelFunc()

        end
		if self.m_itemData.m_locked == 1 then
			Utils:ShowScrollTips(GUITips.RSI_GS_TIP16)
			return
		end
        --直接分解
        if self.m_pos ~= 0 or self.m_itemData == nil  or self.m_itemData.m_uid == 0 or self.m_itemData.m_stoneLevel == nil or self.m_itemData.m_star == nil then return end
        if self.m_itemData.m_stoneLevel > 0 then
            Utils:ShowDialogOKCancel(GUITips.RSI_RESOLVE_TIP_3,handler(self,PetEquipTipsUI.OnDisCard),cancelFunc)
            return
        end
        if self.m_itemData.m_star == 6 then
            Utils:ShowDialogOKCancel(GUITips.RSI_RESOLVE_TIP_2,handler(self,PetEquipTipsUI.OnDisCard),cancelFunc)
            return
        end
        self:OnDisCard()
    end
    local btn = self.m_pBaseBtn:clone()
    btn:setTitleText(GUITips.UI_Btn_Item_Fenjie1)
    self.m_pBtmBtnListPanel:pushBackCustomItem(btn)
    btn:addClickEventListener(DisCardCallback)
	self:MarkIntaractCObj(btn)
end

--分解
function PetEquipTipsUI:OnDisCard()
    if self.m_pos ~= 0 or self.m_itemData.m_uid == 0 then return end
    LuaNetSendMsg:QueryPetEquip(5,self.m_itemData.m_uid,0)
--    local uids = {}
--    uids[1] = self.m_itemData.m_uid
--    LuaNetSendMsg:SendPetEquipFenjieReq(uids)
    self:PetEquipRedDot()
    self:CloseUI()
end


--[[
添加道具的强化按钮事件
]]
function PetEquipTipsUI:AddStrengthenBtns()
    local function btnCallback(sender)
        local petId = self.m_petId
        if self.m_pos == 0 then petId = 0 end
--        --临时直接强化
--        LuaNetSendMsg:QueryPetEquip(4,self.m_itemData.m_uid,petId)
        
        if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SJEQUIPQH) then
            return
        end
        --跳转强化界面
        local value = {self.m_itemData,petId}
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Pet.PetEquipStrengthenUI", AppDef.UIType.ThirdClassLayer, value)
        self:SendMsg(LGameMsg.m_initUIMsg)
        self:PetEquipRedDot()
        self:CloseUI()
    end
    local btn = self.m_pBaseBtn:clone()
    btn:setTitleText(GUITips.UI_Btn_Equip_Strengthen)
    self.m_pBtnListPanel:pushBackCustomItem(btn)
    btn:addClickEventListener(btnCallback)
	self:MarkIntaractCObj(btn)
end

--来源按钮
--@param itemData Item表数据
function PetEquipTipsUI:AddBagFromBtns()
    local function Callback(sender)
        --隐藏按钮页面
        self.m_pBtnListPanel:setVisible(false)
        self.m_pFromPanel:setVisible(true)
        self:ShowFromInfo()
    end
    local btn = self.m_pBaseBtn:clone()
    btn:setTitleText(GUITips.UI_Btn_Item_From)
    self.m_pBtnListPanel:pushBackCustomItem(btn)
    btn:addClickEventListener(Callback)
	self:MarkIntaractCObj(btn)
end

--添加锁定按钮
function PetEquipTipsUI:AddLockedFromBtns()
	local function Callback(sender)
		if self.m_itemData.m_locked == 1 then
			if self.m_pos == 0 then
				LuaNetSendMsg:QueryPetEquip(10,self.m_itemData.m_uid,0)
			else
				LuaNetSendMsg:QueryPetEquip(10,self.m_itemData.m_uid,self.m_petId)
			end
		else
			if self.m_pos == 0 then
				LuaNetSendMsg:QueryPetEquip(9,self.m_itemData.m_uid,0)
			else
				LuaNetSendMsg:QueryPetEquip(9,self.m_itemData.m_uid,self.m_petId)
			end
		end
		self:CloseUI()
    end
	local btn = self.m_pBaseBtn:clone()
	if self.m_itemData.m_locked == 1 then
		btn:setTitleText(GUITips.UI_Btn_Equip_unLocked)
	else
		btn:setTitleText(GUITips.UI_Btn_Equip_Locked)
	end
    self.m_pBtnListPanel:pushBackCustomItem(btn)
    btn:addClickEventListener(Callback)
	self:MarkIntaractCObj(btn)
end
--来源面板
function PetEquipTipsUI:ShowFromInfo()
    local function showIcon(sourceBtn,sourceId)
        --显示来源Icon
        if sourceBtn == nil or sourceId == nil or sourceId < 1 then
            return
        end
        local res = AppDef:GetItemFromIcon(sourceId)
        if res == nil then return end
        local size = self.m_pFromBtn:getContentSize()
        --sourceBtn:ignoreContentAdaptWithSize(false)   
        sourceBtn:loadTextureNormal(res) 
        local curSize  = sourceBtn:getVirtualRendererSize()  
        sourceBtn:setScale(size.width/curSize.width)
    end

    local function onClick(sender)
        --来源Icon点击
        local sourceId = sender.userObject
        if sourceId == nil or sourceId < 1 then
            return
        end
        if Utils:CheckModelNotOpened(sourceId,false) then
            return
        end
        local itemId = 0
        if type(self.m_itemCfgData) == "table" and self.m_itemCfgData ~= nil then 
            itemId = self.m_itemCfgData.id
        end
        LGameMsg.m_baseMsg:ChangeEventId(LUILogicEvent.CloseAllPopup)
        self:SendMsg(LGameMsg.m_baseMsg)
        
        if sourceId == AppDef.EModuleID.EMID_SCJIFEN then --积分商城
            Utils:OpenShop(ShopDef.MK_TP.COMPETE)  
            self:CloseUI()
        elseif sourceId == AppDef.EModuleID.EMID_SCJIFEN then --帮贡商城
            Utils:OpenShop(ShopDef.MK_TP.GONGOFFER)
        elseif sourceId < AppDef.EActivityID.EAID_MAX then --玩法
            self:CloseUI()   
            Utils:OpenWanfaUI(sourceId)
        else
            self:CloseUI()
            Utils:OpenFunction(sourceId)
        end
    end

    local list = self.m_itemCfgData.from
    if list == nil or #list == 0 then return end

    local max = #list
    local line = math.ceil(max/3)  
    for i=1,max do
        local row = line - math.floor((i-1)/3)-1
        local low = (i-1)%3
        local btn = self.m_pFromBtn:clone()
        btn.userObject = list[i]
        self.m_pFromList:addChild(btn)
        btn:setPosition(cc.p(low*100,row*100))
        showIcon(btn,list[i])
        btn:addClickEventListener(onClick)
		self:MarkIntaractCObj(btn)
    end
    local size = self.m_pFromPanel:getContentSize()
    local height = 90+line*100
    local width = size.width
    if max < 3 then width = max * math.floor(size.width/3) + 20 end
    self.m_pFromPanel:setContentSize(cc.size(width,height))
    self.m_pFromLabel:setPosition(cc.p(35,height-30))
end

function PetEquipTipsUI:GetQuality()
    local level = 0      --强化等级
    local equipStar = 1  --星级
    local quality = 1
    if self.m_id == 0 then
        level = self.m_itemData.m_stoneLevel
        equipStar = self.m_itemData.m_star
    else
        equipStar = self.m_star
    end
    local starCfgData =  LDataConstMgr:GetPetEquipStarCfgData(equipStar)
    if starCfgData ~= nil then
        quality = starCfgData.quality
    end
    return level,equipStar,quality
end

function PetEquipTipsUI:ShowEquipIcon(parent,quality,equipStar,pic,stoneLevel,suitType)
    parent:removeAllChildren()

    local resFile = string.format("item/%s.png", pic) 

    local userDefine ={picFilePath = resFile,quality = quality, star = equipStar, strengthenLv = stoneLevel,suitId = suitType}
    local itemValue = {}
    itemValue.userDefine = userDefine
    ItemCellUI:New(parent, itemValue)
end

--[[
显示装备道具基础信息
]]
function PetEquipTipsUI:ShowEquipBaseInfo(name,quality,level,nameLabel)
    if nameLabel == nil then return end
    local color = AppDef:GetItemQualityColor(quality)
    nameStr = name
    if level ~= nil and level > 0 then
        nameStr = nameStr.."		+" .. level
    end
    nameLabel:setString(nameStr)
    nameLabel:setTextColor(color)
end

--[[
显示装备套装信息
]]
function PetEquipTipsUI:ShowSuitInfo(suitId,infoListView)
--    if self.m_itemCfgData == nil then return end  
--    local suitId = self.m_itemCfgData.suitType
    local suitCfgData = LDataConstMgr:GetPetSuitCfgData(suitId)
    if suitCfgData == nil then return end
    self:AddLine(infoListView)  

    local num = 0
    if self.m_pos > 0 and self.m_petId > 0  then
		local data = nil 
		if self.m_isShowBtn == true then
			data =  LRoleDataMgr.Pet:GetPetById(self.m_petId)
		else
			data =  LRoleDataMgr:getOtherRolePetDataById(self.m_petId)
		end
        if data ~= nil then
           local value = data.petSuits[suitId]
           if value ~= nil then
               num = #value
           end
        end
    end
    local contentStr = string.format(GUITips.RSI_PET_SUIT_TIPS4,suitCfgData.name)
    self:AddLabel(contentStr, AppDef.FNT_NAMEC, AppDef.UIFONTSIZELB, UICOLOR_PURPLE_TIPS,infoListView)
    
    for i = 1, suitCfgData.maxAttrNum do
        local suitStr = LDataConstMgr:GetHeroSkillDesc(suitCfgData.skillId[i], suitCfgData.skillLv[i])
        local color = UICOLOR_GRAY_TIPS
        if num >= i then
            color = UICOLOR_GREEN
        end
        local numStr = string.format(GUITips.RSI_PET_SUIT_TIPS9,suitCfgData.suitNum[i])
        local label = self:AddLabel(numStr..Utils:DeleteString(suitStr,"%[","%]"), AppDef.FNT_NAMEC, AppDef.UIFONTSIZELB, color,infoListView)
        self:TextLineFeed(label,305)
    end
end

--显示对比Tips(同部位已装备属性)
function PetEquipTipsUI:ShowCorrTips()
    if self.m_petId == 0 or self.m_id > 0 or self.m_pos > 0 or not self.m_isShowCorrTips then
        return
    end
    local petInfo = LRoleDataMgr.Pet:GetPetById(self.m_petId)
    if petInfo == nil or petInfo.petEquips == nil then 
       return 
    end
    local info = petInfo.petEquips[self.m_itemCfgData.pos]
    if info == nil then return end
    local cfgData = LDataConstMgr:GetPetEquipCfgData(info.m_id)
    if cfgData == nil then return end
    local x,y = self.m_bgPanel:getPosition()
    local size = self.m_bgPanel:getContentSize()
    local corrTipsPanel = self.m_bgPanel:clone()
    self.m_bgPanel:getParent():addChild(corrTipsPanel)
    corrTipsPanel:setPosition(cc.p(x-size.width-10,y))

    local infoListView = corrTipsPanel:getChildByName("infoListView")
    local nameLabel = corrTipsPanel:getChildByName("nameLabel")
    local iconParentImg = corrTipsPanel:getChildByName("Image_2")
    local btnListPanel = corrTipsPanel:getChildByName("Btn_ListView")
    btnListPanel:setVisible(false)
    local btnBtmListPanel = corrTipsPanel:getChildByName("Btn_ListView_0")
    btnBtmListPanel:setVisible(false)
    local loseBtn = corrTipsPanel:getChildByName("closeBtn")
    loseBtn:setVisible(false)

	--显示已装备标志
	corrTipsPanel:getChildByName("Image_3"):setVisible(true)

    local quality = 1
    local starCfgData =  LDataConstMgr:GetPetEquipStarCfgData(info.m_star)
    if starCfgData ~= nil then
        quality = starCfgData.quality
    end

    self:ShowEquipBaseInfo(cfgData.name,quality,info.m_stoneLevel,nameLabel)
    self:ShowEquipIcon(iconParentImg,quality,info.m_star,cfgData.pic,info.m_stoneLevel,cfgData.suitType)
    self:ShowDetailInfo(info,infoListView)
    self:ShowSuitInfo(cfgData.suitType,infoListView)
end

--[[
注册UI消息
]]
function PetEquipTipsUI:RegistMsgs()
   
end

function PetEquipTipsUI:ProcessEvent(msg)
    
end

function PetEquipTipsUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_itemData = nil
    self.m_pos = nil
    self.m_bgClosePanel = nil
    self.m_bgPanel = nil
    self.m_pItemIconPanel = nil
    self.m_pNameLabel = nil
    self.m_pTypeLabel = nil
    self.m_pInfoListView = nil
    if self.m_pLineImg then
        self.m_pLineImg:release()
        self.m_pLineImg = nil
    end
    self.m_pCloseBtn = nil
    self.m_pBtnListPanel = nil
    self.m_pBtmBtnListPanel = nil
    if self.m_pBaseBtn then
        self.m_pBaseBtn:release()
        self.m_pBaseBtn = nil
    end
    self.m_pFromPanel = nil
    self.m_pFromLabel = nil
    self.m_pFromList = nil
    if self.m_pFromBtn then
        self.m_pFromBtn:release()
        self.m_pFromBtn = nil
    end
    self.m_id = nil
    self.m_itemData = nil
    self.m_isShowFrom = nil
    self.m_isShowCorrTips = nil
    self.m_isShowBtn = nil
    self.m_pos = nil
    self.m_petId = nil
end

 
return PetEquipTipsUI