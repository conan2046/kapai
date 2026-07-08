local FundRebateUI = LUIBase:New()
FundRebateUI.__index = FundRebateUI

local subLayers = {
	"View.WelfareActivity.FundRebate",
}
-----------------------------------
function FundRebateUI:New(tab)
    local o = {}
    setmetatable(o, FundRebateUI)
    o:Init(tab)
    return o
end
-----------------------------------
function FundRebateUI:Init(tab)
    self.Script = "WelfareActivity.FundRebateUI"
    --------------------------------------
    self.m_initTab = tab or 1
    self.m_selectTab = 0
    self.uiLayers = {}
    --------------------------------------
    self.m_pListView = nil
    --------------------------------------
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    self:TabClicked(self.m_initTab)
end
-----------------------------------
function FundRebateUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_pListView = nil
    Utils:FreeTable(self.uiLayers)
    self.uiLayers = nil
end
-----------------------------------
function FundRebateUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
-----------------------------------
function FundRebateUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/RechargeLevelLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end
-----------------------------------
function FundRebateUI:InitUIControl()
	local pPanel = self.m_pUILayer:getChildByName("Panel")
	local pBtnList = pPanel:getChildByName("Btn_ListView")
	self.m_pListView = pBtnList
	--TODO:目前只有一个成长基金，暂不显示tab
	self.m_pListView:setVisible(false)

	local items = pBtnList:getItems()
	for i=1,#items do
		items[i]:setTouchEnabled(true)
		items[i]:setTag(i)
		items[i]:addClickEventListener(handler(self, FundRebateUI.ClickItem))
		self:MarkIntaractCObj(items[i])
	end

	local pPanel_1 = pPanel:getChildByName("Panel_1")
	local pCloseBtn = pPanel_1:getChildByName("CloseBtn")
	pCloseBtn:addClickEventListener(handler(self, FundRebateUI.RemoveUI))
	self:MarkIntaractCObj(pCloseBtn)
end
-----------------------------------
function FundRebateUI:ClickItem(sender)
	if sender == nil then
		return
	end
	local ind = sender:getTag()
	self:TabClicked(ind)
end
-----------------------------------
function FundRebateUI:TabClicked(ind)
	if self.m_selectTab == ind then
		return
	end

	local function setItemSelect(pBtnModel, isSelect)
		if pBtnModel == nil then
			return
		end
		pBtnModel:getChildByName("ChooseBg"):setVisible(isSelect)
		pBtnModel:getChildByName("BtnName1"):setVisible(isSelect)
		pBtnModel:getChildByName("BtnName2"):setVisible(not isSelect)
	end

	if self.m_selectTab > 0 then
		local pBtnModel = self.m_pListView:getItem(self.m_selectTab - 1)
		setItemSelect(pBtnModel, false)
		self:HideSubUI()
	end

	if ind > 0 then
		local pBtnModel = self.m_pListView:getItem(ind - 1)
		setItemSelect(pBtnModel, true)

		self.m_selectTab = ind
		self:ShowSubUI()
	end
end
-----------------------------------
function FundRebateUI:ShowSubUI()
	if self.m_selectTab > #subLayers then
		return
	end
	local pUILayer = self.uiLayers[self.m_selectTab]
	if pUILayer == nil then --
		self.uiLayers[self.m_selectTab] = require(subLayers[self.m_selectTab]):New()
		pUILayer = self.uiLayers[self.m_selectTab]
		self.m_pUILayer:addChild(pUILayer.m_pUILayer)
	end
	if pUILayer and pUILayer.m_pUILayer then
		pUILayer.m_pUILayer:setVisible(true)
	end
end
-----------------------------------
function FundRebateUI:HideSubUI()
	if self.uiLayers[self.m_selectTab] and self.uiLayers[self.m_selectTab].m_pUILayer then
		self.uiLayers[self.m_selectTab].m_pUILayer:setVisible(false)
	end
end
-----------------------------------
return FundRebateUI