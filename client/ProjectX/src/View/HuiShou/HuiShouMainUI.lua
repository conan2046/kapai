local HuiShouMainUI = LUIBase:New()
HuiShouMainUI.__index = HuiShouMainUI

HuiShouMainUI.IsHideInBattle = true
function HuiShouMainUI:New(data)
    local o = {}
    setmetatable(o, HuiShouMainUI)
    o:Init(data)
    return o
end

function HuiShouMainUI:Init(data)
	print("============HuiShouMainUI===========>", data)
    self.curSubInd = data or 1
	self.m_pUILayer = nil
	self.m_pSubLayer = {{}, {}, {}}
	self:InitViewSize()
	self:InUIControl()
	self:setCloseCallback()
end

function HuiShouMainUI:InitViewSize()
	self.m_pUILayer = cc.Node:create()
	self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

function HuiShouMainUI:InUIControl()
	--self.curSubInd = 1
	self.subuinames = {{"View.HuiShou.ShengJiangChongShengUI"}, {"View.HuiShou.ZhuangBeiChongShengUI", "View.HuiShou.ZhuangBeiFenJieUI"}, {"View.HuiShou.FaBaoChongShengUI","View.HuiShou.FaBaoFenJieUI"}}
	self.tabNames = {GUITips.UI_HuiShou_ShengJiang, GUITips.UI_HuiShou_Equip, GUITips.UI_HuiShou_FaBao}
	Utils:SendMsg(LUIFClassBgEvent.SetTitle, GUITips.UI_HuiShou_Title)
	local function tabBtnClicked(ind)
		self:TabClicked(ind)
    end
	local tabValues = 
    {
        self.tabNames,
        tabBtnClicked
    }
    Utils:SendMsg(LUIFClassBgEvent.AddTabBtn, tabValues)

    Utils:SendMsg(LUIFClassBgEvent.SelectTab, self.curSubInd)

	self.secondTabNames = {{"神将重生"}, {"装备重生","装备分解"}, {"法宝重生","法宝分解"}}
	self.curSecondSubInd = 1
	self:ShowSubUI(self.curSubInd)
end

function HuiShouMainUI:TabClicked(ind)
	print("======================>", ind)
	if self.curSubInd == ind then
		return
	end
	self:HideSubUI(self.curSubInd)
	self.curSubInd = ind
	self:ShowSubUI(ind)
end

function HuiShouMainUI:SecondTabClicked(ind)
	print("======================>", ind, self.curSubInd)
	self:HideSecondSubUI(self.curSecondSubInd)
	self.curSecondSubInd = ind
	self:ShowSecondSubUI(ind)
end

function HuiShouMainUI:DelayLoadSubUI(ind)
    local delay = cc.DelayTime:create(0.1)
    local function loadSubUI()
        self.m_pSubLayer[ind][self.curSecondSubInd] = require(self.subuinames[ind][self.curSecondSubInd]):New()
        self.m_pUILayer:addChild(self.m_pSubLayer[ind][self.curSecondSubInd].m_pUILayer)
    end
    local func = cc.CallFunc:create(loadSubUI)
    local sequence = cc.Sequence:create(delay, func)
    self.m_pUILayer:runAction(sequence)
end

function HuiShouMainUI:ShowSubUI(ind)
	local function secondTabBtnClicked(ind)
		self:SecondTabClicked(ind)
    end
	local secondTabValues = 
    {
        self.secondTabNames[ind],
        secondTabBtnClicked
    }
    Utils:SendMsg(LUIFClassBgEvent.AddSecondTabBtn, secondTabValues)
	Utils:SendMsg(LUIFClassBgEvent.SelectSecondTab, self.curSecondSubInd)
	if self.m_pSubLayer[ind] == nil or self.m_pSubLayer[ind][self.curSecondSubInd] == nil then
		self:DelayLoadSubUI(ind)
	else
		self.m_pSubLayer[ind][self.curSecondSubInd].m_pUILayer:setVisible(true)
	end
end

function HuiShouMainUI:ShowSecondSubUI(secondind)
	if self.m_pSubLayer[self.curSubInd] == nil or self.m_pSubLayer[self.curSubInd][secondind] == nil then
		self:DelayLoadSubUI(self.curSubInd)
	else
		self.m_pSubLayer[self.curSubInd][secondind]:SetVisible(true)
	end
end
function HuiShouMainUI:HideSubUI(ind)
	if self.m_pSubLayer[ind][self.curSecondSubInd] == nil then
        return
    end
    self.m_pSubLayer[ind][self.curSecondSubInd].m_pUILayer:setVisible(false)
	self.curSecondSubInd = 1
end

function HuiShouMainUI:HideSecondSubUI(secondind)
	if self.m_pSubLayer[self.curSubInd][secondind] == nil then
        return
    end
    self.m_pSubLayer[self.curSubInd][secondind].m_pUILayer:setVisible(false)
end

function HuiShouMainUI:setCloseCallback()
	local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
	Utils:SendMsg(LUIFClassBgEvent.SetCloseCallback, handler(self, HuiShouMainUI.CloseUI))
end

function HuiShouMainUI:onExit()
	self:Destory()
	self.m_pUILayer = nil
end

function HuiShouMainUI:CloseUI()
	for key,value in pairs(self.m_pSubLayer) do
		for k,v in pairs(value) do
			v:CloseUI()
		end
	end
	Utils:DeleteUI("HuiShou.HuiShouMainUI")
end

return HuiShouMainUI