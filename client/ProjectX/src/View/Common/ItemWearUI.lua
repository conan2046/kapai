--[[
lua里面的游戏逻辑控制
可穿戴的非道具Tips
userData数据结构：
{
    （必选）itemType：字符串，可选值有： "Artifact"    神器
                                         "Wing"        翅膀
                                         "Mount"       坐骑
                                         "Title"       称号 
                                         ...按需添加
    （必选）id
    ...后续按需要添加
}
]]

local ItemWearUI = LUIBase:New()
ItemWearUI.__index = ItemWearUI
--local this = LTcpSocket
function ItemWearUI:New(userData)
	local o = LUIBase:New()
	setmetatable(o,ItemWearUI)	
    o:Init(userData)
	return o
end


function ItemWearUI:Init(userData)
    self.m_pUILayer = cc.CSLoader:createNode("csd/ItemWearLayer.csb")
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

    --self:ShowTips(userData)
    --self:ShowModel()
    --self:ShowVersion()
end

function ItemWearUI:InitData()
    self.m_bgClosePanel = self.m_pUILayer:getChildByName("Panel")
    local panel = self.m_pUILayer:getChildByName("Panel_1")
    panel:setTouchEnabled(false)
    local bgPanel = panel:getChildByName("Panel_1_0")
    self.m_pCloseBtn = bgPanel:getChildByName("closeBtn")
    self.m_pNameLabel = bgPanel:getChildByName("Title"):getChildByName("nameLabel")
    self.m_pPowerLabel =  bgPanel:getChildByName("RolePowerBase"):getChildByName("PowerNum")
    local basePanel = bgPanel:getChildByName("Base")
    self.m_pRoleNode = basePanel:getChildByName("Node_1")
    self.m_pTitleImage = basePanel:getChildByName("Image_Sprite")
    self.m_pModelAni = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, 0)
    self.m_pRoleNode:addChild(self.m_pModelAni)  
    self.m_pInfoListView = bgPanel:getChildByName("infoListView")
    self.m_pInfoListView:setItemsMargin(5)--边界

    self.m_pLineImg = bgPanel:getChildByName("Line")
    self.m_pLineImg:retain()
    self.m_pLineImg:removeFromParent()
    self.m_pAttrPanel = bgPanel:getChildByName("Type_2")
    self.m_pAttrPanel:retain()
    self.m_pAttrPanel:removeFromParent()
    self.m_pAttrLabel1 = self.m_pAttrPanel:getChildByName("Attribute1")
    self.m_pAttrLabel1:retain()
    self.m_pAttrLabel1:removeFromParent()
    self.m_pAttrLabel2 = self.m_pAttrPanel:getChildByName("Attribute2")
    self.m_pAttrLabel2:retain()
    self.m_pAttrLabel2:removeFromParent()
    self.m_pDescPanel = bgPanel:getChildByName("Type_3")
    self.m_pDescPanel:retain()
    self.m_pDescPanel:removeFromParent()
    local text = self.m_pDescPanel:getChildByName("Text")
    text:removeFromParent()
    
    self.m_type = ""
    self.m_id = 0
end

function ItemWearUI:InitTouchEvt()
    local function closeCallback(sender)
        self:CloseUI()
    end
    self.m_pCloseBtn:addClickEventListener(closeCallback)
	self:MarkIntaractCObj(self.m_pCloseBtn)
    self.m_bgClosePanel:addClickEventListener(closeCallback)
	self:MarkIntaractCObj(self.m_bgClosePanel)
end

--[[
显示道具
userData数据结构：
{
    （必选）itemType：字符串，可选值有： "Artifact"    神器
                                         "Wing"        翅膀
                                         "Mount"       坐骑
                                         "Title"       称号 
                                         ...按需添加
    （必选）id
    ...后续按需要添加
}
]]
function ItemWearUI:ShowTips(userData)
    if userData == nil then
        return
    end
    self.m_type = userData["itemType"]
    self.m_id = userData["id"]   
    userData["itemType"] = nil
    userData["id"] = nil
    if self.m_type == nil or self.m_id == nil then
        return
    end
    self.m_pTitleImage:setVisible(false)
    self.m_pInfoListView:removeAllChildren()
    if self.m_type == "Wing" then
        self:ShowWingInfo()
    elseif self.m_type == "Mount" then
        self:ShowMountInfo()
    elseif self.m_type == "Artifact" then
        self:ShowArtifactInfo()
    elseif self.m_type == "Title" then
        self:ShowTitleInfo()
    else
        return
    end
    self:ShowModel()
end

function ItemWearUI:ShowWingInfo()
    if self.m_id == nil or self.m_id <= 0 then
        return
    end
    local data = LDataConstMgr:GetWingConfigData(self.m_id)
    if data == nil then return end
    local power =self:ShowWingAttrs(data.attrs)
    self:ShowDesc(data.desc)
    self.m_pNameLabel:setString(data.name)
    self.m_pPowerLabel:setString(power)
end

function ItemWearUI:ShowMountInfo()
    if self.m_id == nil or self.m_id <= 0 then
        return
    end
    local data = LDataConstMgr:GetHorseConfigData(self.m_id)
    if data == nil then return end
    self:ShowMountAttrs(data.attrTypeArr,data.attrValueArr)
    self:ShowDesc(data.desc)
    self.m_pNameLabel:setString(data.name)
    local power = LRoleDataMgr.MyHeroInfo:GetHorsePower(self.m_id,0,0)
    self.m_pPowerLabel:setString(power)
end

function ItemWearUI:ShowArtifactInfo()
    if self.m_id == nil or self.m_id <= 0 then
        return
    end
    local data = LDataConstMgr:GetShenQiById(self.m_id)
    if data == nil then return end
    local power = self:ShowArtifactAttrs(data.m_attrList)
    self:ShowDesc(data.m_desc)
    self.m_pNameLabel:setString(data.m_name)
    self.m_pPowerLabel:setString(power)
end

function ItemWearUI:ShowTitleInfo()
    if self.m_id == nil or self.m_id <= 0 then
        return
    end
    local data = LDataConstMgr:GetMedalNote(self.m_id)
    if data == nil then return end
    local power = self:ShowTitleAttrs(data.newAttribute)
    self:ShowDesc(data.desc)
    self.m_pNameLabel:setString(data.name)
    self.m_pPowerLabel:setString(power)
    self.m_pTitleImage:ignoreContentAdaptWithSize(true)
    self.m_pTitleImage:loadTexture("res/UI/cm_chenghao/chenghao"..self.m_id ..".png", ccui.TextureResType.plistType)
    self.m_pTitleImage:setVisible(true)
end

function ItemWearUI:ShowWingAttrs(attrList)
    if attrList == nil or #attrList == 0 then 
        return
    end
    local power = 0
    local size = self.m_pAttrPanel:getContentSize()
    for i=1,#attrList do
        local attr = self.m_pAttrLabel1:clone()
        local attrType = tonumber(attrList[i][1])
        if attrType ~= nil and attrType > 0 then
            local attrName = LDataConstMgr:GetItemAttrName(attrType)
            if attrName ~= nil and #attrName > 0 then
                attr:setString(attrName..":")
            end
        end
        local attrValueLabel = attr:getChildByName("AttributeNum1")
        local attrValue = tonumber(attrList[i][2])
        if attrValue ~= nil and attrValue > 0 then
            local strValue = " "..attrValue
            if attrType > AppDef.EAttrType.EAT_RESISIT_CRIT then
                strValue = " "..string.format("%.2f",attrValue/100).."%"
            end 
            attrValueLabel:setString(strValue)
        end
        attrValueLabel:setAnchorPoint(cc.p(0,0))
        attrValueLabel:setPosition(cc.p(attr:getContentSize().width,0))
        self.m_pAttrPanel:addChild(attr)
        local y = size.height *(1-0.4* math.ceil(i/2))
        local x = size.width * 0.29
        if i%2 == 0 then
            x = size.width * 0.83  
        end
        attr:setPosition(cc.p(x,y))
        power = power + LDataConstMgr:GetSingleAttrPower(attrType, attrValue)
    end
    self.m_pInfoListView:pushBackCustomItem(self.m_pAttrPanel)
    return power
end

function ItemWearUI:ShowArtifactAttrs(attrList)
    if attrList == nil or #attrList == 0 then 
        return
    end
    local power = 0
    local size = self.m_pAttrPanel:getContentSize()
    for i=1,#attrList do
        local attr = self.m_pAttrLabel1:clone()
        local attrType = attrList[i].attrType
        if attrType ~= nil and attrType > 0 then
            local attrName = LDataConstMgr:GetItemAttrName(attrType)
            if attrName ~= nil and #attrName > 0 then
                attr:setString(attrName..":")
            end
        end
        local attrValueLabel = attr:getChildByName("AttributeNum1")
        local attrValue = attrList[i].attrValue
        if attrValue ~= nil and attrValue > 0 then
             local strValue = " "..attrValue
            if attrType > AppDef.EAttrType.EAT_RESISIT_CRIT then
                strValue = " "..string.format("%.2f",attrValue/100).."%"
            end 
            attrValueLabel:setString(strValue)
        end
        attrValueLabel:setAnchorPoint(cc.p(0,0))
        attrValueLabel:setPosition(cc.p(attr:getContentSize().width,0))
        self.m_pAttrPanel:addChild(attr)
        local y = size.height *(1-0.4* math.ceil(i/2))
        local x = size.width * 0.29
        if i%2 == 0 then
            x = size.width * 0.83  
        end
        attr:setAnchorPoint(self.m_pAttrLabel1:getAnchorPoint())
        attr:setPosition(cc.p(x,y))
        power = power + LDataConstMgr:GetSingleAttrPower(attrType, attrValue)
    end
    self.m_pInfoListView:pushBackCustomItem(self.m_pAttrPanel)
    return power
end

function ItemWearUI:ShowMountAttrs(attrTypes,attrValues)
    if attrTypes == nil or #attrTypes == 0 or attrValues == nil or #attrValues == 0 then 
        return
    end
    local size = self.m_pAttrPanel:getContentSize()
    for i=1,#attrTypes do
        local attr = self.m_pAttrLabel1:clone()
        local attrType = attrTypes[i]
        if attrType ~= nil and attrType > 0 then
            local attrName = LDataConstMgr:GetItemAttrName(attrType)
            if attrName ~= nil and #attrName > 0 then
                attr:setString(attrName..":")
            end
        end
        local attrValueLabel = attr:getChildByName("AttributeNum1")
        local attrValue = attrValues[i]
        if attrValue ~= nil and attrValue > 0 then        
            local strValue = " "..attrValue
            if attrType > AppDef.EAttrType.EAT_RESISIT_CRIT then
                strValue = " "..string.format("%.2f",attrValue/100).."%"
            end 
            attrValueLabel:setString(strValue)
        end
        attrValueLabel:setAnchorPoint(cc.p(0,0))
        attrValueLabel:setPosition(cc.p(attr:getContentSize().width,0))
        self.m_pAttrPanel:addChild(attr)
        local y = size.height *(1-0.4* math.ceil(i/2))
        local x = size.width * 0.29
        if i%2 == 0 then
            x = size.width * 0.83  
        end
        attr:setAnchorPoint(self.m_pAttrLabel1:getAnchorPoint())
        attr:setPosition(cc.p(x,y))
    end
    self.m_pInfoListView:pushBackCustomItem(self.m_pAttrPanel)
end

function ItemWearUI:ShowTitleAttrs(attrList)
    if attrList == nil or #attrList == 0 then 
        return
    end
    local power = 0
    local size = self.m_pAttrPanel:getContentSize()
    for i=1,#attrList do
        local attr = self.m_pAttrLabel1:clone()
        local attrType = attrList[i].type
        if attrType ~= nil and attrType > 0 then
            local attrName = LDataConstMgr:GetItemAttrName(attrType)
            if attrName ~= nil and #attrName > 0 then
                attr:setString(attrName..":")
            end
        end
        local attrValueLabel = attr:getChildByName("AttributeNum1")
        local attrValue = attrList[i].value
        if attrValue ~= nil and attrValue > 0 then
             local strValue = " "..attrValue
            if attrType > AppDef.EAttrType.EAT_RESISIT_CRIT then
                strValue = " "..string.format("%.2f",attrValue/100).."%"
            end 
            attrValueLabel:setString(strValue)
        end
        attrValueLabel:setAnchorPoint(cc.p(0,0))
        attrValueLabel:setPosition(cc.p(attr:getContentSize().width,0))
        self.m_pAttrPanel:addChild(attr)
        local y = size.height *(1-0.4* math.ceil(i/2))
        local x = size.width * 0.29
        if i%2 == 0 then
            x = size.width * 0.83  
        end
        attr:setAnchorPoint(self.m_pAttrLabel1:getAnchorPoint())
        attr:setPosition(cc.p(x,y))
        power = power + LDataConstMgr:GetSingleAttrPower(attrType, attrValue)
    end
    self.m_pInfoListView:pushBackCustomItem(self.m_pAttrPanel)
    return power
end

function ItemWearUI:ShowDesc(str)
    local size = self.m_pDescPanel:getContentSize()
    local lineImg = self.m_pLineImg:clone()
    self.m_pInfoListView:pushBackCustomItem(lineImg)

    local descPanel = self.m_pDescPanel:clone()
    local newLabel = CCAysLabel:createWithString(str, size.width-20, 18, UICOLOR_WHITE_TIPS)
    descPanel:addChild(newLabel)
    newLabel:setPosition(cc.p(2,45))
    self.m_pInfoListView:pushBackCustomItem(descPanel)
end

function ItemWearUI:ShowModel()
    if self.m_id == nil or self.m_id <= 0 then
        return
    end
    local data = LRoleDataMgr.MyHeroInfo
    if self.m_type == "Mount" then
        self.m_pModelAni:InitAni(AppDef.CEnum.ModelAniType.Hero,0,0,0,0,self.m_id,0)
    elseif self.m_type == "Wing" then
        self.m_pModelAni:InitAni(AppDef.CEnum.ModelAniType.Hero,0,0,0,self.m_id,0,0)
    elseif self.m_type == "Artifact" then
        self.m_pModelAni:InitAni(AppDef.CEnum.ModelAniType.Hero,data.professional,data:GetWeaponId(),data.LightEffect,0,0,self.m_id)
    elseif self.m_type == "Title" then
        self.m_pModelAni:InitAni(AppDef.CEnum.ModelAniType.Hero,data.professional,data:GetWeaponId(),data.LightEffect,0,0,0)
    else
        return
    end
    self.m_pModelAni:PlayStand(0)
end

function ItemWearUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_type = nil
    self.m_id = nil
    self.m_bgClosePanel = nil
    self.m_pCloseBtn = nil
    self.m_pNameLabel = nil
    self.m_pPowerLabel =  nil
    self.m_pRoleNode = nil
    self.m_pTitleImage = nil
    self.m_pModelAni = nil
    self.m_pInfoListView = nil

    if self.m_pLineImg then
        self.m_pLineImg:release()
        self.m_pLineImg = nil
    end

    if self.m_pAttrPanel then
        self.m_pAttrPanel:release()
        self.m_pAttrPanel = nil
    end
    if self.m_pAttrLabel1 then
        self.m_pAttrLabel1:release()
        self.m_pAttrLabel1 = nil
    end

    if self.m_pAttrLabel2 then
        self.m_pAttrLabel2:release()
        self.m_pAttrLabel2 = nil
    end

    if self.m_pDescPanel then
        self.m_pDescPanel:release()
        self.m_pDescPanel = nil
    end
    
    self.m_type = nil
    self.m_id = nil
    
end

function ItemWearUI:CloseUI()
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Common.ItemWearUI")
    self:SendMsg(LGameMsg.m_initUIMsg)
end 


return ItemWearUI