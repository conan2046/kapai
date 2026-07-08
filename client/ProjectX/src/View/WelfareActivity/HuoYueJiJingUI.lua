local HuoYueJiJingUI = LUIBase:New()
HuoYueJiJingUI.__index = HuoYueJiJingUI

local subLayers = {
	"View.WelfareActivity.HuoyueLayer",
}
-----------------------------------
function HuoYueJiJingUI:New(tab)
    local o = {}
    setmetatable(o, HuoYueJiJingUI)
    o:Init(tab)
    return o
end
-----------------------------------
function HuoYueJiJingUI:Init(tab)
    self.Script = "WelfareActivity.HuoYueJiJingUI"
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
function HuoYueJiJingUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_pListView = nil
    Utils:FreeTable(self.uiLayers)
    self.uiLayers = nil
end
-----------------------------------
function HuoYueJiJingUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
-----------------------------------
function HuoYueJiJingUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/HuoyueLevelLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end
-----------------------------------
function HuoYueJiJingUI:InitUIControl()
	local pPanel = self.m_pUILayer:getChildByName("Panel")
	local pBtnList = pPanel:getChildByName("Btn_ListView")
	self.m_pListView = pBtnList
	--TODO:目前只有一个成长基金，暂不显示tab
	self.m_pListView:setVisible(false)

	local items = pBtnList:getItems()
	for i=1,#items do
		items[i]:setTouchEnabled(true)
		items[i]:setTag(i)
		items[i]:addClickEventListener(handler(self, HuoYueJiJingUI.ClickItem))
		self:MarkIntaractCObj(items[i])
	end

	local pPanel_1 = pPanel:getChildByName("Panel_1")
	local pCloseBtn = pPanel_1:getChildByName("CloseBtn")
	pCloseBtn:addClickEventListener(handler(self, HuoYueJiJingUI.RemoveUI))
	self:MarkIntaractCObj(pCloseBtn)
end
-----------------------------------
function HuoYueJiJingUI:ClickItem(sender)
	if sender == nil then
		return
	end
	local ind = sender:getTag()
	self:TabClicked(ind)
end
-----------------------------------
function HuoYueJiJingUI:TabClicked(ind)
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
function HuoYueJiJingUI:ShowSubUI()
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
function HuoYueJiJingUI:HideSubUI()
	if self.uiLayers[self.m_selectTab] and self.uiLayers[self.m_selectTab].m_pUILayer then
		self.uiLayers[self.m_selectTab].m_pUILayer:setVisible(false)
	end
end
-----------------------------------
return HuoYueJiJingUI