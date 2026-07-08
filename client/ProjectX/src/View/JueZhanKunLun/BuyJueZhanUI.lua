local BuyJueZhanUI = LUIBase:New()
BuyJueZhanUI.__index = BuyJueZhanUI

BuyJueZhanUI.IsHideInBattle = true
function BuyJueZhanUI:New(data)
    local o = {}
    setmetatable(o, BuyJueZhanUI)
    o:Init(data)
    return o
end

function BuyJueZhanUI:Init(data)
	self.m_pUILayer = nil
	self.buynum = 1
	self.buydata = {}
	self:InitViewSize()
	self:InitUIControl()
	self:LoadData(data)
end

function BuyJueZhanUI:InitViewSize()
	self:CreateUINode("csd/common/daojugoumai.csb")
	local popup = self.m_pUILayer:getChildByName("Popup")
	popup:getChildByName("Panel_1"):setVisible(false)
	popup:getChildByName("CheckBox"):setVisible(false)
end

function BuyJueZhanUI:InitUIControl()
	local popup = self.m_pUILayer:getChildByName("Popup")

	self.mineLabel = popup:getChildByName("Panel_2"):getChildByName("text"):getChildByName("mine")
	
	local panel3 = popup:getChildByName("Panel_3")
	panel3:getChildByName("Btn_Minus10"):setVisible(false)
	panel3:getChildByName("Btn_Plus10"):setVisible(false)

	self.buyLabel = panel3:getChildByName("Count"):getChildByName("Value")
	
	local subBtn = panel3:getChildByName("Btn_Minus")
	subBtn:addClickEventListener(handler(self, BuyJueZhanUI.SubClicked))
	self:MarkIntaractCObj(subBtn)
	local addBtn = panel3:getChildByName("Btn_Plus")
	addBtn:addClickEventListener(handler(self, BuyJueZhanUI.AddClicked))
	self:MarkIntaractCObj(addBtn)

	local panel4 = popup:getChildByName("Panel_4")
	self.maxLabel = panel4:getChildByName("text1"):getChildByName("buy_num")
	self.vipLabel = panel4:getChildByName("text1"):getChildByName("vip")
	self.vipLabel:setVisible(false)
	
	local closeBtn = popup:getChildByName("Btn_close")
	closeBtn:addClickEventListener(handler(self, BuyJueZhanUI.CloseUI))
	self:MarkIntaractCObj(closeBtn)

	local buyBtn = popup:getChildByName("Btn_Buy")
	buyBtn:addClickEventListener(handler(self, BuyJueZhanUI.BuyClicked))
	self:MarkIntaractCObj(buyBtn)
	buyBtn:getChildByName("use"):setVisible(false)
	self.costlayer = buyBtn:getChildByName("buy_layer")
	local icon = self.costlayer:getChildByName("Icon_item")
	local path = "res/UI/ui_common/ui_icon_yuanbao.png"
	Utils:SafeLoadTexture(icon, path,ccui.TextureResType.plistType)
end

function BuyJueZhanUI:LoadData(data)
	local cfg = JsonConfig.m_config.getDefByID(5)
	if cfg ~= nil then
		self.buydata = json.decode(cfg.value)
	end
	self.curnum = data[1]
	self.maxbuynum = data[2]

	self.mineLabel:setString(tostring(self.curnum))
	self.maxLabel:setString(tostring(self.maxbuynum))
	self.buyLabel:setString(self.buynum)
	self:UpdateCost()
end

function BuyJueZhanUI:UpdateCost()
	local costLabel = self.costlayer:getChildByName("Text")

	local costnum = 0
	local index = #self.buydata - self.maxbuynum
	for i = 1,self.buynum do
		local num = self.buydata[index + i]
		costnum = costnum + num
	end
	costLabel:setString(costnum)

	local myLabel = self.costlayer:getChildByName("text"):getChildByName("mine")
	local myMoney = LRoleDataMgr.MyHeroInfo.DetailData:GetKunLunMoney()
	myLabel:setString(myMoney)
end

function BuyJueZhanUI:SubClicked(sender)
	if self.buynum == 0 then
		return
	end
	self.buynum = self.buynum - 1
	self.buyLabel:setString(tostring(self.buynum))
	self:UpdateCost()
end

function BuyJueZhanUI:AddClicked(sender)
	if self.buynum == self.maxbuynum then
		return
	end
	self.buynum = self.buynum + 1
	self.buyLabel:setString(tostring(self.buynum))
	self:UpdateCost()
end

function BuyJueZhanUI:BuyClicked(sender)
	LuaNetSendMsg:BuyKunLunFightNum(self.buynum )
	self:CloseUI()
end

function BuyJueZhanUI:CloseUI(sender)
	LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "JueZhanKunLun.BuyJueZhanUI")
    self:SendMsg(LGameMsg.m_initUIMsg)
end

function BuyJueZhanUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

function BuyJueZhanUI:onExit()
	self:Destory()
	self.m_pUILayer = nil
end

return BuyJueZhanUI