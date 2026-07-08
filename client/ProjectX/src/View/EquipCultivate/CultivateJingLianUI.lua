local CultivateJingLianUI = LUIBase:New()
CultivateJingLianUI.__index = CultivateJingLianUI
--local this = LTcpSocket
function CultivateJingLianUI:New()
    local o = LUIBase:New()
    setmetatable(o,CultivateJingLianUI)    
    o:Init()
    return o
end

--注册事件
-- -----------------------------------
function CultivateJingLianUI:RegistMsgs()
    self.msgIds = 
    {
        -- LUIKaPaiPetEvent.ShowPetLeftInfo,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function CultivateJingLianUI:ProcessEvent(msg)
    -- if msg.msgId == LUIKaPaiPetEvent.ShowPetLeftInfo then
    -- end
end

function CultivateJingLianUI:Init()
    self:InitMembers()
    self:AddTouchEvt()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end

    self.m_pUILayer:registerScriptHandler(onNodeEvent)

end

function CultivateJingLianUI:InitMembers()
    self.m_pUILayer = cc.CSLoader:createNode("csd/zhuangbeiyangcheng/zhuangbeijinglian.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    local bg = self.m_pUILayer:getChildByName("zhuangbeijinglianUI"):getChildByName("jinglian")
	self.manji = bg:getChildByName("manji")
	self.title2 = bg:getChildByName("Title_2")
    local attrBg = bg:getChildByName("jichushuxing")
    self.costBg = bg:getChildByName("jinglianxiaohao")
	
	self.tips = self.costBg:getChildByName("Tips")
    self.m_curLevel = attrBg:getChildByName("Level_1")
    self.m_nextLevel = attrBg:getChildByName("Level_2")


    self._listView = attrBg:getChildByName("ListView")
    self._pCell = self._listView:getChildByName("Panel_1")
    self._pCell:removeFromParent()
    self._pCell:retain()

    self.m_curLevelText = self.costBg:getChildByName("Level")
    self.m_expPercent = self.costBg:getChildByName("Slider_Bg"):getChildByName("LoadingBar")
    self.m_expValueText = self.costBg:getChildByName("Slider_Bg"):getChildByName("Value")
    self.m_itemIcons = {}
    for i=1,4 do
        local itemIcon = {}
        itemIcon.itemBg = self.costBg:getChildByName("Item_"..i)
        itemIcon.num = itemIcon.itemBg:getChildByName("Value")
        itemIcon.expText = itemIcon.itemBg:getChildByName("Text")
        self.m_itemIcons[i] = itemIcon
    end

    self.m_autoJingLianBtn = self.costBg:getChildByName("yijianjinglianBtn")
    self.m_jingLianBtn = self.costBg:getChildByName("jinglianyijiBtn")
end

function CultivateJingLianUI:AddTouchEvt()
    local function JingLianCallBack(sender)
        local equip = LRoleDataMgr.Pet.equipList.m_petEquips[self.m_equipId]
        local curLevel = equip.cultivateLevel[AppDef.PetEquipLevelType.JingLian] or 0
        local quelityCfg = JsonConfig.m_quality.getDefByID(equip.m_quality)
        local quelityRate = 1
        if quelityCfg ~= nil then
            quelityRate = quelityCfg.jinglian_ratio / 10000
        end
        local jlCfg = JsonConfig.m_equipJingLian.getDefByID(curLevel)
        local levelExp = jlCfg.exp * quelityRate - equip.m_jlExp
        if jlCfg == nil or jlCfg.exp == 0 or curLevel >= #JsonConfig.m_equipJingLian.getList() - 1 then
            return
        end
        local cfgs = JsonConfig.GetItemCfgByType(4)
        local costs = {}
        for i=1,#cfgs do
            local cfg = cfgs[i]
            local cost = {}
            if levelExp > 0 then
                local subValue = cfg.sub_value[1]
                local hasNum = LRoleDataMgr.Equip:CountItemNumById(cfg.id)
                local needNum = math.ceil(levelExp / subValue[2])
                if needNum < hasNum then
                    cost.id = cfg.id
                    cost.num = needNum
                else
                    cost.id = cfg.id
                    cost.num = hasNum
                end
                levelExp = levelExp - cost.num * subValue[2]
            else
                break
            end
            costs[i] = cost
        end
        if levelExp > 0 then
            Utils:ShowScrollTips(GUITips.RSI_ZQX_QEUIP_CULTIVATE8,true)
        else
            LuaNetSendMsg:SendEquipAutoJingLian(self.m_equipId, costs)
        end
    end
    self.m_jingLianBtn:addClickEventListener(JingLianCallBack)
    self:MarkIntaractCObj(self.m_jingLianBtn)

    local function AutoJingLianCallBack(sender)
        Utils:InitUI("EquipCultivate.AutoJingLianUI", AppDef.UIType.PopWindow, self.m_equipId)
    end
    self.m_autoJingLianBtn:addClickEventListener(AutoJingLianCallBack)
    self:MarkIntaractCObj(self.m_autoJingLianBtn)
end

function CultivateJingLianUI:onExit()
    self.m_pUILayer = nil
    self.m_curLevel = nil
    self.m_nextLevel = nil
    self.m_attrInfo = nil
    self.m_curLevelText = nil
    self.m_expPercent = nil
    self.m_expValueText = nil
    self.m_itemIcons = nil
    self.m_jingLianBtn = nil
    self.m_autoJingLianBtn = nil
    self:Destory()
end

function CultivateJingLianUI:UpdateData(equipId)
    self.m_equipId = equipId
	self.isMax = false
    local equip = LRoleDataMgr.Pet.equipList.m_petEquips[equipId]
    local curLevel = equip.cultivateLevel[2] or 0
    local nextLevel = curLevel
    if nextLevel < (#JsonConfig.m_equipJingLian.getList() - 1) then 
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
    local jcfg = JsonConfig.m_equipJingLian.getDefByID(curLevel)
	local qcfg = JsonConfig.m_quality.getDefByID(equip.m_quality)
    self.m_curLevel:setString(string.format(GUITips.RSI_ZQX_QEUIP_CULTIVATE5, curLevel))
    self.m_nextLevel:setString(string.format(GUITips.RSI_ZQX_QEUIP_CULTIVATE5, nextLevel))

    self._listView:removeAllItems()
    for i=1, #ecfg.attr_jinglian do
        local qattr = ecfg.attr_jinglian[i]
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

    local cfglist = JsonConfig.m_Item.getList()
    local itemCfg = {}
    for i=1, #cfglist do
        local cfg = cfglist[i]
        if cfg.type == 4 then
            itemCfg[#itemCfg + 1] = cfg
        end
    end

    for i=1,#itemCfg do
        local cfg = itemCfg[i]
        local itemIcon = self.m_itemIcons[i]
        if itemIcon ~= nil then
            local num = LRoleDataMgr.Equip:CountItemNumById(cfg.id)
            local subValue = cfg.sub_value[1]
            Utils:GetItemCellValue(itemIcon.itemBg, 0, cfg.id, true, true, num, nil, true, false)
            if subValue ~= nil then
                itemIcon.expText:setString(string.format(GUITips.RSI_ZQX_QEUIP_CULTIVATE6, subValue[2]))
            end
        end
    end
	local needexp = jcfg.exp * qcfg.jinglian_ratio / 10000
    self.m_curLevelText:setString(string.format(GUITips.RSI_ZQX_QEUIP_CULTIVATE7, curLevel))
    self.m_expPercent:setPercent(equip.m_jlExp * 100 / needexp)
    self.m_expValueText:setString(string.format(GUITips.RSI_ZQX_HERO_BOOK10, equip.m_jlExp, needexp))
	self.tips:setString(string.format(GUITips.UI_Equip_JingLian_tips, #JsonConfig.m_equipJingLian.getList() - 1))
end

return CultivateJingLianUI