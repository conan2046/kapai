
local FaBaoQiangHuaUI = LUIBase:New()
FaBaoQiangHuaUI.__index = FaBaoQiangHuaUI
--local this = LTcpSocket
function FaBaoQiangHuaUI:New()
	local o = LUIBase:New()
	setmetatable(o,FaBaoQiangHuaUI)	
    o:Init()
	return o
end

local maxQHLV = 120

--注册事件
-- -----------------------------------
function FaBaoQiangHuaUI:RegistMsgs()
    self.msgIds = 
    {
        LUIFaBaoEvent.PetQHMaterialSelect,
        LUIFaBaoEvent.PetQHSuc,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function FaBaoQiangHuaUI:ProcessEvent(msg)
    if msg.msgId == LUIFaBaoEvent.PetQHMaterialSelect then
        -- self._matrList = msg.value
        if self._matrList then
            for k,v in pairs(msg.value) do  
                table.insert(self._matrList, v)
            end
        else
            self._matrList = msg.value
        end
        self:showList()
        self:updateMoneyValue()
    elseif msg.msgId == LUIFaBaoEvent.PetQHSuc then
        --刷新UI
        self:updateUIAfterQhSuc(msg.value)
    end
end

function FaBaoQiangHuaUI:Init()

    self.m_pUILayer = cc.CSLoader:createNode("csd/zhuangbeiyangcheng/fabaoqianghua.csb")
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

function FaBaoQiangHuaUI:initControlUI( ... )
    -- body
    local fabaoqianghuaUI = self.m_pUILayer:getChildByName("fabaoqianghuaUI")
    local qianghua = fabaoqianghuaUI:getChildByName("qianghua")

    local jichushuxing = qianghua:getChildByName("jichushuxing")

    self._listView = jichushuxing:getChildByName("ListView")
    self._attrCell =  self._listView:getChildByName("Panel_1")
    self._attrCell:removeFromParent()
    self._attrCell:retain()

    self._topCurLv = jichushuxing:getChildByName("Level_1")
    self._topNextLv = jichushuxing:getChildByName("Level_2")

    --------------------------------------------------------------------------
    local qianghuaxiaohao = qianghua:getChildByName("qianghuaxiaohao")
    self._SliderBg = qianghuaxiaohao:getChildByName("Slider_Bg")
    self._LoadingBar = self._SliderBg:getChildByName("LoadingBar")

    self._curQHExp = self._SliderBg:getChildByName("Value")
    self._addQHExp = self._curQHExp:getChildByName("Value_up")

    self._curLV = qianghuaxiaohao:getChildByName("Level")
    self._addLV = self._curLV:getChildByName("Levelup")

    self._tips = qianghuaxiaohao:getChildByName("Tips")
    local qhConfigList = JsonConfig.m_faBaoQiangHua.getList()
    local length = #qhConfigList
    local lastData = qhConfigList[length]
    self._tips:setString(string.format(GUITips.UI_Title_PetFaBao_Tips3, lastData.level))
    ---------------------------------------------------------------
    local suipian_layer = qianghuaxiaohao:getChildByName("suipian_layer")
    self._addItemList = {}
    for i=1, 8 do
        local addSuipianicon = suipian_layer:getChildByName("suipianicon"..i)
        addSuipianicon:setTag(i)
        table.insert(self._addItemList, addSuipianicon)
        addSuipianicon:addClickEventListener(handler(self, FaBaoQiangHuaUI.addConsumeItem))
        addSuipianicon.userObject = 0
    end

    local yijiantianjiaBtn = qianghuaxiaohao:getChildByName("yijiantianjiaBtn")
    yijiantianjiaBtn:addClickEventListener(handler(self, FaBaoQiangHuaUI.oneKeyAddItem))

    local qianghuaBtn = qianghuaxiaohao:getChildByName("qianghuaBtn")
    qianghuaBtn:addClickEventListener(handler(self, FaBaoQiangHuaUI.QHEvent))
    ------------------------------------------------------------------------------
    local ConsumeBg = qianghuaxiaohao:getChildByName("ConsumeBg")
    self._costValue = ConsumeBg:getChildByName("Value")
    self._costValueColor = self._costValue:getTextColor()
end

function FaBaoQiangHuaUI:oneKeyAddItem( sender )
    -- body
    if self:GetCurQHLv() >= maxQHLV then
        Utils:ShowScrollTips(GUITips.FaBao_QH_Tip1)
        return
    end

    local list = PetkaPaiManager:oneKeySelectFBQHItem(self._faBaoUid)
    if list == nil then
        Utils:ShowScrollTips(GUITips.UI_Title_PetFaBao_Tips1)
        return
    end

    self._matrList = list
    self:showList()
    self:updateMoneyValue()
end

function FaBaoQiangHuaUI:showList( ... )
    -- body
    for i=1, #self._matrList do
        local item = self._addItemList[i]
        local addIcon = item:getChildByName("AddIcon")
        addIcon:setVisible(false)
        local IconBase = item:getChildByName("IconBase")
        local itemData = self._matrList[i]
        item.userObject = itemData.m_uid
        Utils:GetFaBaoCellValue(IconBase, nil, itemData.m_id, itemData.m_uid, true, 1, itemData.qhLv, itemData.qhLv, false, true)
    end

end

function FaBaoQiangHuaUI:resetUI( ... )
    -- body
    for i=1, #self._addItemList do
        local item = self._addItemList[i]
        item.userObject = 0
        local addIcon = item:getChildByName("AddIcon")
        addIcon:setVisible(true)
        local IconBase = item:getChildByName("IconBase")
        IconBase:removeAllChildren()
    end

    self._matrList = {}
    self._addLevel = 1
end

function FaBaoQiangHuaUI:QHEvent( sender )
    -- body
    -- print("FaBaoQiangHuaUI:QHEvent ====>", self._faBaoUid)
    -- dump(self._matrList, "QHEvent ===============111 >")
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_KAPAI_FABAO_QIANGHUA) then
        return
    end

    if self:GetCurQHLv() >= maxQHLV then
        Utils:ShowScrollTips(GUITips.FaBao_QH_Tip1)
        return
    end

    if self._matrList == nil or #self._matrList < 0 then
        return 
    end
    LuaNetSendMsg:SendFaBaoQianHua(self._faBaoUid, self._matrList)
end


function FaBaoQiangHuaUI:addConsumeItem( sender )
    -- body

    local tag = sender:getTag()
    local faBaoUid = sender.userObject
    if faBaoUid == 0 then
        local selectList = {}
        table.insert(selectList, self._faBaoUid)
        if self._matrList then
            for k,v in pairs(self._matrList) do
                table.insert(selectList, v.m_uid)
            end
        end

        Utils:InitUI("FaBao.ChooseFaBaoQHMat", AppDef.UIType.PopFirstClassLayer, selectList)
    else

        for i=1, #self._matrList do
            if self._matrList[i].m_uid == faBaoUid then
                table.remove(self._matrList, i)
                break
            end
        end

        local IconBase = sender:getChildByName("IconBase")
        IconBase:removeAllChildren()

        local AddIcon = sender:getChildByName("AddIcon")
        AddIcon:setVisible(true)

        sender.userObject = 0

        self:updateMoneyValue()

    end

end

function FaBaoQiangHuaUI:UpdateData(faBaoUid)
    -- body
    self._faBaoUid = faBaoUid
    self._addLevel = 1
    self:updateUI()
end

function FaBaoQiangHuaUI:GetCurQHLv( ... )
    -- body
    local fabaoData = LRoleDataMgr.Pet.faBaoList.m_petFaBaos[self._faBaoUid]
    if fabaoData == nil then
        return 0
    end
    return fabaoData.qhLv
end

function FaBaoQiangHuaUI:updateUI( ... )
    -- body
    local fabaoData = LRoleDataMgr.Pet.faBaoList.m_petFaBaos[self._faBaoUid]
    if fabaoData == nil then
        return
    end
    -- print("FaBaoQiangHuaUI:updateUI ===>", self._faBaoUid)
    -- dump(fabaoData, "FaBaoQiangHuaUI:updateUI ======>")
    self.m_id = fabaoData.m_id
    --属性条

    self._listView:removeAllItems()
    local qattr = fabaoData.baseData.atrr_qianghua
    local item = self._attrCell:clone()

    local _attrName = item:getChildByName("Value_0")
    local _curValue = item:getChildByName("Value_1")
    local _nextValue = item:getChildByName("Value_2")
    local _addValue = item:getChildByName("Value_3")

    local nextLevel = fabaoData.qhLv + self._addLevel
    local baseAttr = fabaoData.baseData.attr[2]
    self._addLV:setVisible(false)
    _attrName:setString(Utils:getAttrName(qattr[1]))
    _curValue:setString(tostring(qattr[2] * fabaoData.qhLv + baseAttr))
    _nextValue:setString(tostring(qattr[2] * nextLevel + baseAttr))
    _addValue:setString(tostring(qattr[2]))
    self._listView:pushBackCustomItem(item)

    self._curLV:setString(tostring(fabaoData.qhLv).. GUITips.Common_Ji)
    
    self._topCurLv:setString(tostring(fabaoData.qhLv).. GUITips.Common_Ji)
    if nextLevel > maxQHLV then
        self._topNextLv:setVisible(false)
    else
        self._topNextLv:setString(tostring(nextLevel).. GUITips.Common_Ji)
    end
    
    local curqhConfig = JsonConfig.m_faBaoQiangHua.getDefByID(fabaoData.qhLv + 1)
	if curqhConfig == nil then
		return
	end
    local qualityConfig = JsonConfig.m_quality.getDefByID(fabaoData.baseData.quality)
    local lvUpNeedExp = curqhConfig.exp * qualityConfig.fabao_qianghua / 10000
    self._curQHExp:setString(string.format("%d/%d", fabaoData.qHExp, lvUpNeedExp))
    
    self._LoadingBar:setPercent(fabaoData.qHExp / lvUpNeedExp * 100)
    
    self:updateMoneyValue()
end

function FaBaoQiangHuaUI:updateMoneyValue( ... )
    -- body
    local addExp = self:getAddExp()
    self._addQHExp:setString("+".. addExp)

    local myCoinNum = LRoleDataMgr.MyHeroInfo.DetailData:getMoney()
    if addExp > myCoinNum then
        self._costValue:setTextColor(AppDef.UIColor.RED)
    else
        self._costValue:setTextColor(self._costValueColor)
    end
    self._costValue:setString(addExp)
end

function FaBaoQiangHuaUI:getAddExp()
    -- body
    local exp = 0
    if self._matrList == nil then
        return exp
    end
    for k,v in pairs(self._matrList) do
        local configData = JsonConfig.m_faBaoConfig.getDefByID(v.m_id)
        if configData.exp > 0 then
            exp = exp + configData.exp
        end
    end
    return exp
end

function FaBaoQiangHuaUI:updateUIAfterQhSuc( data )
    
    self:resetUI()
    self:updateUI()
end

function FaBaoQiangHuaUI:CloseUI( ... )
    -- body
    Utils:DeleteUI("HappyDraw.FaBaoQiangHuaUI")
end

function FaBaoQiangHuaUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

return FaBaoQiangHuaUI