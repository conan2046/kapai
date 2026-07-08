local JingJiePreViewUI = LUIBase:New()
JingJiePreViewUI.__index = JingJiePreViewUI

function JingJiePreViewUI:New()
    local o = LUIBase:New()
    setmetatable(o,JingJiePreViewUI)  
    o:Init()
    return o
end

function JingJiePreViewUI:Init()
	self.m_pUILayer = cc.CSLoader:createNode("csd/zhujue/Jingjieyulan.csb")
	self.m_pUILayer:setContentSize(AppDef.frameSize)
	ccui.Helper:doLayout(self.m_pUILayer)
	local function onNodeEvent(event)        
		if "exit" == event then
			self:onExit()
		end
	end
	self.m_pUILayer:registerScriptHandler(onNodeEvent)
	self:InitViewSize()
	self:LoadData()
end

function JingJiePreViewUI:InitViewSize()
	local popup = self.m_pUILayer:getChildByName("Popup")

	local closeBtn = popup:getChildByName("Btn_close")
	closeBtn:addClickEventListener(handler(self, JingJiePreViewUI.CloseUI))
	self:MarkIntaractCObj(closeBtn)

	self.listview = popup:getChildByName("ListView")
	self.item = popup:getChildByName("Panel_1")
end

function JingJiePreViewUI:LoadData()
	local num = #JsonConfig.m_jingjieConfig.getList()
	for i = 1, num do
		local data = JsonConfig.m_jingjieConfig.getDefByID(i)
		if data ~= nil then
			local item = self.item:clone()
			self:InitItemUI(item, data)
			self.listview:pushBackCustomItem(item)
		end
	end
end

function JingJiePreViewUI:InitItemUI(item, data)
	local nameLabel = item:getChildByName("title_bg"):getChildByName("value")
	nameLabel:setString(data.name)
	for i = 1, 7 do
		local attrcell = item:getChildByName("Attribute"..i)
		local value = attrcell:getChildByName("Value")
		if i <= #data.attr then
			Utils:ShowAttrLabelSec(attrcell, data.attr[i][1], value, data.attr[i][2])
		end
	end
end

function JingJiePreViewUI:CloseUI()
	LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "JingJie.JingJiePreViewUI")
    self:SendMsg(LGameMsg.m_initUIMsg)
end

function JingJiePreViewUI:onExit()
	self:Destory()
	self.m_pUILayer = nil
end

return JingJiePreViewUI