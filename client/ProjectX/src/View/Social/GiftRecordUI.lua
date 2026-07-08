
local GiftRecordUI = LUIBase:New()
GiftRecordUI.__index = GiftRecordUI
--local this = LTcpSocket
function GiftRecordUI:New()
	local o = LUIBase:New()
	setmetatable(o,GiftRecordUI)	
    o:Init()
	return o
end

local GiveOtherTab = 1
local GiveMeTab = 2


--[[
注册消息
]]
function GiftRecordUI:RegistMsgs()
    self.msgIds = 
    {
         LUIGiveGiftEvent.updateXianHuaRecord,
         LUIGiveGiftEvent.xianHuaRecordNeedRefresh,
         LUIGiveGiftEvent.updateMeili,
    }
    self:RegistSelf(self,self.msgIds)
end

function GiftRecordUI:ProcessEvent(msg)
    if msg:GetMsgId() == LUIGiveGiftEvent.updateXianHuaRecord then
        self:loadData(msg.value)
    end

    if msg:GetMsgId() == LUIGiveGiftEvent.xianHuaRecordNeedRefresh then
        self._isNeedRefash = true
    end

    if msg:GetMsgId() == LUIGiveGiftEvent.updateMeili then
        self._mieliText:setString(LRoleDataMgr.MyHeroInfo.meili)
    end
end

function GiftRecordUI:Init()

    self.m_pUILayer = cc.CSLoader:createNode("csd/GiftsListLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs();
    self:initUI()
end

function GiftRecordUI:initUI( )
    -- body
    self._channel = GiveOtherTab;

    local panel = self.m_pUILayer:getChildByName("Panel")
    local role = panel:getChildByName("RoleBg"):getChildByName("Role")
    self.m_pNameLabel = role:getChildByName("RoleName"):getChildByName("Name")
    self.m_pRoleNode = role:getChildByName("RoleBase"):getChildByName("RoleNode")
    self.m_pRoleModel = nil

    self._mieliText = role:getChildByName("CharmBg"):getChildByName("Value")
    self._mieliText:setString(LRoleDataMgr.MyHeroInfo.meili)

    local GiveScreem = panel:getChildByName("GiveScreem")
    self._Btn1 = GiveScreem:getChildByName("Btn1")

    local function OnGiveOtherChatButtonClick(sender)
        if(self._channel == GiveOtherTab) then
            return
        end
        self._channel = GiveOtherTab
        self:updateBtnStat();

        if self._isNeedRefash then
            self._isNeedRefash = false
            LuaNetSendMsg:QueryGetXianHuaRecord(self._channel)
        else
            if #self._GiveList <= 0 then
                LuaNetSendMsg:QueryGetXianHuaRecord(self._channel)
            end
        end
    end
    self._Btn1:addClickEventListener(OnGiveOtherChatButtonClick)
	self:MarkIntaractCObj(self._Btn1)
    self._BtnNameOther1 = self._Btn1:getChildByName("BtnName_1")
    self._BtnNameOther2 = self._Btn1:getChildByName("BtnName_2")

    self._Btn2 = GiveScreem:getChildByName("Btn2")
    local function OnGiveMeChatButtonClick(sender)
        if(self._channel == GiveMeTab) then
            return
        end
        self._channel = GiveMeTab
        self:updateBtnStat();

        if #self._receiveList <= 0 then
            LuaNetSendMsg:QueryGetXianHuaRecord(self._channel)
        end

    end
    self._Btn2:addClickEventListener(OnGiveMeChatButtonClick)
	self:MarkIntaractCObj(self._Btn2)
    self._BtnNameMe1 = self._Btn2:getChildByName("BtnName_1")
    self._BtnNameMe2 = self._Btn2:getChildByName("BtnName_2")

    self._GiveBg_1 = GiveScreem:getChildByName("GiveBg_1")
    self._GiveOtherList = self._GiveBg_1:getChildByName("List")
    self._pCell1 = self._GiveBg_1:getChildByName("Desc_1")
    self._pCell1:setVisible(false)

    self._GiveBg_2 = GiveScreem:getChildByName("GiveBg_2")
    self._GiveMeList = self._GiveBg_2:getChildByName("List")
    self._pCell2 = self._GiveBg_2:getChildByName("Desc_1")
    self._pCell2:setVisible(false)

    self:ShowRoleModel()
    self:ShowRoleName()

    self:updateBtnStat()

--赠送列表
    self._GiveList = {}

--受赠列表
    self._receiveList = {}

    self._isNeedRefash = true

    LuaNetSendMsg:QueryGetXianHuaRecord(self._channel)

end


function GiftRecordUI:loadData(list)
    -- body
--    Utils:dump(list)
    self._GiveList = {}
    self._receiveList = {}
    for i = 1, #list.recordArr do
        if list.recordType == GiveOtherTab then
            table.insert(self._GiveList, list.recordArr[i])
        else 
            table.insert(self._receiveList, list.recordArr[i])
        end
    end

    if list.recordType == GiveOtherTab then
        self._GiveOtherList:removeAllItems()
        for i=1, #self._GiveList do
            local item = self._pCell1:clone();
--            item:getChildByName("Text"):setString(self._GiveList[i].buf)
            local text = item:getChildByName("Text")
            local pAysLabel = Utils:CreateColorText2(item, text)
            pAysLabel:setString(self._GiveList[i].buf)
            item:setVisible(true)
            self._GiveOtherList:pushBackCustomItem(item)
        end
        self._GiveOtherList:jumpToTop()
    else
        self._GiveMeList:removeAllItems()
        for i=1, #self._receiveList do
            local item = self._pCell2:clone();
--            item:getChildByName("Text"):setString(self._receiveList[i].buf)
            local text = item:getChildByName("Text")
            local pAysLabel = Utils:CreateColorText2(item, text)
            pAysLabel:setString(self._receiveList[i].buf)

            item:setVisible(true)
            self._GiveMeList:pushBackCustomItem(item)
        end
        self._GiveMeList:jumpToTop()
    end

end

function GiftRecordUI:updateBtnStat()
    
    local isGiveOtherTab = (self._channel == GiveOtherTab)
    print("GiftRecordUI:updateBtnStat isGiveOtherTab", isGiveOtherTab)

    self._GiveBg_1:setVisible(isGiveOtherTab)
    self._GiveBg_2:setVisible(not isGiveOtherTab)

    self._Btn1:setBright(not isGiveOtherTab)
    self._Btn2:setBright(isGiveOtherTab)

    self._BtnNameOther1:setVisible(isGiveOtherTab)
    self._BtnNameOther2:setVisible(not isGiveOtherTab)

    self._BtnNameMe1:setVisible(not isGiveOtherTab)
    self._BtnNameMe2:setVisible(isGiveOtherTab)
    

end

function GiftRecordUI:ShowRoleModel()
    local data = LRoleDataMgr.MyHeroInfo
    if self.m_pRoleModel == nil then
        self.m_pRoleModel = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, 
                                            data.professional, 
                                            data:GetWeaponId(), 
                                            data.LightEffect,
                                            data.WingsId,
                                            data:GetHorseId(),
                                            data:GetShenQiId())
        self.m_pRoleNode:addChild(self.m_pRoleModel)
    else
        self.m_pRoleModel:InitAni(AppDef.CEnum.ModelAniType.Hero, 
                                            data.professional, 
                                            data:GetWeaponId(), 
                                            data.LightEffect,
                                            data.WingsId,
                                            data:GetHorseId(),
                                            data:GetShenQiId())
    end
    self.m_pRoleModel:PlayStand(0)
    
end

function GiftRecordUI:ShowRoleName()
    self.m_pNameLabel:setString(LRoleDataMgr.MyHeroInfo.name)
end

function GiftRecordUI:onExit()
    self.m_pUILayer = nil
    self.m_pNameLabel = nil
    self.m_pRoleNode = nil
    self.m_pRoleModel = nil
    self._mieliText = nil
    self._Btn1 = nil
    self._BtnNameOther1 = nil
    self._BtnNameOther2 = nil
    self._Btn2 = nil

    self._BtnNameMe1 = nil
    self._BtnNameMe2 = nil

    self._GiveBg_1 = nil
    self._GiveOtherList = nil
    self._pCell1 = nil

    self._GiveBg_2 = nil
    self._GiveMeList = nil
    self._pCell2 = nil

--赠送列表
    Utils:FreeTable(self._GiveList)
--受赠列表
    Utils:FreeTable(self._receiveList)
    self._isNeedRefash = nil
    self:Destory()
end

function GiftRecordUI:refreshUI( )
    -- body
    if self._isNeedRefash then
        self._isNeedRefash = false
        LuaNetSendMsg:QueryGetXianHuaRecord(self._channel)
    end
end

return GiftRecordUI