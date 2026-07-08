
local HeroBookAllAttrUI = LUIBase:New()
HeroBookAllAttrUI.__index = HeroBookAllAttrUI
--local this = LTcpSocket
function HeroBookAllAttrUI:New()
    local o = LUIBase:New()
    setmetatable(o,HeroBookAllAttrUI)    
    o:Init()
    return o
end

--注册事件
-- -----------------------------------
function HeroBookAllAttrUI:RegistMsgs()
    self.msgIds = 
    {
        -- LUIKaPaiPetEvent.ShowPetLeftInfo,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function HeroBookAllAttrUI:ProcessEvent(msg)
    -- if msg.msgId == LUIKaPaiPetEvent.ShowPetLeftInfo then
    -- end
end

function HeroBookAllAttrUI:Init(data)
    self:InitMembers()
    self:AddTouchEvt()
    self:ShowData()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end

    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

function HeroBookAllAttrUI:InitMembers()
    self.m_pUILayer = cc.CSLoader:createNode("csd/shenjiangyangcheng/yingxiongtujianshuxingLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
    local attrBg = self.m_pUILayer:getChildByName("Popup")
    local starAttrBg = attrBg:getChildByName("Content_1")
    local scoreAttrBg = attrBg:getChildByName("Content_2")

    self.m_blackBg = self.m_pUILayer:getChildByName("Mask")
    self.m_closeBtn = attrBg:getChildByName("Btn_close")
    self.m_starAttrText = {}
    for i=1,4 do
        self.m_starAttrText[i] = starAttrBg:getChildByName("Atrribute_"..i)
        self.m_starAttrText[i]:setVisible(false)
    end

    self.m_scoreAttr = {}
    for i=1,8 do
        self.m_scoreAttr[i] = scoreAttrBg:getChildByName("Atrribute_"..i)
        self.m_scoreAttr[i]:setVisible(false)
    end
end

function HeroBookAllAttrUI:onExit()
    self.m_pUILayer = nil
    self.m_blackBg = nil
    self.m_blackBg = nil
    self.m_closeBtn = nil
    self.m_starAttrText = nil
    self:Destory()
end

function HeroBookAllAttrUI:AddTouchEvt()
    local function ClickCallback(sender)
        LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "HeroBook.HeroBookAllAttrUI")
        LUIManager:SendMsg(LGameMsg.m_deleteUIMsg)
    end
    self.m_blackBg:addTouchEventListener(ClickCallback)
    self:MarkIntaractCObj(self.m_blackBg)
    self.m_closeBtn:addTouchEventListener(ClickCallback)
    self:MarkIntaractCObj(self.m_closeBtn)
end

function HeroBookAllAttrUI:ShowData()
    local idx = 1
    for k,v in ipairs(LRoleDataMgr.m_book.bookAttr) do
        local str = string.format(GUITips.RSI_ZQX_HERO_BOOK9,Utils:getAttrNameAndValue(k,v))
        self.m_starAttrText[idx]:setString(str)
        self.m_starAttrText[idx]:setVisible(true)
        idx = idx + 1
    end

    idx = 1
    for i,v in pairs(LRoleDataMgr.m_book.bookScoreAttr) do
        print(i,v)
        local str = string.format(GUITips.RSI_ZQX_HERO_BOOK9,Utils:getAttrNameAndValue(i,v))
        self.m_scoreAttr[idx]:setString(str) 
        self.m_scoreAttr[idx]:setVisible(true)
        idx = idx + 1
    end
end

return HeroBookAllAttrUI