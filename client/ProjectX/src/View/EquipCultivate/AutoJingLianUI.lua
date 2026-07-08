
local AutoJingLianUI = LUIBase:New()
AutoJingLianUI.__index = AutoJingLianUI
--local this = LTcpSocket
function AutoJingLianUI:New(eid)
	local o = LUIBase:New()
	setmetatable(o,AutoJingLianUI)	
    o:Init(eid)
	return o
end

--注册事件
-- -----------------------------------
function AutoJingLianUI:RegistMsgs()
    self.msgIds = 
    {
        -- LUIKaPaiPetEvent.ShowPetLeftInfo,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function AutoJingLianUI:ProcessEvent(msg)
    -- if msg.msgId == LUIKaPaiPetEvent.ShowPetLeftInfo then
    -- end
end

function AutoJingLianUI:Init(eid)
    self:InitMembers(eid)
    self:AddTouchEvt()
    self:UpdateData()
    self:AddLevel(0)
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end

    self.m_pUILayer:registerScriptHandler(onNodeEvent)

end

function AutoJingLianUI:InitMembers(eid)
    self.m_pUILayer = cc.CSLoader:createNode("csd/zhuangbeiyangcheng/yijianjinglian.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    local bg = self.m_pUILayer:getChildByName("Popup")
    local levelBg = bg:getChildByName("Panel_1")
    local itemBg = bg:getChildByName("Panel_2")
    self.m_equipItem = levelBg:getChildByName("Item")
    self.m_equipName = levelBg:getChildByName("Name")
    self.m_curLevel = levelBg:getChildByName("Level"):getChildByName("Value_1")
    self.m_nextLevel = levelBg:getChildByName("Level"):getChildByName("Value_2")
    self.m_addLevel = levelBg:getChildByName("Count"):getChildByName("Value")
    self.m_add = levelBg:getChildByName("Btn_Plus")
    self.m_add10 = levelBg:getChildByName("Btn_Plus10")
    self.m_sub = levelBg:getChildByName("Btn_Minus")
    self.m_sub10 = levelBg:getChildByName("Btn_Minus10")
    self.m_okBtn = bg:getChildByName("Btn_Confirm")
    self.m_cancelBtn = bg:getChildByName("Btn_Cancel")
    self.m_closeBtn = bg:getChildByName("Btn_close")
    self.m_eid = eid
    self.m_costItem = {}
    self.m_itemCfg = {}
    self.m_realLevel = 0
    for i=1,4 do
        self.m_costItem[i] = itemBg:getChildByName("Item_"..i)
    end
end

function AutoJingLianUI:onExit()
    self.m_pUILayer = nil
    self.m_equipItem = nil
    self.m_equipName = nil
    self.m_curLevel = nil
    self.m_nextLevel = nil
    self.m_addLevel = nil
    self.m_add = nil
    self.m_add10 = nil
    self.m_sub = nil
    self.m_sub10 = nil
    self.m_okBtn = nil
    self.m_cancelBtn = nil
    self.m_eid = nil
    self.m_costItem = nil
    self.m_itemCfg = nil
    self.m_realLevel = nil
    self:Destory()
end

function AutoJingLianUI:AddTouchEvt()
    local function AddCallBack(sender)
        self:AddLevel(self.m_realLevel + 1)
    end
    self.m_add:addClickEventListener(AddCallBack)
    self:MarkIntaractCObj(self.m_add)

    local function Add10CallBack(sender)
        self:AddLevel(self.m_realLevel + 10)
    end
    self.m_add10:addClickEventListener(Add10CallBack)
    self:MarkIntaractCObj(self.m_add10)


    local function SubCallBack(sender)
        self:AddLevel(self.m_realLevel - 1)
    end
    self.m_sub:addClickEventListener(SubCallBack)
    self:MarkIntaractCObj(self.m_sub)

    local function Sub10CallBack(sender)
        self:AddLevel(self.m_realLevel - 10)
    end
    self.m_sub10:addClickEventListener(Sub10CallBack)
    self:MarkIntaractCObj(self.m_sub10)

    local function OkCallBack(sender)
        LuaNetSendMsg:SendEquipAutoJingLian(self.m_eid, self.m_costs)
        Utils:DeleteUI("EquipCultivate.AutoJingLianUI")
    end
    self.m_okBtn:addClickEventListener(OkCallBack)
    self:MarkIntaractCObj(self.m_okBtn)


    local function CancelCallBack(sender)
        Utils:DeleteUI("EquipCultivate.AutoJingLianUI")
    end
    self.m_cancelBtn:addClickEventListener(CancelCallBack)
    self:MarkIntaractCObj(self.m_cancelBtn)
    self.m_closeBtn:addClickEventListener(CancelCallBack)
    self:MarkIntaractCObj(self.m_closeBtn)
end

function AutoJingLianUI:UpdateData()
    local equip = LRoleDataMgr.Pet.equipList.m_petEquips[self.m_eid]
    local curLevel = equip.cultivateLevel[AppDef.PetEquipLevelType.JingLian] or 0
    local cfgs = JsonConfig.GetItemCfgByType(4)
    self.m_addExp = 0
    for i=1,#cfgs do
        local cfg = cfgs[i]
        local itemIcon = self.m_costItem[i]
        if itemIcon ~= nil then
            itemIcon.itemId = cfg.id
            itemIcon.hasNum = LRoleDataMgr.Equip:CountItemNumById(cfg.id)
            local subValue = cfg.sub_value[1]
            if subValue ~= nil then
                self.m_addExp = self.m_addExp + itemIcon.hasNum * subValue[2]
                itemIcon.addExp = subValue[2]
            end
            Utils:GetItemCellValue(itemIcon, 0, cfg.id,
                    true, false, 1, nil, false, true)
        end
    end
    self.m_showEquip = PetkaPaiManager:ShowEquipImg(self.m_equipItem, self.m_eid, self.m_showEquip, true)
    self.m_equipName:setString(equip.m_name)
end

function AutoJingLianUI:AddLevel(level)
    local equip = LRoleDataMgr.Pet.equipList.m_petEquips[self.m_eid]
    local curLevel = equip.cultivateLevel[AppDef.PetEquipLevelType.JingLian] or 0
    local quelityCfg = JsonConfig.m_quality.getDefByID(equip.m_quality)
    local quelityRate = 1
    if quelityCfg ~= nil then
        quelityRate = quelityCfg.jinglian_ratio / 10000
    end
    local curExp = equip.m_jlExp
    local needExp = 0 - curExp
    if level > curLevel then
        for i=curLevel,level - 1 do
            local jlCfg = JsonConfig.m_equipJingLian.getDefByID(i)
            local levelExp = jlCfg.exp * quelityRate
            if jlCfg == nil or jlCfg.exp == 0 or self.m_addExp < needExp + levelExp then
                break
            end
            needExp = needExp + levelExp
            self.m_realLevel = i + 1
        end
    else
        self.m_realLevel = curLevel
    end
    self.m_costs = {}
    for i=1,#self.m_costItem do
        local itemIcon = self.m_costItem[i]
        local cost = {}
        if needExp > 0 then
            if math.ceil(needExp / itemIcon.addExp) < itemIcon.hasNum then
                cost.id = itemIcon.itemId
                cost.num = math.ceil(needExp / itemIcon.addExp)
            else
                cost.id = itemIcon.itemId
                cost.num = itemIcon.hasNum
            end
            needExp = needExp - itemIcon.addExp * cost.num
        else
            cost.id = itemIcon.itemId
            cost.num = 0
        end
        self.m_costs[i] = cost
        itemIcon:getChildByName("Value"):setString(string.format(GUITips.RSI_ZQX_HERO_BOOK5,
                cost.num, itemIcon.hasNum))
    end
    self.m_curLevel:setString(tostring(curLevel))
    self.m_nextLevel:setString(tostring(self.m_realLevel))
    self.m_addLevel:setString(tostring(self.m_realLevel - curLevel))
end

return AutoJingLianUI