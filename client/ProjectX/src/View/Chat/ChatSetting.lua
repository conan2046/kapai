--[[
lua chat 表情
]]

local ChatSetting = LUIBase:New()
ChatSetting.__index = ChatSetting

function ChatSetting:New()
	local o = LUIBase:New()
	setmetatable(o,ChatSetting)	
    o:Init()
	return o
end

function ChatSetting:Init()
   
    self.m_pUILayer = cc.CSLoader:createNode("csd/ChannelSetLayer.csb")
    ccui.Helper:doLayout(self.m_pUILayer)

    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)


    self:AddTouchEvt();
end

function ChatSetting:AddTouchEvt()
     --关闭按钮
    local panel = self.m_pUILayer:getChildByName("ChannelSet")
    local btnClose = panel:getChildByName("bg"):getChildByName("Btn_close")

    local function OnCloseButtonClick(sender)
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Chat.ChatSetting")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    btnClose:addClickEventListener(OnCloseButtonClick)
	self:MarkIntaractCObj(btnClose)
    self._selectArr = {}
    local zhChannel = panel:getChildByName("CheckBox1")
    table.insert(self._selectArr, zhChannel)
    local worldChannel = panel:getChildByName("CheckBox2")
    table.insert(self._selectArr, worldChannel)
    local curChannel = panel:getChildByName("CheckBox3")
    table.insert(self._selectArr, curChannel)
    local bpChannel = panel:getChildByName("CheckBox4")
    table.insert(self._selectArr, bpChannel)
    local teamChannel = panel:getChildByName("CheckBox5")
    table.insert(self._selectArr, teamChannel)
    local sysChannel = panel:getChildByName("CheckBox6")
    table.insert(self._selectArr, sysChannel)
    
end

function ChatSetting:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

return ChatSetting