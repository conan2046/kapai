
local BoxInfoUI = LUIBase:New()
BoxInfoUI.__index = BoxInfoUI
--local this = LTcpSocket
function BoxInfoUI:New()
	local o = LUIBase:New()
	setmetatable(o,BoxInfoUI)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function BoxInfoUI:RegistMsgs()
    self.msgIds = 
    {
        LUIWeiWoDuXianEvent.UpdateBoxInfo
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function BoxInfoUI:ProcessEvent(msg)
    if msg.msgId == LUIWeiWoDuXianEvent.UpdateBoxInfo then
        self:UpdateBoxInfo(msg.value)
    end
end

function BoxInfoUI:Init()

    self.m_pUILayer = cc.CSLoader:createNode("csd/ItemInfoLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:InitControlUI()

end

function BoxInfoUI:InitControlUI( ... )
    -- body
    local panel = self.m_pUILayer:getChildByName("Panel")
    local Panel_1 = self.m_pUILayer:getChildByName("Panel_1")
    local Panel_1_0 = Panel_1:getChildByName("Panel_1_0")
    local Btn_ListView = Panel_1_0:getChildByName("Btn_ListView")
    Btn_ListView:setVisible(false)

    local closeBtn = Panel_1_0:getChildByName("closeBtn")
    local function closeEvent( sender )
        -- body
        self:CloseDialog()
    end
    closeBtn:addClickEventListener(closeEvent)
	self:MarkIntaractCObj(closeBtn) 

    local image3 = Panel_1_0:getChildByName("Image_3")
    image3:setVisible(false)

    local typeLabel = Panel_1_0:getChildByName("typeLabel")
    typeLabel:setVisible(false)

    self._imageIcon = Panel_1_0:getChildByName("Image_4")

    
    self._nameLabel = Panel_1_0:getChildByName("nameLabel")

    self._powerLabel = Panel_1_0:getChildByName("powerLabel")

    self._infoListView = Panel_1_0:getChildByName("infoListView")

    self._pCell = Panel_1_0:getChildByName("Type_3")
end

function BoxInfoUI:UpdateBoxInfo( data )
    -- body
--    dump(data, "box data")
    if data == nil then
        return
    end

    local id = data[1]
    local strSlite = data[2]
    local desParts = string.split(strSlite, "|")
--    dump(desParts, "UpdateBoxInfo")

    --3000 -------> 3004
    local strPath = string.format("item/equip%d.png", 3000 + (5 - id))    
    self._imageIcon:loadTexture(strPath, UI_TEX_TYPE_LOCAL)

    self._nameLabel:setString(desParts[1])
    self._powerLabel:setString(desParts[2])
    

    local awardArr = string.split(desParts[3], ",")
    for i=1, #awardArr do
        local item = self._pCell:clone()
        self._infoListView:pushBackCustomItem(item)
        local text = item:getChildByName("DescribeText")
        text:setString(awardArr[i])
    end

    if string.len(desParts[4]) > 0 then
        local item = self._pCell:clone()
        self._infoListView:pushBackCustomItem(item)
        local text = item:getChildByName("DescribeText")
        text:setString(desParts[4])
    end

    if string.len(desParts[5]) > 0 then
        local item = self._pCell:clone()
        self._infoListView:pushBackCustomItem(item)
        local text = item:getChildByName("DescribeText")
        text:setString(desParts[5])
    end


end

function BoxInfoUI:CloseDialog( ... )
    -- body
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "ZhengBa.BoxInfoUI")
    self:SendMsg(LGameMsg.m_initUIMsg)
end

function BoxInfoUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

return BoxInfoUI