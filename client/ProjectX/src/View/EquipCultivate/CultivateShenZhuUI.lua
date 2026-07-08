
local CultivateShenZhuUI = LUIBase:New()
CultivateShenZhuUI.__index = CultivateShenZhuUI
--local this = LTcpSocket
function CultivateShenZhuUI:New()
	local o = LUIBase:New()
	setmetatable(o,CultivateShenZhuUI)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function CultivateShenZhuUI:RegistMsgs()
    self.msgIds = 
    {
        -- LUIKaPaiPetEvent.ShowPetLeftInfo,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function CultivateShenZhuUI:ProcessEvent(msg)
    -- if msg.msgId == LUIKaPaiPetEvent.ShowPetLeftInfo then
    -- end
end

function CultivateShenZhuUI:Init()
    self:InitMembers()
    self:AddTouchEvt()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end

    self.m_pUILayer:registerScriptHandler(onNodeEvent)

end

function CultivateShenZhuUI:InitMembers()

    self.m_pUILayer = cc.CSLoader:createNode("csd/zhuangbeiyangcheng/zhuangbeishenzhu.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    local bg = self.m_pUILayer:getChildByName("zhuangbeijuexingUI"):getChildByName("shenzhu")
	self.manji = bg:getChildByName("manji")
	self.title2 = bg:getChildByName("Title_2")
	self.title3 = bg:getChildByName("Title_3")
    local attrBg = bg:getChildByName("jichushuxing")
    local attrExBg = bg:getChildByName("fujiashuxing")
    self.costBg = bg:getChildByName("juexingxiaohao")

	self.m_curLevel = attrBg:getChildByName("Level_1")
    self.m_nextLevel = attrBg:getChildByName("Level_2")
    
    self._listView = attrBg:getChildByName("ListView")
    self._pCell = self._listView:getChildByName("Panel_1")
    self._pCell:removeFromParent()
    self._pCell:retain()

	local function xiangxiBtnCallBack()
        Utils:InitUI("EquipCultivate.ShenZhuTeXiaoUI", AppDef.UIType.PopWindow, self.m_equipId)
    end
	local xiangxiBtn = attrExBg:getChildByName("Btn_xiangxi")
    xiangxiBtn:addClickEventListener(xiangxiBtnCallBack)
    self:MarkIntaractCObj(xiangxiBtn)
	self.exText = attrExBg:getChildByName("Text_1")

    self.m_costItem = self.costBg:getChildByName("Item")
    self.m_costName = self.costBg:getChildByName("Name")
    self.m_costValue = self.costBg:getChildByName("Value")
    self.m_shenzhuBtn = self.costBg:getChildByName("Btn_shenzhu")
    self.m_moneyValue = self.costBg:getChildByName("ConsumeBg"):getChildByName("Value")
end

function CultivateShenZhuUI:AddTouchEvt()
    local function shenZhuCallBack(sender)
        local equip = LRoleDataMgr.Pet.equipList.m_petEquips[self.m_equipId]
        local ecfg = JsonConfig.m_equipConfig.getDefByID(equip.m_id)
        local curLevel = equip.cultivateLevel[4] or 0
        local nextLevel = 0
        if nextLevel < #JsonConfig.m_equipShenZhu.getList() then nextLevel = nextLevel + 1 end
        local szCfg = JsonConfig.m_equipShenZhu.getDefByID(nextLevel)

        if LRoleDataMgr.Equip:CountItemNumById(ecfg.shenzhu_cost) < szCfg.cost_count then
            Utils:ShowScrollTips(string.format(GUITips.RSI_ZQX_QEUIP_CULTIVATE13,
                Utils:getItemNameByID(ecfg.shenzhu_cost)), true)
            return
        end

        if LRoleDataMgr.MyHeroInfo.DetailData:getMoney() < szCfg.money[1][3] then
            Utils:ShowScrollTips(RSI_BP_SKILL_UPTIPS3, true)
            return
        end

        LuaNetSendMsg:SendEquipCultivate(self.m_equipId, 15, 1)
    end
    self.m_shenzhuBtn:addClickEventListener(shenZhuCallBack)
    self:MarkIntaractCObj(self.m_shenzhuBtn)
end

function CultivateShenZhuUI:onExit()
    self.m_pUILayer = nil
    self.m_curLevel = nil
    self.m_nextLevel = nil
    self.m_attrInfo = nil
    self.m_levelStr = nil
    self.m_attrEx1 = nil
    self.m_attrEx2 = nil
    self.m_costItem = nil
    self.m_costName = nil
    self.m_costValue = nil
    self.m_costItem = nil
    self.m_shenzhuBtn = nil
    self.m_moneyValue = nil
    self:Destory()
end

function CultivateShenZhuUI:UpdateData(equipId, update)
    self.m_equipId = equipId
    local equip = LRoleDataMgr.Pet.equipList.m_petEquips[equipId]
    local curLevel = equip.cultivateLevel[4] or 0
    local nextLevel = curLevel
    if nextLevel < #JsonConfig.m_equipShenZhu.getList() then 
		nextLevel = nextLevel + 1 
		self.manji:setVisible(false)
		self.title3:setVisible(true)
		self.costBg:setVisible(true)
		self.m_nextLevel:setVisible(true)
	else
		--已经到达满级
		self.manji:setVisible(true)
		self.title3:setVisible(false)
		self.costBg:setVisible(false)
		self.m_nextLevel:setVisible(false)
		self.isMax = true
	end
    local ecfg = JsonConfig.m_equipConfig.getDefByID(equip.m_id)
    local cjcfg = JsonConfig.m_equipShenZhu.getDefByID(curLevel)
    local njcfg = JsonConfig.m_equipShenZhu.getDefByID(nextLevel)
    local levelStr = GUITips.RSI_ZQX_QEUIP_CULTIVATE10
    if cjcfg ~= nil then
        levelStr = cjcfg.name
    end
    self.m_curLevel:setString(levelStr)
    self.m_nextLevel:setString(njcfg.name)

    self._listView:removeAllItems()
    for i=1, #ecfg.attr_shenzhu do
        local qattr = ecfg.attr_shenzhu[i]
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
	
	local exdata = {}
	local list = JsonConfig.m_equipShenZhu.getList()
	for i = nextLevel,#list do
		local cfg = list[i]
		if #cfg.skill_add > 0 then
			exdata = cfg.skill_add[ecfg.part]
			exdata[4] = cfg.name
			break
		end
	end
  --  print("tmepStr===========>00000")
    if self.richExText==nil then
        self.richExText=Utils:CreateColorText3(self.exText, true)  
    end
	local skillcfg = LDataConstMgr:GetSkillDetailList(exdata[2])


    

    local temp_Desc =LDataConstMgr:GetHeroSkillDesc(exdata[2],exdata[3])

    local tmepStr = string.format(GUITips.RSI_ZQX_QEUIP_CULTIVATE14,skillcfg.name, exdata[3],temp_Desc, exdata[4])
    print(temp_Desc,"tmepStr===========>")
	self.richExText:setString(tmepStr)

    self.m_costName:setString(Utils:getItemNameByID(ecfg.shenzhu_cost))
    self.m_moneyValue:setString(tostring(njcfg.money[1][3]))
    Utils:GetItemCellValue(self.m_costItem, 0, ecfg.shenzhu_cost, true, false, 1, nil, false, false)
    self.m_costValue:setString(string.format(GUITips.RSI_ZQX_HERO_BOOK5,
        LRoleDataMgr.Equip:CountItemNumById(ecfg.shenzhu_cost), njcfg.cost_count))
	if curLevel > 1 and update then
		if curLevel % 50 == 0  then
			performWithDelay(self.m_pUILayer, function()
				local data = {}
				data.equipId  = self.m_equipId
				data.type = 3
				Utils:InitUI("EquipCultivate.EquipStarUpSuccUI", AppDef.UIType.PopWindow, data)
			end, 3)
		elseif curLevel % 5 == 0 then
			performWithDelay(self.m_pUILayer, function()
				local data = {}
				data.equipId  = self.m_equipId
				data.type = 2
				Utils:InitUI("EquipCultivate.EquipStarUpSuccUI", AppDef.UIType.PopWindow, data)
			end, 3)
		end
	end

end

return CultivateShenZhuUI
