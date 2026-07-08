--[[
通用按钮列表弹出框
userData:{
    {btnName,callback},
    {btnName,callback},
    {btnName,callback},
    ...
    pos,
}
]]
local BtnBoxUI = LUIBase:New()
BtnBoxUI.__index = BtnBoxUI
local ScriptPath = "Common.BtnBoxUI"
function BtnBoxUI:New(userData)
    userData = userData or {}
	local o = LUIBase:New()
	setmetatable(o,BtnBoxUI)	
    o:Init(userData)
	return o
end

function BtnBoxUI:Init(userData)
    self.m_pUILayer = cc.CSLoader:createNode("csd/BtnListLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:InitData()
    self:InitBtns(userData)
end

--[[
注册UI消息
]]
function BtnBoxUI:RegistMsgs()
    -- self.msgIds = 
    -- {
    --     LUIMsgBoxEvent.ShowMsgBox,
    -- }
    -- self:RegistSelf(self,self.msgIds)
end

function BtnBoxUI:ProcessEvent(msg)
    -- if msg:GetMsgId() == LUIMsgBoxEvent.ShowMsgBox then
    --     self:UpdateUserData(msg.value)
    -- end
end

function BtnBoxUI:onExit()
    self.m_pUILayer = nil
    self.m_pUserData = nil
    self.m_pListView = nil
    self.m_pBaseBtn = nil
    self:Destory()
end

function BtnBoxUI:InitData()
    local panel = self.m_pUILayer:getChildByName("Panel")
    self.m_pListView = panel:getChildByName("BtnList")
    self.m_pBaseBtn = self.m_pListView:getChildByName("Button_1")
    self.m_pBaseBtn:setTag(1)
end

function BtnBoxUI:InitBtns(userData)
    self.m_pUserData = userData
    local function CloseCallBack(sender)
       self:HandleClose()
    end
    local panel = self.m_pUILayer:getChildByName("Panel")
    panel:addClickEventListener(CloseCallBack)
	self:MarkIntaractCObj(panel)
    local function BtnCallback(sender)
        local ind = sender:getTag()
        self.m_pUserData[ind][2]()
        self:HandleClose()
    end
    if #userData == 0 then
        return
    end
    self.m_pBaseBtn:addClickEventListener(BtnCallback)
	self:MarkIntaractCObj(self.m_pBaseBtn)
    local label
    label = self.m_pBaseBtn:getChildByName("Text")
    label:setString(userData[1][1])
    for i = 2, #userData do
        local btn = self.m_pBaseBtn:clone()
        label = btn:getChildByName("Text")
        label:setString(userData[i][1])
        btn:setTag(i)
        self.m_pListView:pushBackCustomItem(btn)
    end
    local size = self.m_pListView:getContentSize()
    if #userData < 5 then
        size.height = self.m_pBaseBtn:getContentSize().height * #userData
        self.m_pListView:setContentSize(size)
        self.m_pListView:setTouchEnabled(false)
    end
    if userData.pos ~= nil then

        local screenSize = cc.Director:getInstance():getWinSize()

        if userData.pos.y < self.m_pListView:getContentSize().height then
            userData.pos.y = self.m_pListView:getContentSize().height
        end

        if userData.pos.y > screenSize.height then
            userData.pos.y = screenSize.height
        end

        if userData.pos.x > screenSize.width - self.m_pListView:getContentSize().width * 1.5 then
            userData.pos.x = screenSize.width - self.m_pListView:getContentSize().width * 1.5
        end

        if userData.pos.x < 0 then
            userData.pos = 0
        end

        self.m_pListView:setPosition(userData.pos)
    end
end

function BtnBoxUI:HandleClose()
	LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, ScriptPath)
    self:SendMsg(LGameMsg.m_initUIMsg)
end

return BtnBoxUI