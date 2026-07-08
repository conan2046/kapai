
local HeroBookActivateUI = LUIBase:New()
HeroBookActivateUI.__index = HeroBookActivateUI
--local this = LTcpSocket
function HeroBookActivateUI:New(data)
    local o = LUIBase:New()
    setmetatable(o,HeroBookActivateUI)    
    o:Init(data)
    return o
end

--注册事件
-- -----------------------------------
function HeroBookActivateUI:RegistMsgs()
    self.msgIds = 
    {
        -- LUIKaPaiPetEvent.ShowPetLeftInfo,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function HeroBookActivateUI:ProcessEvent(msg)
    -- if msg.msgId == LUIKaPaiPetEvent.ShowPetLeftInfo then
    -- end
end

function HeroBookActivateUI:Init(data)
    self:InitMembers()
    self:ShowData(data)
    self:AddTouchEvt()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end

    self.m_pUILayer:registerScriptHandler(onNodeEvent)

end

function HeroBookActivateUI:InitMembers()
    self.m_pUILayer = cc.CSLoader:createNode("csd/shenjiangyangcheng/yingxiongtujianendLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
    self.m_blackBg = self.m_pUILayer:getChildByName("jihuochenggongUI")
    self.m_heroText = self.m_blackBg:getChildByName("Text")
    self.m_heroIconColor = self.m_blackBg:getChildByName("IconColor")
    self.m_heroIcon = self.m_heroIconColor:getChildByName("Icon")
    self.m_bookScoreText = self.m_blackBg:getChildByName("tujianzhi")
    self.m_attrText = {}
    for i=1,4 do
        self.m_attrText[i] = self.m_blackBg:getChildByName("Atrribute_"..i)
        self.m_attrText[i]:setVisible(false)
    end
end

function HeroBookActivateUI:onExit()
    self.m_pUILayer = nil
    self.m_blackBg = nil
    self.m_heroText = nil
    self.m_heroIconColor = nil
    self.m_heroIcon = nil
    self.m_bookScoreText = nil
    self.m_attrText = nil
    self:Destory()
end

function HeroBookActivateUI:AddTouchEvt()
    local function ClickCallback(sender)
        LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "HeroBook.HeroBookActivateUI")
        LUIManager:SendMsg(LGameMsg.m_deleteUIMsg)
        if  self.upgradeLevel==true then
            Utils:InitUI("HeroBook.BookActivateUI", AppDef.UIType.PopWindow)
        end
    end
    self.m_blackBg:addTouchEventListener(ClickCallback)
    self:MarkIntaractCObj(self.m_blackBg)
end

function HeroBookActivateUI:ShowData(sucInfo)
    self.upgradeLevel=sucInfo.upgradeLevel
    local petData = LRoleDataMgr.Pet:GetPetById(sucInfo.heroId)
    Utils:ShowPetHeadImg(self.m_heroIcon, petData.baseData.pic,
        self.m_heroIconColor, petData.baseData.quality, petData:IsShiny())
    self.m_heroText:setString(string.format(GUITips.RSI_ZQX_HERO_BOOK1, petData.baseData.name))
    self.m_bookScoreText:getChildByName("Value"):setString(tostring(sucInfo.addScore))
    for i=1,#sucInfo.cardAttr do
        if i < 5 then
            local attr = sucInfo.cardAttr[i]
            local str = string.format(GUITips.RSI_ZQX_HERO_BOOK3, Utils:getAttrName(attr.type))
            self.m_attrText[i]:setString(str)
            self.m_attrText[i]:getChildByName("Value"):setString(tostring(attr.value))
            self.m_attrText[i]:setVisible(true)
        end
    end
end

return HeroBookActivateUI