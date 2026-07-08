local FaBaoInfo = LUIBase:New()
FaBaoInfo.__index = FaBaoInfo

function FaBaoInfo:New(userdata)
    local o = LUIBase:New()
    setmetatable(o,FaBaoInfo) 
    o:Init(userdata)
    return o
end

function FaBaoInfo:Init(userdata)
    self.Script = "PetEquip.FaBaoInfo"
    self:CreateUINode("csd/zhuangbeiyangcheng/zhuangbeiInfo.csb")
    -- self.m_pUILayer = cc.CSLoader:createNode("csd/zhuangbeiyangcheng/zhuangbeiInfo.csb")
    if userdata ~= nil then
        self.m_id = userdata["id"]
        self.m_uid = userdata["uid"]
        self.m_IsShowBtn = userdata["isShowBtn"]
        self.m_heroPos = userdata["heroPos"]--查看其他玩家神将法宝使用（神将位置）
        self.m_wpos = userdata["wPos"]--查看其他玩家神将法宝使用（穿戴位置）
    end
    self.m_uid = self.m_uid or 0
    self.m_id = self.m_id or 0
    self.m_heroPos = self.m_heroPos or 0
    self.m_wpos = self.m_wpos or 0
    if self.m_IsShowBtn == nil then
        self.m_IsShowBtn = false
    end
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:InitData()
    self:ShowLeftInfo()
    self:ShowRightInfo()
	self:UpdateRedDotUI()
end

function FaBaoInfo:InitData()
    local panel = self.m_pUILayer:getChildByName("zhuangbeiInfoUI")
    local maskImg = panel:getChildByName("Mask")
    maskImg:setTouchEnabled(true)

    local popup = panel:getChildByName("Popup")

    local closeBtn = popup:getChildByName("Btn_close")
    closeBtn:addClickEventListener(function(sender)
        self:CloseUI()
    end)

    local title = popup:getChildByName("Title"):getChildByName("Title")
    title:setString(GUITips.UI_Title_PetFaBao_Tips8)

    --左边
    local left = panel:getChildByName("zhuangbei")
    self.m_iconNode = left:getChildByName("Node")
    self.m_nameLabel = left:getChildByName("Namebg"):getChildByName("Name")
    self.m_xieBtn = left:getChildByName("Btn_xiexia")
    self.m_huanBtn = left:getChildByName("Btn_genghuan")
    self.m_xieBtn:addClickEventListener(function (sender)--脱装备
        -- body

        if self.m_uid > 0 and self.m_fpos > 0 then
            -- LuaNetSendMsg:SendPetEquipWearReq(3,self.m_uid,self.m_fpos)
            --脱掉法宝
            LuaNetSendMsg:SendFaBaoTakeOff(self.m_uid)
            self:CloseUI()
        end
    end)
    self.m_huanBtn:addClickEventListener(function (sender)--更换装备
        if self.m_uid > 0 and self.m_fpos > 0 and self.m_info ~= nil then
            local part = self.m_info.m_wpos or 0
            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "FaBao.PetFaBaoChangeUI",AppDef.UIType.PopWindow, {part,self.m_fpos})
            self:SendMsg(LGameMsg.m_initUIMsg)
            self:CloseUI()
        end
    end)

    --右边
    local right = panel:getChildByName("Info")
    self.m_scrollView = right:getChildByName("ScrollView")
    self.m_listView = right:getChildByName("ListView")
    self.m_baseAttr = right:getChildByName("jichushuxing")
    self.m_baseAttrType = self.m_baseAttr:getChildByName("Atrribute_1")
    
    self.m_qhAttr = right:getChildByName("qianghuashuxing")
    self.m_jlAttr = right:getChildByName("jinglianshuxing")
    print("self.m_id InitData ===>", self.m_id, self.m_uid)
    local qhBtn = self.m_qhAttr:getChildByName("Btn_qianghua")
    local jlBtn = self.m_jlAttr:getChildByName("Btn_jinglian")
    if self.m_id > AppDef.fabaoExpItemID.high_fbExp then
        --self.m_qhLvLabel = self.m_qhAttr:getChildByName("Level"):getChildByName("Value")
        self.m_qhAttrType = self.m_qhAttr:getChildByName("Atrribute_1")
        qhBtn:addClickEventListener(function (sender)--打开强化界面
            if self.m_uid > 0 then
                if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_KAPAI_FABAO_QIANGHUA) then
                    return
                end
                self:CloseUI()
                Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_FABAO_QIANGHUA, {1, self.m_uid})
            end
        end)
        
        --self.m_jlLvLabel = self.m_jlAttr:getChildByName("Level"):getChildByName("Value")
        self.m_jlAttrType = self.m_jlAttr:getChildByName("Atrribute_1")
        
        jlBtn:addClickEventListener(function (sender)
            if self.m_uid > 0 then
                if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_KAPAI_FABAO_JINGLIAN) then
                    return
                end
                self:CloseUI()
                Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_FABAO_JINGLIAN, {2, self.m_uid})
            end
        end)
    else
        self.m_qhAttr:setVisible(false)
        self.m_jlAttr:setVisible(false)
    end

    self.m_jxAttr = right:getChildByName("juexingshuxing")
    self.m_jxAttr:setVisible(false)


    self.m_szAttr = right:getChildByName("shenzhushuxing")
    self.m_szAttr:setVisible(false)


    self.m_suitInfo = right:getChildByName("zhuangbeitaozhuang")
    self.m_suitInfo:setVisible(false)
    self.m_suitList = self.m_suitInfo:getChildByName("List")
    self.m_suitItem = self.m_suitInfo:getChildByName("Item")
    self.m_suitAttrType = self.m_suitInfo:getChildByName("Atrribute_1")

    self.m_descNode = right:getChildByName("zhuangbeimiaoshu")
    self.m_descLabel = self.m_descNode:getChildByName("Content")

    --数据
    
    if self.m_uid > 0 then
        if self.m_heroPos > 0 and self.m_wpos > 0 then
            self.m_info = LRoleDataMgr.OtherHeroInfo.MapFaBao[self.m_heroPos][self.m_wpos]
        else
            local petFaBao = LRoleDataMgr.Pet.faBaoList.m_petFaBaos
            if petFaBao ~= nil then
                self.m_info = petFaBao[self.m_uid]
            end
        end
    end
    self.m_fpos = 0
    if self.m_info ~= nil then
        self.m_fpos = self.m_info.m_fpos or 0
        if self.m_id == 0 and self.m_heroPos == 0 then
            self.m_id = self.m_info.m_id
        end
    end

    if self.m_id > 0 then
        self.m_cfgData = JsonConfig.m_faBaoConfig.getDefByID(self.m_id)
    end
    
    self.m_qhLv = 0
    self.m_jlLv = 0
    if self.m_info ~= nil then
        self.m_qhLv = self.m_info.cultivateLevel[AppDef.PetFaBaoLevelType.QiangHua] or 0
        self.m_jlLv = self.m_info.cultivateLevel[AppDef.PetFaBaoLevelType.JingLian] or 0
    end

    if not self.m_IsShowBtn then
        self.m_xieBtn:setVisible(false)
        self.m_huanBtn:setVisible(false)
    end
    if self.m_heroPos > 0 then
        qhBtn:setVisible(false)
        jlBtn:setVisible(false)
    end
end

function FaBaoInfo:ShowLeftInfo()
    if self.m_id == 0 or self.m_cfgData == nil then
        return
    end
    self.m_nameLabel:setString(self.m_cfgData.name)
    self.m_nameLabel:setColor(AppDef:GetQualityColor(self.m_cfgData.quality))

    if self.m_icon == nil then
		self.m_iconNode:setScale(1.5)
        self.m_icon = ItemCellUI:New(self.m_iconNode)
        self.m_icon.m_pUILayer:setAnchorPoint(cc.p(0.5, 0.5))
    end
    
    local itemValue = {}
    local petFaBaoData = {
        id = self.m_id,
        qhLv = self.m_qhLv,
        jlLv = self.m_jlLv,
    }
    itemValue.petFaBaoData = petFaBaoData
    self.m_icon:UpdateItem(itemValue)
end

function FaBaoInfo:ShowRightInfo()
    --self.m_scrollView:removeAllChildren()
    self.m_listView:removeAllItems()
    if self.m_cfgData ~= nil and #self.m_cfgData.attr > 0 then
        self:ShowBaseAttr()
        self:ShowAttrs()
    end
    self:ShowDesc()
end

function FaBaoInfo:ShowBaseAttr()
    if self.m_id == 0 or self.m_cfgData == nil then
        return
    end
    self.m_baseAttr:retain()
    self.m_baseAttr:removeFromParent()
    local typeLable = self.m_baseAttrType
    local valLable = typeLable:getChildByName("Value")
    Utils:ShowAttrLabelSec(typeLable, self.m_cfgData.attr[1], valLable, "+"..self.m_cfgData.attr[2])
    self.m_listView:pushBackCustomItem(self.m_baseAttr)
end

function FaBaoInfo:ShowAttrs()
    self.m_qhAttr:setVisible(false)
    self.m_jlAttr:setVisible(false)

    if self.m_uid == 0 or self.m_info == nil then
        return
    end

    local qhAttrs = {}
    qhAttrs[self.m_info.baseData.atrr_qianghua[1]] = self.m_qhLv * self.m_info.baseData.atrr_qianghua[2]

    local jlAttrs = {}
    for i = 1,#self.m_info.baseData.attr_jinglian do
        local attr = self.m_info.baseData.attr_jinglian[i]
        jlAttrs[attr[1]] = attr[2] * self.m_jlLv
    end
    
    -- -- --强化
    self:ShowAttr(self.m_qhAttr,self.m_qhAttrType,self.m_qhLv,#JsonConfig.m_faBaoQiangHua.getList() - 1, qhAttrs)

    -- -- --精炼
    self:ShowAttr(self.m_jlAttr,self.m_jlAttrType,self.m_jlLv,#JsonConfig.m_faBaoJingLian.getList()-1, jlAttrs)

end

function FaBaoInfo:ShowAttr(attrNode,attrType,level,maxLevel,attrs)
    --dump(attrs,"FaBaoInfo:ShowAttr=>")
    if level == nil or attrs == nil or  attrNode == nil or attrType == nil  then
        return
    end
    attrNode:setVisible(true)
    attrType:setString("")
    attrType:getChildByName("Value"):setString("")
    local cnt = 0
    for k,v in pairs(attrs) do
        local typeLable = nil
        if cnt == 0 then
            typeLable = attrType
            cnt = 1 
        else
            typeLable = attrType:clone()
            local pos = cc.p(attrType:getPosition())
            typeLable:setPosition(cc.p(pos.x,pos.y-typeLable:getContentSize().height*cnt-2))
            attrNode:addChild(typeLable)
            cnt = cnt +1
        end
        local valLable = typeLable:getChildByName("Value")
        --Utils:ShowAttrLabelSec(typeLable, k, valLable, "+"..v)
        if k > AppDef.EAttrType.EAT_RESISIT_CRIT then
            local value = v / 100
            Utils:ShowAttrLabel(typeLable, k, valLable, "+"..value, true)
        else
            Utils:ShowAttrLabel(typeLable, k, valLable, "+"..v, false)
        end
        valLable:setPositionX(100)
    end
    local lvLabel = attrNode:getChildByName("Level"):getChildByName("Value")
    lvLabel:setString(""..level.."/"..maxLevel)
    --self.m_scrollView:addChild(attrNode)
    attrNode:retain()
    attrNode:removeFromParent()
    self.m_listView:pushBackCustomItem(attrNode)
end

function FaBaoInfo:ShowDesc()
    if self.m_cfgData == nil then
        return
    end
    self.m_descLabel:setString(self.m_cfgData.des or "")
    self.m_descNode:retain()
    self.m_descNode:removeFromParent()
    self.m_listView:pushBackCustomItem(self.m_descNode)
end

function FaBaoInfo:CloseUI()
    LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "FaBao.FaBaoInfo")
    self:SendMsg(LGameMsg.m_deleteUIMsg)
end

function FaBaoInfo:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_pNode = nil
    self.m_id = nil
    self.Script  = nil
end

function FaBaoInfo:UpdateRedDotUI()
    if self.m_uid == 0 or self.m_id == 0 or self.m_heroPos ~= 0 then
        return
    end
	local isqianghua, isjinglian = LRedDotCheckMgr:FaBaoCultivateRedDotCheck(self.m_uid)
	self.m_qhAttr:getChildByName("Btn_qianghua"):getChildByName("Prompt"):setVisible(isqianghua)
	self.m_jlAttr:getChildByName("Btn_jinglian"):getChildByName("Prompt"):setVisible(isjinglian)
	local isShow = LRedDotCheckMgr:FaBaoChangeRedDotCheck(self.m_info.m_fpos,self.m_uid)
	self.m_huanBtn:getChildByName("Prompt"):setVisible(isShow)
end

return FaBaoInfo