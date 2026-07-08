
local BookActivateUI = LUIBase:New()
BookActivateUI.__index = BookActivateUI
--local this = LTcpSocket
function BookActivateUI:New()
    local o = LUIBase:New()
    setmetatable(o,BookActivateUI)    
    o:Init()
    return o
end

--注册事件
-- -----------------------------------
function BookActivateUI:RegistMsgs()
    self.msgIds = 
    {
        -- LUIKaPaiPetEvent.ShowPetLeftInfo,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function BookActivateUI:ProcessEvent(msg)
    -- if msg.msgId == LUIKaPaiPetEvent.ShowPetLeftInfo then
    -- end
end

function BookActivateUI:Init()
    self:InitMembers()
    self:ShowData()
    self:AddTouchEvt()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end

    self.m_pUILayer:registerScriptHandler(onNodeEvent)

end

function BookActivateUI:InitMembers()
    self.m_pUILayer = cc.CSLoader:createNode("csd/shenjiangyangcheng/yingxiongjihuoendLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
    self.m_blackBg=self.m_pUILayer:getChildByName("jihuochengjiuUI")
    self.m_pAtrributes={}
    for i=1,3 do
        table.insert(self.m_pAtrributes,self.m_blackBg:getChildByName("Atrribute_"..i))
    end
    self.m_pTuJianText=self.m_blackBg:getChildByName("tujianzhi")
end

function BookActivateUI:onExit()
    self.m_pUILayer = nil
    self.m_blackBg = nil
    self:Destory()
end

function BookActivateUI:AddTouchEvt()
    local function ClickCallback(sender)
        LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "HeroBook.BookActivateUI")
        LUIManager:SendMsg(LGameMsg.m_deleteUIMsg)
    end
    self.m_blackBg:addTouchEventListener(ClickCallback)
    self:MarkIntaractCObj(self.m_blackBg)
end

function BookActivateUI:ShowData()
    local queryLevel = LRoleDataMgr.m_book.curLevel
    if queryLevel < #JsonConfig.m_heroBook.getList() then
        queryLevel = queryLevel + 1
    end
    local bookCfg = JsonConfig.m_heroBook.getDefByID(queryLevel)
    if bookCfg ~= nil then
        for i=1,#bookCfg.attr do
            local attr = bookCfg.attr[i]
            if self.m_pAtrributes[i] ~= nil then
                local desc,value= Utils:getAttrNameAndValue(attr[1],attr[2])
                self.m_pAtrributes[i]:setString(GUITips.RSI_ZQX_HERO_BOOK15..desc..":")
                self.m_pAtrributes[i]:getChildByName("Value"):setString("+"..tostring(value))
            end
        end
        for i=1,#self.m_pAtrributes do
            if i>#bookCfg.attr then
                self.m_pAtrributes[i]:setVisible(false)
            end    
        end
    end
    self.m_pTuJianText:setString(GUITips.RSI_ZQX_HERO_BOOK14..tostring(LRoleDataMgr.m_book.curScore))   
end

return BookActivateUI