
local FaBaoJingLianUI = LUIBase:New()
FaBaoJingLianUI.__index = FaBaoJingLianUI
--local this = LTcpSocket
function FaBaoJingLianUI:New()
	local o = LUIBase:New()
	setmetatable(o,FaBaoJingLianUI)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function FaBaoJingLianUI:RegistMsgs()
    self.msgIds = 
    {
        LUIFaBaoEvent.PetJLSuc,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function FaBaoJingLianUI:ProcessEvent(msg)
    if msg.msgId == LUIFaBaoEvent.PetJLSuc then
        self:updateJLData(msg.value)
    end
end

function FaBaoJingLianUI:Init()

    self.m_pUILayer = cc.CSLoader:createNode("csd/zhuangbeiyangcheng/fabaojinglian.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:initControlUI()
end

function FaBaoJingLianUI:initControlUI( ... )
    -- body
    local fabaojuexing_layer = self.m_pUILayer:getChildByName("fabaojuexing_layer")
    local juexing = fabaojuexing_layer:getChildByName("juexing")
    local juexingshuxing = juexing:getChildByName("juexingshuxing")

    self._listView = juexingshuxing:getChildByName("ListView")
    self._attrCell = self._listView:getChildByName("Panel_1")
    self._attrCell:removeFromParent()
    self._attrCell:retain()

    self._topCurLv = juexingshuxing:getChildByName("Level_1")
    self._topNextLv = juexingshuxing:getChildByName("Level_2")
    -------------------------------------------------------------
    local jinglianxiaohao = juexing:getChildByName("jinglianxiaohao")

    self._itemIcon = jinglianxiaohao:getChildByName("Item")

    self._itemName = jinglianxiaohao:getChildByName("Name")
    self._itemValue = jinglianxiaohao:getChildByName("Value")
    self._textColor = self._itemValue:getTextColor()
    ---------------------------------------------------------
    local ConsumeBg = jinglianxiaohao:getChildByName("ConsumeBg")
    self._costValue = ConsumeBg:getChildByName("Value")

    self._Btn_shenzhu = jinglianxiaohao:getChildByName("Btn_shenzhu")
    self._Btn_shenzhu:addClickEventListener(handler(self, FaBaoJingLianUI.JingLianEvent))
    --------------------------------------------------------------

end

function FaBaoJingLianUI:UpdateData(faBaoUid)
    -- body
    self._faBaoUid = faBaoUid
    local fabaoData = LRoleDataMgr.Pet.faBaoList.m_petFaBaos[self._faBaoUid]
    self._faBaoJLLV = fabaoData.jlLv
    self._addLevel = 1
    self:updateUI()
end

function FaBaoJingLianUI:JingLianEvent( sender )
    -- body

    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_KAPAI_FABAO_JINGLIAN) then
        return
    end

    local myMoney = LRoleDataMgr.MyHeroInfo.DetailData:getMoney()
    if myMoney < self._costMoney then
        Utils:ShowScrollTips(GUITips.RSI_BP_SKILL_UPTIPS3)
        return
    end

    if self._itemNum  < self._costItemNum then
        Utils:ShowScrollTips(GUITips.UI_Title_PetFaBao_Tips5)
        return
    end

    if self._faBaoJLLV >= 25 then
        Utils:ShowScrollTips(GUITips.UI_Title_PetFaBao_Tips6)
        return
    end
    print("JingLianEvent ====>", self._faBaoJLLV + 1, self._faBaoUid)
    LuaNetSendMsg:SendFaBaoJingLian(self._faBaoUid, self._faBaoJLLV + 1)
end

function FaBaoJingLianUI:updateJLData(data)
    -- body
    LRoleDataMgr.Pet.faBaoList.m_petFaBaos[self._faBaoUid].jlLv = data.toLevel
    self._faBaoJLLV = data.toLevel
    self:updateUI()
end

function FaBaoJingLianUI:updateUI( ... )
    -- body
    local fabaoData = LRoleDataMgr.Pet.faBaoList.m_petFaBaos[self._faBaoUid]
    if fabaoData == nil then
        return
    end
    -- print("FaBaoJingLianUI:updateUI ===>", self._faBaoUid)
    -- dump(fabaoData, "FaBaoJingLianUI:updateUI ======>")
    self.m_id = fabaoData.m_id
    --属性条

    self._listView:removeAllItems()

    local nextLevel = fabaoData.jlLv + self._addLevel
    local qattr = fabaoData.baseData.attr_jinglian
    for k,v in pairs(qattr) do
        local item = self._attrCell:clone()

        local _attrName = item:getChildByName("Value_0")
        local _curValue = item:getChildByName("Value_1")
        local _nextValue = item:getChildByName("Value_2")
        local _addValue = item:getChildByName("Value_3")

        local baseAttr = 0
        if fabaoData.baseData.attr[1] == v[1] then
            local baseAttr = fabaoData.baseData.attr[2]
        end

        _attrName:setString(Utils:getAttrName(v[1]))
        _curValue:setString(tostring(v[2] * fabaoData.jlLv + baseAttr))
        _nextValue:setString(tostring(v[2] * nextLevel + baseAttr))
        _addValue:setString(tostring(v[2]))
        self._listView:pushBackCustomItem(item)

    end


    self._topCurLv:setString(tostring(fabaoData.jlLv).. GUITips.Common_Ji)
    self._topNextLv:setString(tostring(nextLevel).. GUITips.Common_Ji)

    local curJLConfig = JsonConfig.m_faBaoJingLian.getDefByID(fabaoData.jlLv)

    Utils:GetItemCellValue(self._itemIcon, 0, curJLConfig.cost[1][1], true, false, 0, nil, true, true)
    local itemData = JsonConfig.m_Item.getDefByID(curJLConfig.cost[1][1])
    self._itemName:setString(itemData.name)
    local num = LRoleDataMgr.Equip:CountItemNumById(curJLConfig.cost[1][1])
    self._itemNum = num
    self._costItemNum = curJLConfig.cost[1][3]

    if self._itemNum < self._costItemNum then
        self._itemValue:setTextColor(CCNORMAL_RED)
    end

    self._itemValue:setString(string.format("%d/%d", num, curJLConfig.cost[1][3]))

    local myMoney = LRoleDataMgr.MyHeroInfo.DetailData:getMoney()
    self._costMoney = curJLConfig.cost[2][3]

    if myMoney < curJLConfig.cost[2][3] then
        self._costValue:setTextColor(CCNORMAL_RED)
    end

    self._costValue:setString(curJLConfig.cost[2][3])

end

function FaBaoJingLianUI:CloseUI( ... )
    -- body
    Utils:DeleteUI("HappyDraw.FaBaoJingLianUI")
end

function FaBaoJingLianUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

return FaBaoJingLianUI