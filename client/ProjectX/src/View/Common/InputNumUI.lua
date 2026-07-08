--[[
lua里面的游戏逻辑控制
     道具选择UI
]]

local InputNumUI = LUIBase:New()
InputNumUI.__index = InputNumUI
--[[
userData:
userData[1]:maxNum
userData[2]:callback
]]
function InputNumUI:New(userData)
	local o = LUIBase:New()
	setmetatable(o,InputNumUI)	
    o:Init(userData)
	return o
end

function InputNumUI:Init(userData)
    self.m_pUILayer = cc.CSLoader:createNode("csd/EnterNumLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
   -- self:addChild(self.m_pUILayer)
   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:InitData(userData)
    self:InitTouchEvt()
end

function InputNumUI:onExit()
    self:Destory()
    self.m_maxNum = nil
    self.m_callback = nil
    self.m_num = nil
    self.m_pNumTextField = nil
    local cnt = #self.m_pNumBtns
    for i = 1, cnt do
        self.m_pNumBtns[i] = nil
    end
    self.m_pNumBtns = nil
    self.m_pDelBtn = nil
    self.m_pOKBtn = nil
    self.m_pCloseBtn = nil
end

function InputNumUI:UpdateUserData(userData)
    self.m_maxNum = userData[1]--道具类型
    self.m_callback = userData[2]
    -- -1 表示无限制
    if self.m_maxNum < 0 then
        self.m_maxNum = 200
    end
    print("InputNumUI:UpdateUserData ===>", self.m_maxNum)
end

function InputNumUI:InitData(userData)
    self.m_maxNum = userData[1]--道具类型
    self.m_callback = userData[2]
    -- -1 表示无限制
    if self.m_maxNum < 0 then
        self.m_maxNum = 200
    end
    print("InputNumUI:UpdateUserData === 222222222222>", self.m_maxNum)
    self.m_num = 0
    local panel = self.m_pUILayer:getChildByName("Panel"):getChildByName("Bg")
    self.m_pNumTextField = panel:getChildByName("Num"):getChildByName("TextField")
    local btnpanel = panel:getChildByName("BtnList")
    self.m_pNumBtns = {}
    for i = 1, 10 do
        self.m_pNumBtns[i] = btnpanel:getChildByName("Btn" .. (i - 1))
        self.m_pNumBtns[i]:setTag(i - 1)
    end
    self.m_pDelBtn = btnpanel:getChildByName("Btn10")
    self.m_pOKBtn = btnpanel:getChildByName("Btn12")
    self.m_pCloseBtn = panel:getChildByName("Close")
    
 
end

function InputNumUI:InitTouchEvt()
    local function CloseCallBack(sender)
       self:CloseUI()
    end
    self.m_pCloseBtn:addClickEventListener(CloseCallBack)
	self:MarkIntaractCObj(self.m_pCloseBtn)
    local function DeleteBtnCallback(sender)
        self.m_num = math.floor(self.m_num/10)
        self.m_pNumTextField:setString(self.m_num)
    end
    self.m_pDelBtn:addClickEventListener(DeleteBtnCallback)
	self:MarkIntaractCObj(self.m_pDelBtn)
    local function OKBtnCallback(sender)
        self.m_callback(self.m_num)
        self:CloseUI()
    end
    self.m_pOKBtn:addClickEventListener(OKBtnCallback)
	self:MarkIntaractCObj(self.m_pOKBtn)
    local function NumBtnCallback(sender)
        local num = sender:getTag()
        self.m_num = self.m_num*10 + num
        if self.m_maxNum < self.m_num then
            self.m_num = self.m_maxNum
        end
        self.m_pNumTextField:setString(self.m_num)
    end
    for i = 1, 10 do
        self.m_pNumBtns[i]:addClickEventListener(NumBtnCallback)
		self:MarkIntaractCObj(self.m_pNumBtns[i])
    end
end

function InputNumUI:CloseUI()
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Common.InputNumUI")
    self:SendMsg(LGameMsg.m_initUIMsg)
end

return InputNumUI