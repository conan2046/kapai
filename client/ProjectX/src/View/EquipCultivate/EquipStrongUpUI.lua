
local EquipStrongUpUI = LUIBase:New()
EquipStrongUpUI.__index = EquipStrongUpUI
--local this = LTcpSocket
function EquipStrongUpUI:New()
	local o = LUIBase:New()
	setmetatable(o,EquipStrongUpUI)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function EquipStrongUpUI:RegistMsgs()
    self.msgIds = 
    {
      -- LUIRoleEquipChangeEvent.EquipeShuaXin,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function EquipStrongUpUI:ProcessEvent(msg)
    -- if msg.msgId == LUIRoleEquipChangeEvent.EquipeShuaXin then
		
    -- end
end

function EquipStrongUpUI:Init()
    self:InitMembers()
    self:AddTouchEvt()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end

    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegisterGuide()
end

function EquipStrongUpUI:InitMembers()
    self.m_pUILayer = cc.CSLoader:createNode("csd/zhuangbeiyangcheng/zhuangbeiqianghua.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
    local qhbg = self.m_pUILayer:getChildByName("zhuangbeiqianghuaUI"):getChildByName("qianghua")
	self.manji = qhbg:getChildByName("manji")
	self.title2 = qhbg:getChildByName("Title_2")
    local attrBg = qhbg:getChildByName("jichushuxing")
    self.costBg = qhbg:getChildByName("qianghuaxiaohao")

    self._listView = attrBg:getChildByName("ListView")
    self._pCell = self._listView:getChildByName("Panel_1")
    self._pCell:removeFromParent()
    self._pCell:retain()

    self.m_curLevel = attrBg:getChildByName("Level_1")
    self.m_nextLevel = attrBg:getChildByName("Level_2")
    


    self.m_costValue = self.costBg:getChildByName("ConsumeBg"):getChildByName("Value")
    self.m_btnOne = self.costBg:getChildByName("qianghuaBtn")
    self.m_btnFive = self.costBg:getChildByName("qianghua5Btn")
end

function EquipStrongUpUI:AddTouchEvt()
	local money = LRoleDataMgr.MyHeroInfo.DetailData:getMoney()
    local function OneStrongBtnCallback(sender)
		if money < self.curCost then
			Utils:ShowScrollTips(GUITips.RSI_BP_SKILL_UPTIPS3)
			return
		end
        LuaNetSendMsg:SendEquipQiangHua(self.m_equipId, 0)
    end
    self.m_btnOne:addClickEventListener(OneStrongBtnCallback)
    self:MarkIntaractCObj(self.m_btnOne)

    local function FiveStrongBtnCallback(sender)
		if money < self.curCost then
			Utils:ShowScrollTips(GUITips.RSI_BP_SKILL_UPTIPS3)
			return
		end
        LuaNetSendMsg:SendEquipQiangHua(self.m_equipId, 1)
    end
    self.m_btnFive:addClickEventListener(FiveStrongBtnCallback)
    self:MarkIntaractCObj(self.m_btnFive)
end

function EquipStrongUpUI:onExit()
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep,GuideDef.StepId.Guide_Equip_7)
    self.m_pUILayer = nil
    self.m_curLevel = nil
    self.m_nextLevel = nil
    self.m_attrName = nil
    self.m_curValue = nil
    self.m_nextValue = nil
    self.m_addValue = nil
    self.m_costValue = nil
    self.m_btnOne = nil
    self.m_btnFive = nil
    self.m_equipId = nil
    self:Destory()
end

function EquipStrongUpUI:UpdateData( equipId )
    self.m_equipId = equipId
	self.isMax = false
    local equip = LRoleDataMgr.Pet.equipList.m_petEquips[equipId]
    if equip == nil then return end
    local curLevel = equip.cultivateLevel[AppDef.PetEquipLevelType.QiangHua] or 0
    local nextLevel = curLevel
    if nextLevel < #JsonConfig.m_equip_qianghua.getList() then 
		nextLevel = nextLevel + 1 
		self.title2:setVisible(true)
		self.costBg:setVisible(true)
		self.manji:setVisible(false)
		self.m_nextLevel:setVisible(true)
	else
		--已经到达满级
		self.title2:setVisible(false)
		self.costBg:setVisible(false)
		self.manji:setVisible(true)
		self.m_nextLevel:setVisible(false)
		self.isMax = true
	end
    local ecfg = JsonConfig.m_equipConfig.getDefByID(equip.m_id)

    self._listView:removeAllItems()
    for i=1, #ecfg.atrr_qianghua do
        local qattr = ecfg.atrr_qianghua[i]
        -- dump(qattr, "UpdateData ===== 11111111111 >")
        local item = self._pCell:clone()

        local _attrName = item:getChildByName("Value_0")
        local _curValue = item:getChildByName("Value_1")
        local _nextValue = item:getChildByName("Value_2")
        local _addValue = item:getChildByName("Value_3")

        _attrName:setString(Utils:getAttrName(qattr[1]))
        _curValue:setString(tostring(qattr[2] * curLevel))
        _nextValue:setString(tostring(qattr[2] * nextLevel))
        _addValue:setString(tostring(qattr[2]))
        self._listView:pushBackCustomItem(item)

		if self.isMax == true then
			item:getChildByName("Image"):setVisible(false)
			item:getChildByName("To"):setVisible(false)
			_nextValue:setVisible(false)
			_addValue:setVisible(false)
		else
			item:getChildByName("Image"):setVisible(true)
			item:getChildByName("To"):setVisible(true)
			_nextValue:setVisible(true)
			_addValue:setVisible(true)
		end
    end

    self.m_curLevel:setString(string.format(GUITips.RSI_ZQX_QEUIP_CULTIVATE5, curLevel))
    self.m_nextLevel:setString(string.format(GUITips.RSI_ZQX_QEUIP_CULTIVATE5, nextLevel))

    local scfg = JsonConfig.m_equip_qianghua.getDefByID(nextLevel)
	local qcfg = JsonConfig.m_quality.getDefByID(equip.m_quality)
    self.m_costValue:setString(tostring(scfg.cost[3] * qcfg.qianghua_ratio / 10000))
	self.curCost = scfg.cost[3]
end

function EquipStrongUpUI:RegisterGuide()
    Utils:RegisterGuide(GuideDef.StepId.Guide_Equip_7, self.m_btnOne ,function()
        LuaNetSendMsg:SendEquipQiangHua(self.m_equipId, 0)
    end, nil, true)
end

return EquipStrongUpUI