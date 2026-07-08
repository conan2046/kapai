
local FaBaoSuiPianBagUI = LUIBase:New()
FaBaoSuiPianBagUI.__index = FaBaoSuiPianBagUI
--local this = LTcpSocket
function FaBaoSuiPianBagUI:New()
	local o = LUIBase:New()
	setmetatable(o,FaBaoSuiPianBagUI)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function FaBaoSuiPianBagUI:RegistMsgs()
    self.msgIds = 
    {
        LUIXunBaoEvent.FaBaoHechengSuc,
        LUIXunBaoEvent.FaBaoOneKeyHCSuc,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function FaBaoSuiPianBagUI:ProcessEvent(msg)
    if msg.msgId == LUIXunBaoEvent.FaBaoHechengSuc then
        self:InitData()
        self:updateUI()
    elseif msg.msgId == LUIXunBaoEvent.FaBaoOneKeyHCSuc then
        self:InitData()
        self:updateUI()
    end
end

function FaBaoSuiPianBagUI:Init()

    self.m_pUILayer = cc.CSLoader:createNode("csd/zhuangbeiyangcheng/fabaosuipianbeibao.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:InitData()
    self:initControlUI()
    self:updateUI()
end

function FaBaoSuiPianBagUI:initControlUI( ... )
    -- body
    local suipianUI = self.m_pUILayer:getChildByName("suipianUI")
    -- suipianUI:setTouchEnabled(false)
    self._ListView = suipianUI:getChildByName("ListView")
    self._cell = self._ListView:getChildByName("Panel_fabao")
	suipianUI:getChildByName("cell"):setVisible(false);
    suipianUI:getChildByName("recycle"):setVisible(false)
    self._cell:removeFromParent()
    self._cell:retain()

    self._Point = suipianUI:getChildByName("Point")
    self._Point:getChildByName("txt"):setString(GUITips.RSI_FABAO_SUIPIAN_NONE)
    
    --------------------------------------------------------------
    local Button = suipianUI:getChildByName("Button")
    Button:addClickEventListener(function ( sender )
        -- body
        if self._canHeChengNum < 1 then
            return
        end
        print("FaBaoSuiPianBagUI addClickEventListener ===>", self._canHeChengNum)
        LuaNetSendMsg:SendFaBaoHeChengOneKeyReq()
    end)
    self._Number = suipianUI:getChildByName("Number")
    --------------------------------------------------------------
    local recycle = suipianUI:getChildByName("recycle")
    self._recycle = recycle
    local cell = suipianUI:getChildByName("cell")
    self._cellBtn = cell
end

function FaBaoSuiPianBagUI:isNoFaBaoUIState( isNoFragment )
    -- body
    self._Point:setVisible(isNoFragment)
    self._ListView:setVisible(not isNoFragment)
    self._recycle:setVisible(not isNoFragment)
    self._cellBtn:setVisible(not isNoFragment)
end

function FaBaoSuiPianBagUI:InitData( ... )
    -- body
    self._ownFaBaoFragList = {}
    local Num = 0
    for k,v in pairs(LRoleDataMgr.Equip:GetPackageMap()) do
        --神将碎片
        -- dump(v, "PetBagFragmentSubUI:initData ===========>")
        print("FaBaoSuiPianBagUI:InitData ===>", v.m_type, v.m_id)
        if v.m_type == AppDef.ItemType.FaBaoFrag then
            local heChengData = self:getHeChengConfigData(v.m_id)
            if heChengData ~= nil and not self:isContainData(heChengData) then
                table.insert(self._ownFaBaoFragList, heChengData)
            end
        end
    end
    self:sortData()
    self._canHeChengNum = 0
end


function FaBaoSuiPianBagUI:sortData( ... )
    -- body
    local function sortFuc(a, b)
        return self:getSuiPianHeChengProp(a) > self:getSuiPianHeChengProp(b)
    end 
    table.sort(self._ownFaBaoFragList, sortFuc)
end

function FaBaoSuiPianBagUI:getSuiPianHeChengProp( hcData )
    -- body
    if hcData == nil then
        return 0
    end
    local isCanHeCheng =  PetkaPaiManager:FaBaoCanHeCheng(hcData)
    local faBaoData = JsonConfig.m_faBaoConfig.getDefByID(hcData.target[2])
    if faBaoData == nil then
        return false
    end
    if isCanHeCheng then
        return 3000 + faBaoData.quality
    end

    return faBaoData.quality
end

function FaBaoSuiPianBagUI:isContainData( data )
    -- body
    for k,v in pairs(self._ownFaBaoFragList) do
        if v.id == data.id then
            return true
        end
    end
    return false
end

function FaBaoSuiPianBagUI:getHeChengConfigData(id)
    -- body
    local heChengList = JsonConfig.m_HeCheng.getList()
    for i=1, #heChengList do
        if heChengList[i].type == AppDef.HeChengType.Cop_FaBao then
            local items = heChengList[i].item
            for j=1, #items do
                local itemData = items[j]
                -- print("itemData ===>", itemData[1])
                if itemData[1] == id then
                    return heChengList[i]
                end
            end
        end
    end
    return nil
end

function FaBaoSuiPianBagUI:updateUI( ... )
    -- body
    local ownSpNum = #self._ownFaBaoFragList

    -- dump(self._ownFaBaoFragList, "updateUI==>")

    if ownSpNum < 1 then
        self:isNoFaBaoUIState(true)
        return
    end
    
    self:isNoFaBaoUIState(false)
    self._ListView:removeAllItems()
    self._canHeChengNum = 0
    for i=1, ownSpNum do
        local item = self._cell:clone()
        local suipian_layer = item:getChildByName("suipian_layer")
        local hcData = self._ownFaBaoFragList[i]
        local size = #hcData.item
        local isCanHeCheng = true
        local minSPNum = 0
        for j=1, 5 do
            local frag = suipian_layer:getChildByName("Icon_suipian_"..j)
            frag:setVisible(false)
            if j <= size then
                local itemData = hcData.item[j]
                frag:setVisible(true)
                local itemNum = LRoleDataMgr.Equip:CountItemNumById(itemData[1])
                if j == 1 then
                    minSPNum = itemNum
                end
                if itemNum < 1 then
                    isCanHeCheng = false
                end

                if itemNum < minSPNum  then
                    minSPNum = itemNum
                end

                Utils:GetItemCellValue(frag, 0, itemData[1], true, true, itemNum, nil, false, true)
                local Name = frag:getChildByName("Name")
                local nameStr = Utils:getItemNameByID(itemData[1])
                Name:setString(nameStr)

                local Image_zhezhao = frag:getChildByName("Image_zhezhao")
                Image_zhezhao:setVisible(itemNum < 1)
                Image_zhezhao:setGlobalZOrder(1)
            end

        end

        self._canHeChengNum = self._canHeChengNum + minSPNum

        local xunbaoBtn = item:getChildByName("xunbaoBtn")
        xunbaoBtn:setTag(i)
        xunbaoBtn:addClickEventListener(handler(self, FaBaoSuiPianBagUI.GoToFind))
        if isCanHeCheng then
            local text = xunbaoBtn:getChildByName("Text")
            text:setString(GUITips.UI_Btn_Item_Hecheng)
            xunbaoBtn:setTag(1)
            xunbaoBtn.userObject = hcData.target[2]
        else
            xunbaoBtn:setTag(2)
        end

        local faBao = hcData.target
        local faBaoIcon = item:getChildByName("Icon_fabao")
        local fabaoID = faBao[2]
        Utils:GetFaBaoCellValue(faBaoIcon, nil, fabaoID, 0, true, faBao[3], 0, 0, true, true)
        local faBaoName = faBaoIcon:getChildByName("Name")
        local cfgData = JsonConfig.m_faBaoConfig.getDefByID(fabaoID)
        faBaoName:setString(cfgData.name)

        self._ListView:pushBackCustomItem(item)

        self._Number:setString(string.format(GUITips.FABAO_SUIPIAN_TIPS, self._canHeChengNum))

    end
    
end

function FaBaoSuiPianBagUI:GoToFind( sender )
    -- body
    local tag = sender:getTag()
    print("GoToFind 11111111111111===>", tag)
    if tag == 1 then
        local FaBaoId = sender.userObject
        print("GoToFind 22222222222222222==>", FaBaoId)
        LuaNetSendMsg:SendFaBaoHeChengReq(FaBaoId)
    else
        self:CloseUI()
        Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_XUNBAO)
    end

end

function FaBaoSuiPianBagUI:CloseUI( ... )
    -- body
    Utils:DeleteUI("FaBao.FaBaoMainUI")
end

function FaBaoSuiPianBagUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

return FaBaoSuiPianBagUI