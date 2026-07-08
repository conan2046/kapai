
local HeroBookNextAttrUI = LUIBase:New()
HeroBookNextAttrUI.__index = HeroBookNextAttrUI
--local this = LTcpSocket
function HeroBookNextAttrUI:New(data)
    local o = LUIBase:New()
    setmetatable(o,HeroBookNextAttrUI)    
    o:Init(data)
    return o
end

--注册事件
-- -----------------------------------
function HeroBookNextAttrUI:RegistMsgs()
    self.msgIds = 
    {
        -- LUIKaPaiPetEvent.ShowPetLeftInfo,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function HeroBookNextAttrUI:ProcessEvent(msg)
    -- if msg.msgId == LUIKaPaiPetEvent.ShowPetLeftInfo then
    -- end
end

function HeroBookNextAttrUI:Init(data)
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

function HeroBookNextAttrUI:InitMembers()
    self.m_pUILayer = cc.CSLoader:createNode("csd/shenjiangyangcheng/yingxiongtujianchengjiuLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    local bg = self.m_pUILayer:getChildByName("Popup")
    self.m_blackBg = self.m_pUILayer:getChildByName("Mask")
    self.m_clostBtn = bg:getChildByName("Btn_close")
    self.m_curScore = bg:getChildByName("tujianzhi"):getChildByName("Value")
    self.m_levelScore = bg:getChildByName("Tips")
    self.m_bookAttrListView = bg:getChildByName("ListView")
    self.m_item = bg:getChildByName("Item")
    for j=1,3 do
        local text = self.m_item:getChildByName("Attribute_"..j)
        if text ~= nil then
            text:setVisible(false)
        end
    end
    self.m_blackBg:setSwallowTouches(true)
end

function HeroBookNextAttrUI:onExit()
    self.m_pUILayer = nil
    self.m_blackBg = nil
    self.m_clostBtn = nil
    self.m_curScore = nil
    self.m_levelScore = nil
    self.m_bookAttrListView = nil
    self.m_item = nil
    self:Destory()
end

function HeroBookNextAttrUI:AddTouchEvt()
    local function ClickCallback(sender)
        LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "HeroBook.HeroBookNextAttrUI")
        LUIManager:SendMsg(LGameMsg.m_deleteUIMsg)
    end
    self.m_blackBg:addTouchEventListener(ClickCallback)
    self:MarkIntaractCObj(self.m_blackBg)
    self.m_clostBtn:addClickEventListener(ClickCallback)
    self:MarkIntaractCObj(self.m_clostBtn)
end

function HeroBookNextAttrUI:ShowData(sucInfo)
    local queryLevel = LRoleDataMgr.m_book.curLevel
    print("LRoleDataMgr.m_book.curLevel ===>", LRoleDataMgr.m_book.curLevel)
    if queryLevel < #JsonConfig.m_heroBook.getList() then
        queryLevel = queryLevel + 1
    end
    local bookCfg = JsonConfig.m_heroBook.getDefByID(queryLevel)
    if bookCfg ~= nil then
        self.m_levelScore:setString(string.format(GUITips.RSI_ZQX_HERO_BOOK8, bookCfg.handbook_value))
        self.m_curScore:setString(tostring(LRoleDataMgr.m_book.curScore))
    end

    local allCfg = JsonConfig.m_heroBook.getList()
    for i=1,#allCfg do
        local item = self.m_item:clone()
        local bookCfg = allCfg[i]
        item:getChildByName("Title"):setString(string.format(GUITips.RSI_ZQX_HERO_BOOK7, bookCfg.handbook_value))
        if LRoleDataMgr.m_book.curLevel >= i then
            item:getChildByName("Title"):setTextColor(AppDef.UIColor.GREEN)
        end
        for j=1,#bookCfg.attr do
            local attr = bookCfg.attr[j]
            local str = string.format(GUITips.RSI_ZQX_HERO_BOOK9, Utils:getAttrNameAndValue(attr[1], attr[2]))
            local text = item:getChildByName("Attribute_"..j)
            if text ~= nil then
                text:setString(str)
                if LRoleDataMgr.m_book.curLevel >= i then
                    text:setTextColor(AppDef.UIColor.GREEN)
                end
            end
            text:setVisible(true)
        end
        self.m_bookAttrListView:pushBackCustomItem(item)
    end
end

return HeroBookNextAttrUI