
local FragmentTransUI = LUIBase:New()
FragmentTransUI.__index = FragmentTransUI
--local this = LTcpSocket
function FragmentTransUI:New(itemId)
	local o = LUIBase:New()
	setmetatable(o,FragmentTransUI)	
    o:Init(itemId)
	return o
end

--注册事件
-- -----------------------------------
function FragmentTransUI:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

local JIANYI = 1
local JIANSHI = 2
local ZENGJIAYI = 3
local JIADAOZUIDA = 4
-- -----------------------------------
function FragmentTransUI:ProcessEvent(msg)

end

function FragmentTransUI:Init(itemId)

    self.m_pUILayer = cc.CSLoader:createNode("csd/wannengsuipianLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:initData(itemId)
    self:initControlUI()
end

function FragmentTransUI:initData( itemId )
    -- body
    self._itemId = itemId
end

function FragmentTransUI:initControlUI( ... )
    -- body
    local Popup = self.m_pUILayer:getChildByName("Popup")
    local Btn_close = Popup:getChildByName("Btn_close")
    
    Btn_close:addClickEventListener(function ( sender )
        -- body
        self:closeUI()
    end)


    self._Icon1 = Popup:getChildByName("IconColor_1")
    self._targetIcon = Popup:getChildByName("IconColor_2")
    self._text = Popup:getChildByName("Count"):getChildByName("Value")

    local Button_M1 = Popup:getChildByName("Button_-")
    Button_M1:setTag(JIANYI)
    Button_M1:addClickEventListener(handler(self, FragmentTransUI.ChangeEventAmount))
    self:MarkIntaractCObj(Button_M1)
    local Button_P1 = Popup:getChildByName("Button_+")
    Button_P1:setTag(ZENGJIAYI)
    Button_P1:addClickEventListener(handler(self, FragmentTransUI.ChangeEventAmount))
    self:MarkIntaractCObj(Button_P1)
    local Button_M10 = Popup:getChildByName("Button_-10")
    Button_M10:setTag(JIANSHI)
    Button_M10:addClickEventListener(handler(self, FragmentTransUI.ChangeEventAmount))
    self:MarkIntaractCObj(Button_M10)
    local Button_PMax = Popup:getChildByName("Button_+N")
    Button_PMax:setTag(JIADAOZUIDA)
    Button_PMax:addClickEventListener(handler(self, FragmentTransUI.ChangeEventAmount))

end

function FragmentTransUI:ChangeEventAmount( sender )
    -- body
    local tag = sender:getTag()
    local amount = 1
    if tag == JIANYI then
        amount = 1
    elseif tag == JIANSHI then
        amount = 10
    elseif tag == ZENGJIAYI then
        amount = 2
    elseif tag == JIADAOZUIDA then
        amount = 11
    end
    self:setAmount(amount)
end

function FragmentTransUI:setAmount( amount )
    -- body
    self._text:setString(tostring(amount))
end

function FragmentTransUI:updateUI( ... )
    -- body

end

function FragmentTransUI:closeUI( ... )
    -- body
    Utils:DeleteUI("Common.FragmentTransUI")
end

function FragmentTransUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

return FragmentTransUI