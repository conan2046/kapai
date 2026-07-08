--[[
lua里面的游戏逻辑控制
竞技场挑战界面
]]
--local ShopDef = require("View.Shop.ShopDef")

local XunBaoMainUI = LUIBase:New()
XunBaoMainUI.__index = XunBaoMainUI
XunBaoMainUI.IsHideInBattle = true
--local this = LTcpSocket
function XunBaoMainUI:New()
	local o = LUIBase:New()
	setmetatable(o,XunBaoMainUI)	
    o:Init()
	return o
end

local SPEED = 300--/秒

function XunBaoMainUI:Init()
    --self.m_pGuideBtn = nil
    self:CreateUINode("csd/wanfa/XunbaoLayer.csb")
    -- self.m_pUILayer = cc.CSLoader:createNode("csd/wanfa/XunbaoLayer.csb")
    -- self.m_pUILayer:setContentSize(AppDef.frameSize)
    -- ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    self:RegistMsgs()
    self:InitData()
    self:UpdateInfo()

    self:ShowBgMoney(1)
    

    LuaNetSendMsg:SendXunBaoInfoReq()
    --LuaNetSendMsg:QueryGotTaskList(3)
    self:RegisterGuide()
    self:UpdateRedDot()
end

function XunBaoMainUI:onExit()
    LRedDotCheckMgr:CloseCheckBtn(AppDef.RedDotBtnName.XunBaoTask)
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep,GuideDef.StepId.Guide_XunBao_4)
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep,GuideDef.StepId.Guide_XunBao_8)
    LArenaDataMgr:Init()
    self:Destory()
    self:DeleteSchedule()
    self.m_pUILayer = nil
    self.m_cellNodes = nil
    self.m_datas = nil
    self.m_suiItems = nil
    self.m_checkHeChengNum = nil
    Utils:CheckGuide(GuideDef.StepId.Guide_XunBao_9,true)
end

--[[
注册UI消息
]]
function XunBaoMainUI:RegistMsgs()
    self.msgIds = 
    {
        LUIRoleDataChangeEvent.MoneyChanged,
        LUIRoleDataChangeEvent.TongBaoChanged, 
        LUIRoleDataChangeEvent.TiliChanged,
        LUIXunBaoEvent.UpdateCntUI,
        LUIXunBaoEvent.ShowResultUI,
        LUIXunBaoEvent.FaBaoHechengSuc,
        LUIXunBaoEvent.FaBaoOneKeyHCSuc,
    }
    self:RegistSelf(self,self.msgIds)
end

function XunBaoMainUI:ProcessEvent(msg)
    if msg.msgId == LUIRoleDataChangeEvent.MoneyChanged 
        or msg.msgId == LUIRoleDataChangeEvent.TongBaoChanged 
        or msg.msgId == LUIRoleDataChangeEvent.TiliChanged then
        self:ShowBgMoney()
    elseif msg.msgId == LUIXunBaoEvent.UpdateCntUI then
        self:ShowTime()
    elseif msg.msgId == LUIXunBaoEvent.ShowResultUI then
        self:UpdateHeCheng()
    elseif msg.msgId == LUIXunBaoEvent.FaBaoHechengSuc then
        self:ShowTimeLine()
    elseif msg.msgId == LUIXunBaoEvent.FaBaoOneKeyHCSuc then
        self:UpdateHeCheng()
    end
end


function XunBaoMainUI:InitData()
    --panel:setTouchEnabled(false)
    --信息界面
    local panel = self.m_pUILayer:getChildByName("Panel")
    panel:setTouchEnabled(true)
    closeBtn = panel:getChildByName("Title"):getChildByName("CloseBtn")
    closeBtn:addClickEventListener(handler(self, XunBaoMainUI.CloseUI))
    self.m_closeBtn = closeBtn
    local infoPanel = panel:getChildByName("XunbaoBg")
    infoPanel:setTouchEnabled(false)
    local cntPanel = infoPanel:getChildByName("TimesBg")
    self.m_tipsLabel = cntPanel:getChildByName("Tips")
    self.m_cntLabel = cntPanel:getChildByName("Icon"):getChildByName("Num")
    local addCntBtn =  cntPanel:getChildByName("AddBtn")--加次数按钮
    addCntBtn:addClickEventListener(handler(self, XunBaoMainUI.OnAddCntBtnClick))
    --local zhenBtn = infoPanel:getChildByName("ArrayBtn")--打开阵容界面
    --zhenBtn:addClickEventListener(handler(self, XunBaoMainUI.OnZhenBtnClick))
    
    local btn = infoPanel:getChildByName("Btn_1")
    btn:addClickEventListener(handler(self, XunBaoMainUI.OnBottomRightBtnClick))
    self.m_redPoint = btn
    
    --金钱
    local moneyPanel = panel:getChildByName("GoldCheck")
    local money1 = moneyPanel:getChildByName("GoldIcon1")
    self.m_tiliImg = money1:getChildByName("Icon")--体力
    self.m_tiliLabel = money1:getChildByName("GoldNumBg"):getChildByName("Num")
    local tiliAddBtn = money1:getChildByName("AddBtn")
    tiliAddBtn:addClickEventListener(function ( sender )
        Utils:OpenUseUI(500,1)
    end)
    local money2 = moneyPanel:getChildByName("GoldIcon3")
    self.m_goldImg = money2:getChildByName("Icon")--金币
    self.m_goldLabel = money2:getChildByName("GoldNumBg"):getChildByName("Num")
    local goldAddBtn = money2:getChildByName("AddBtn")
    goldAddBtn:addClickEventListener(function ( sender )
        Utils:OpenFunction(AppDef.EModuleID.EMID_SCCHANGYONG)
    end)
    local money3 = moneyPanel:getChildByName("GoldIcon4")
    self.m_cashImg = money3:getChildByName("Icon")--元宝
    self.m_cashLabel = money3:getChildByName("GoldNumBg"):getChildByName("Num")
    local cashAddBtn = money3:getChildByName("AddBtn")
    cashAddBtn:setVisible(false)

    --faBao list
    local faBaoPanel = self.m_pUILayer:getChildByName("Xunbao")
    local leftPanel = faBaoPanel:getChildByName("Panel")
    self.m_leftListView = leftPanel:getChildByName("List")
    self.m_leftItemCell = leftPanel:getChildByName("Item")
    local btn = self.m_leftItemCell:getChildByName("Big")
    btn:setTouchEnabled(false)
    self.m_leftBtn = leftPanel:getChildByName("Button_L")
    self.m_rightBtn = leftPanel:getChildByName("Button_R")
    -- self.m_leftBtn:addClickEventListener(handler(self, XunBaoMainUI.MoveCallBack))
    -- self.m_leftBtn.userObject = 1
    -- self.m_rightBtn:addClickEventListener(handler(self, XunBaoMainUI.MoveCallBack))
    -- self.m_leftBtn.userObject = 0

    self.m_colorPanels = {}
    for i=1,3 do
        self.m_colorPanels[i] = faBaoPanel:getChildByName("Blue")
    end
    self.m_colorPanels[4] = faBaoPanel:getChildByName("Purple")
    self.m_colorPanels[5] = faBaoPanel:getChildByName("Orange")
    for i=6,7 do
        self.m_colorPanels[i] = faBaoPanel:getChildByName("Red")
    end

    for i=3,6 do
        self.m_colorPanels[i]:setTouchEnabled(false)
        self.m_colorPanels[i]:setVisible(false)
        local layer = self.m_colorPanels[i]:getChildByName("Image")
        for k=1,8 do
            local btn = layer:getChildByName("Add"..k)
            if btn ~= nil then
                btn:addClickEventListener(handler(self,XunBaoMainUI.SeekCallBack))
            end
        end
    end

    self.m_oneKeyBtn = faBaoPanel:getChildByName("Btn_1")
    self.m_oneKeyBtn:addClickEventListener(handler(self,XunBaoMainUI.OneKeyCallBack))
    self.m_heChengBtn = faBaoPanel:getChildByName("Btn_2")
    self.m_heChengBtn:addClickEventListener(handler(self,XunBaoMainUI.HeChengCallBack))
    self.m_OneKeyHCBtn = faBaoPanel:getChildByName("Btn_3")
    self.m_OneKeyHCBtn:addClickEventListener(handler(self,XunBaoMainUI.OneKeyHCCallBack))

    --法宝属性显示
    self.m_faBaoDescPanel = panel:getChildByName("DescBg"):getChildByName("Bg")
    self.m_list = self.m_faBaoDescPanel:getChildByName("List")
    self.m_baseAttr = self.m_faBaoDescPanel:getChildByName("jichushuxing")
    self.m_baseAttrType = self.m_baseAttr:getChildByName("Atrribute_1")
    self.m_qhAttr = self.m_faBaoDescPanel:getChildByName("qianghuashuxing")
    self.m_qhAttrType = self.m_qhAttr:getChildByName("Atrribute_1")
    self.m_jlAttr = self.m_faBaoDescPanel:getChildByName("jinglianshuxing")
    self.m_jlAttrType = self.m_jlAttr:getChildByName("Atrribute_1")
    self.m_descNode = self.m_faBaoDescPanel:getChildByName("zhuangbeimiaoshu")
    self.m_descLabel = self.m_descNode:getChildByName("Content")
    self.m_nameLabel = self.m_faBaoDescPanel:getChildByName("Namebg"):getChildByName("Name")

    self.m_cellNodes = {}
    self.m_datas = {}
    self.m_suiItems = {}
    self.m_isPlaying = false
    self.m_checkHeChengNum = 0

	local helpBtn = panel:getChildByName("Title"):getChildByName("TitleName"):getChildByName("btn_help")
    helpBtn:addClickEventListener(function ( sender )
        self:HelpClicked()
    end)
end

function XunBaoMainUI:HelpClicked(sender) 
    Utils:ShowDialogOKCancel(GUITips.XunBao)
end

function XunBaoMainUI:SortItem()
    self.m_datas = {}
    local ids = JsonConfig.GetHeChengIdsByType(8)
    if ids == nil or #ids == 0 then
        return
    end
    for i=1,#ids do
        local cfg = JsonConfig.m_HeCheng.getDefByID(ids[i])
        if cfg ~= nil and cfg.type == 8 then
            local value = {}
            value.id = cfg.target[2]
            value.items = cfg.item
            value.quality = 1
            value.name = ""
            value.pic = 0
            value.heChengId = cfg.id
            local fabaoCfg = JsonConfig.m_faBaoConfig.getDefByID(value.id)
            if fabaoCfg ~= nil and cfg.item ~= nil then
                value.quality = fabaoCfg.quality
                value.name = fabaoCfg.name
                value.pic = fabaoCfg.pic
                local showSign = (value.quality == 3 and value.id ~= 615)
                if not showSign then
                    for k=1,#cfg.item do
                        local id = cfg.item[k][1] or 0
                        if id > 0 then
                            local num = LRoleDataMgr.Equip:CountItemNumById(id)
                            if num > 0 then
                                showSign = true
                                break
                            end
                        end
                    end
                end
                if showSign then
                    table.insert(self.m_datas,value)
                end
            end
        end
    end
    local function sortFuc(m1, m2)
        if m1.quality == m2.quality then
            return m1.id < m2.id
        end
        return m1.quality > m2.quality
    end
    table.sort(self.m_datas, sortFuc)
end


function XunBaoMainUI:UpdateInfo()
    self:SortItem()
    self:ShowList()
    self:SelecteItem(1)
end

function XunBaoMainUI:ShowBgMoney(init)
    init = init or 0
    local value1 = Utils:getTiliStr(LRoleDataMgr.MyHeroInfo.DetailData:getTili())
    if self.m_tiliLabel ~= nil then
        self.m_tiliLabel:setString(value1)
    end
    local value2 = Utils:getGoldStr()
    self.m_goldLabel:setString(""..value2)
    local value3 =  LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao()
    self.m_cashLabel:setString(""..value3)
    --print("showmoney",value1,value2,value3)
    if init == 1 then
        local imgPath1 = "res/UI/Icon/ui_huobi_icon/huobi_"..LRoleDataMgr.GetItemPicId(AppDef.SpecialItemId.Tili)..".png"
        Utils:SafeLoadTexture(self.m_tiliImg,imgPath1,ccui.TextureResType.plistType)
        local imgPath2 = "res/UI/Icon/ui_huobi_icon/huobi_"..LRoleDataMgr.GetItemPicId(AppDef.SpecialItemId.Gold)..".png"
        Utils:SafeLoadTexture(self.m_goldImg,imgPath2,ccui.TextureResType.plistType)
        local imgPath3 = "res/UI/Icon/ui_huobi_icon/huobi_"..LRoleDataMgr.GetItemPicId(AppDef.SpecialItemId.Cash)..".png"
        Utils:SafeLoadTexture(self.m_cashImg,imgPath3,ccui.TextureResType.plistType)
    end
end

--一键
function XunBaoMainUI:ShowXunBaoBtn()
    self.m_oneKeyBtn:setVisible(false)
    self.m_heChengBtn:setVisible(false)
    local limitLv = LDataConstMgr:GetFuctionCondition(AppDef.EModuleID.EMID_KAPAI_XUNBAO_ONEKEY, 1)
    --print("XunBaoMainUI:ShowXunBaoBtn limitLv",limitLv)
    if self.m_curData == nil or self.m_curData.heChengId == nil then
        return
    end
    local data = self.m_curData
    local cfg = JsonConfig.m_HeCheng.getDefByID(data.heChengId)
    local sign = false
    if cfg ~= nil then
        sign = true
        for i=1,#cfg.item do
            local id = cfg.item[i][1] or 0
            local num = LRoleDataMgr.Equip:CountItemNumById(id)
            if num < cfg.item[i][3] then
                sign = false
                break
            end
        end
    end
    self.m_heChengBtn:setVisible(true)
    local width = self.m_heChengBtn:getParent():getSize().width 
    if limitLv <= LRoleDataMgr.MyHeroInfo.level then
        self.m_oneKeyBtn:setVisible(true)
        self.m_heChengBtn:setPositionX(width*0.65)
    else
        self.m_heChengBtn:setPositionX(width*0.5)
    end
    self.m_OneKeyHCBtn:setPositionX(width*0.78)
    if not sign then
        self.m_heChengBtn:setBright(false)
        self.m_heChengBtn:setEnabled(false)
        self.m_oneKeyBtn:setBright(true)
        self.m_oneKeyBtn:setEnabled(true)
    else
        self.m_heChengBtn:setBright(true)
        self.m_heChengBtn:setEnabled(true)
        self.m_oneKeyBtn:setBright(false)
        self.m_oneKeyBtn:setEnabled(false)
        Utils:CheckGuide(GuideDef.StepId.Guide_XunBao_6,true)
    end
end

function XunBaoMainUI:ShowInfo()
    self:ShowTime()
end

-- function XunBaoMainUI:ShowResultUI(faBaoId,oneKeySign)
--     local data = LActivityManager:GetXunBaoData()
--     if data.m_records == nil or #data.m_records == 0 then
--         return
--     end
--     faBaoId = faBaoId or 0
--     oneKeySign = oneKeySign or 0
--     Utils:InitUI("Activity.XunBaoResultUI",AppDef.UIType.SecondClassLayer,{data.m_records,faBaoId,oneKeySign})
-- end

function XunBaoMainUI:ShowHeChengUI(sender)
    if self.m_isPlaying then
        return
    end
    local idx = sender.userObject
    if idx == nil or idx < 1  then
        return
    end
    local data = self.m_datas[idx]
    if self.m_curData ~= nil and self.m_curData.id == data.id then
        return
    end
    self.m_curData = data
    local quality = data.quality or 1
    if self.m_curColorPanel ~= nil then
        self.m_curColorPanel:setVisible(false)
    end
    self.m_curColorPanel = self.m_colorPanels[quality]
    self.m_curColorPanel:setVisible(true)
    
    self:UpdateItems(idx)

    self.m_oneKeyBtn:setVisible(false)
    self.m_heChengBtn:setVisible(false)
    self:CreateAction()
    --local indexs = {360,360,360,310,260,210,210}
    --local start = indexs[quality] or 360
    --print("XunBaoMainUI:ShowHeChengUI",start,start+45)
    --self.m_action:gotoFrameAndPlay(start,start+45,true)
    local names = {"BlueOpen","BlueOpen","BlueOpen","PurpleOpen","OrangeOpen","RedOpen","RedOpen"}
    self.m_action:play(names[quality],false)
    --self:ClearColorPanel()
    self:UpdateHeChengUI()
    self:ShowFaBaoDesc()
    self.m_isPlaying = true
end

--更新碎片UI
function XunBaoMainUI:UpdateHeChengUI()
    if  self.m_curData == nil or self.m_curColorPanel == nil then
        return
    end
    local data = self.m_curData
    --dump(data)
    local panel = self.m_curColorPanel:getChildByName("Image")
    local iconImg = self.m_curColorPanel:getChildByName("Icon")
    local str = "item/"..data.pic..".png"
    Utils:SafeLoadTexture(iconImg,str,ccui.TextureResType.localType)
    for i=1,#data.items do
        local addLayer = panel:getChildByName("Add"..i)
        if addLayer ~= nil then
            local addImg = addLayer:getChildByName("Icon")
            local itemImg = addLayer:getChildByName("Icon_0")
            local particle = addLayer:getChildByName("Particle")
            local numLabel = addLayer:getChildByName("Num")
            particle:setVisible(false)
            itemImg:setVisible(true)
            particle:setLocalZOrder(99)
            numLabel:setString("")
            local id = data.items[i][1] or 0
            local num = LRoleDataMgr.Equip:CountItemNumById(id)
            --print("XunBaoMainUI:UpdateHeChengUI",i,id,num)
            local value = {}
            value.suiId = id
            value.faBaoId = data.id
            value.sign = 0--碎片标记
            if id > 0 then
                local path = "item/equip"..LRoleDataMgr.GetItemPicId(id)..".png"
                Utils:SafeLoadTexture(itemImg,path,ccui.TextureResType.localType)
                if num > 0 then
                    numLabel:setString(""..num)
                    print("UpdateHeChengUI num",num)
                end
                if num >= data.items[i][3] then
                    addImg:setVisible(false)
                    particle:setVisible(true)
                    itemImg:setColor(AppDef.UIColor.WHITE)
                else
                    addImg:setVisible(true)
                    addImg:setLocalZOrder(9)
                    itemImg:setColor(cc.c3b(0x7f,0x7f,0x7f))
                    value.sign = 1
                end
            end
            addLayer.userObject = value
        end
    end
    self:ShowXunBaoBtn()
end

function XunBaoMainUI:UpdateItems(idx)
    for i= 1,#self.m_cellNodes do
        local node = self.m_cellNodes[i]:getChildByName("Big")
        if i == idx then
            node:setScale(1.2)
        else
            node:setScale(1)
        end
    end
end

--flag 是否跳过id相同判断，用于更新
function XunBaoMainUI:SelecteItem(idx,flag)
    if self.m_isPlaying then
        return
    end
    if self.m_datas == nil or idx > #self.m_datas or idx < 1 then
        return
    end
    local data = self.m_datas[idx]
    if data == nil then
        return
    end
    if flag == nil then
        flag = false
    end
    if not flag and self.m_curData ~= nil and self.m_curData.id == data.id then
        return
    end
    self.m_curData = data
    local quality = data.quality or 1
    if self.m_curColorPanel ~= nil then
        self.m_curColorPanel:setVisible(false)
    end
    self.m_curColorPanel = self.m_colorPanels[quality]
    self.m_curColorPanel:setVisible(true)

    self:UpdateItems(idx)
    self:UpdateHeChengUI()

    if self.m_guideBtn == nil then
        local layer = self.m_curColorPanel:getChildByName("Image")
        self.m_guideBtn = layer:getChildByName("Add1")
    end
    self:ShowFaBaoDesc()
end

function XunBaoMainUI:ShowTimeLine()
    if self.m_curColorPanel == nil then
        return
    end
    self:CreateAction()
    --local indexs = {810,810,810,610,410,0,0}
    --local start = indexs[quality] or 810
    --print("XunBaoMainUI:ShowTimeLine",start,start+195)
    --self.m_action:gotoFrameAndPlay(start,start+195,true)
    local quality = 1
    if self.m_curData ~= nil then
        quality = self.m_curData.quality or 1
    end
    local names = {"BlueCompose","BlueCompose","BlueCompose","PurpleCompose","OrangeCompose","RedCompose","RedCompose"}
    self.m_action:play(names[quality],false)
    self:ShowAllParticle(0)
    self.m_isPlaying = true
end

function XunBaoMainUI:PlayEnd1Callback()
    self.m_action:stop()
    self:ShowAllParticle()
    if self.m_curData ~= nil and self.m_curData.id > 0 then
        Utils:InitUI("WanFa.XunBaoPopUI", AppDef.UIType.PopWindow,{1,self.m_curData.id})
    end
    self.m_isPlaying = false
    self:UpdateHeCheng()
end

function XunBaoMainUI:PlayEnd2Callback()
   self.m_action:stop()
   self.m_curColorPanel:setVisible(true)
   self.m_isPlaying = false
end

function XunBaoMainUI:CreateAction() 
    if self.m_action == nil then
        self.m_action = cc.CSLoader:createTimeline("csd/wanfa/XunbaoLayer.csb")
        self.m_action:setAnimationEndCallFunc("BlueOpen",handler(self,XunBaoMainUI.PlayEnd2Callback))
        self.m_action:setAnimationEndCallFunc("PurpleOpen",handler(self,XunBaoMainUI.PlayEnd2Callback))
        self.m_action:setAnimationEndCallFunc("OrangeOpen",handler(self,XunBaoMainUI.PlayEnd2Callback))
        self.m_action:setAnimationEndCallFunc("RedOpen",handler(self,XunBaoMainUI.PlayEnd2Callback))
        self.m_action:setAnimationEndCallFunc("BlueCompose",handler(self,XunBaoMainUI.PlayEnd1Callback))
        self.m_action:setAnimationEndCallFunc("PurpleCompose",handler(self,XunBaoMainUI.PlayEnd1Callback))
        self.m_action:setAnimationEndCallFunc("OrangeCompose",handler(self,XunBaoMainUI.PlayEnd1Callback))
        self.m_action:setAnimationEndCallFunc("RedCompose",handler(self,XunBaoMainUI.PlayEnd1Callback))
    
        self.m_pUILayer:runAction(self.m_action)
        self.m_action:pause()
        --self.m_action:clearFrameEventCallFunc()
        --self.m_action:setFrameEventCallFunc(playEndCallback)
    end
end

function XunBaoMainUI:ShowAllParticle(isHide)
    if self.m_curColorPanel == nil or self.m_curData == nil then
        return
    end
    isHide = isHide or 1
    local panel = self.m_curColorPanel:getChildByName("Image")
    for i=1,#self.m_curData.items do
        local addLayer = panel:getChildByName("Add"..i)
        if addLayer ~= nil then
            local particle = addLayer:getChildByName("Particle")
            if isHide == 1 then
                particle:setVisible(false)
            else
                particle:setVisible(true)
            end
        end
    end
end

function XunBaoMainUI:ClearColorPanel()
    if self.m_curColorPanel == nil or self.m_curData == nil then
        return
    end
    local iconImg = self.m_curColorPanel:getChildByName("Icon")
    local str = "item/"..self.m_curData.pic..".png"
    Utils:SafeLoadTexture(iconImg,str,ccui.TextureResType.localType)
    local panel = self.m_curColorPanel:getChildByName("Image")
    for i=1,#self.m_curData.items do
        local addLayer = panel:getChildByName("Add"..i)
        if addLayer ~= nil then
            local particle = addLayer:getChildByName("Particle")
            local addImg = addLayer:getChildByName("Icon")
            local itemImg = addLayer:getChildByName("Icon_0")
            local numLabel = addLayer:getChildByName("Num")
            particle:setVisible(false)
            addImg:setVisible(true)
            itemImg:setVisible(false)
            numLabel:setString("")
        end
    end
end

function XunBaoMainUI:ShowList()
    local idx = 0
    --self.m_leftListView:removeAllItems()
    self.m_checkHeChengNum = 0
    local max = #self.m_datas
    for i = 1,max do
        if self.m_cellNodes[i] == nil then
            self.m_cellNodes[i] = self.m_leftItemCell:clone()
            self.m_cellNodes[i]:setTag(i)
            self.m_leftListView:pushBackCustomItem(self.m_cellNodes[i])
            self.m_cellNodes[i]:addClickEventListener(handler(self, XunBaoMainUI.ShowHeChengUI))
        end
        self.m_cellNodes[i].userObject = i
        self:ShowOneItem(self.m_cellNodes[i])
        if self.m_curData ~= nil and self.m_curData.id == self.m_datas[i].id then
            idx = i
        end
    end
    for i = max+1,#self.m_cellNodes do
        if self.m_cellNodes[i] ~= nil then
            self.m_cellNodes[i]:removeFromParent()
            self.m_cellNodes[i] = nil
            --self.m_leftItemCell:removeChildByTag(self.m_cellNodes[i]:getTag())
        end
    end
    if idx == 0 and max > 0 then
        idx = 1
    end
    local show = (self.m_checkHeChengNum > 1)
    self.m_OneKeyHCBtn:setVisible(show)
    return idx
end

function XunBaoMainUI:CheckHeCheng(heChengId)
    heChengId = heChengId or 0
    if heChengId == 0 then
        return false
    end
    local cfg = JsonConfig.m_HeCheng.getDefByID(heChengId)
    if cfg == nil or cfg.type ~= 8 then
        return false
    end
    local sign = true
    for i=1,#cfg.item do
        local value = cfg.item[i]
        if value ~= nil then
            local num = LRoleDataMgr.Equip:CountItemNumById(value[1])
            if num < value[3] then
                sign = false
                break
            end
        end
    end
    return sign
end

-- function XunBaoMainUI:GetCellIdx()
--     local idx = 1
--     if self.m_curData == nil then
--         return idx
--     end
--     local max = #self.m_datas
--     for i = 1,max do
--         if self.m_curData ~= nil and self.m_curData.id == self.m_datas[i].id then
--             idx = i
--             break
--         end
--     end
--     return idx
-- end

function XunBaoMainUI:UpdateHeCheng()
    self:SortItem()
    local idx = self:ShowList()
    if idx == 1 then
        self.m_leftListView:refreshView()
        self.m_leftListView:jumpToTop()
    end
    self:SelecteItem(idx,true)
end

function XunBaoMainUI:ShowOneItem(sender)
    if sender == nil then
        return
    end
    local idx = sender.userObject
    local data = self.m_datas[idx]
    if data == nil then
        return
    end
    local node = sender:getChildByName("Big")
    local qualityImg = node:getChildByName("bg")
    local iconImg = node:getChildByName("Icon")
    local nameLabel = node:getChildByName("Name") 
    Utils:SafeLoadTexture(qualityImg,AppDef.ColorKuangArr[data.quality],ccui.TextureResType.plistType)
    nameLabel:setString(data.name)  
    Utils:SafeLoadTexture(iconImg,"item/"..data.pic..".png",ccui.TextureResType.localType)

    local show = self:CheckHeCheng(data.heChengId)
    if show then
        self.m_checkHeChengNum = self.m_checkHeChengNum + 1
    end
    local effect = iconImg:getChildByName("effect")
    if effect ~= nil then
        effect:setVisible(show)
    elseif show then
        local size = iconImg:getContentSize()
        effect = Utils:createAnimEffect(iconImg, cc.p(size.width/2,size.height/2), "res2/animation/effect_tuitu_3")
        effect:setName("effect")
    end
end

--够买次数
function XunBaoMainUI:OnAddCntBtnClick(sender)
    if self.m_isPlaying then
        return
    end
    --local data = LActivityManager:GetXunBaoData()
    --local cnt = data.m_buyCnt or 0
    Utils:OpenUseUI(402,1)--,"arenabuy"
end

--寻宝（碎片+号点击）
function XunBaoMainUI:SeekCallBack(sender)
    if self.m_isPlaying then
        return
    end
    local value = sender.userObject
    if value.sign == 0 then
        return
    end
    local data = LActivityManager:GetXunBaoData()
    local cnt = data.m_cnt or 0
    if cnt == 0 then
        self:OnAddCntBtnClick()
        return
    end
    LuaNetSendMsg:SendXunBaoReq(value.faBaoId,value.suiId)
    --print("XunBaoMainUI:SeekCallBack",value.faBaoId,value.suiId)
end

--寻宝,一键
function XunBaoMainUI:OneKeyCallBack(sender)
    if self.m_isPlaying then
        return
    end
    if self.m_curData == nil or self.m_curData.id == 0 then
        return
    end
    local data = LActivityManager:GetXunBaoData()
    local cnt = data.m_cnt or 0
    if cnt == 0 then
        self:OnAddCntBtnClick()
        return
    end
    if data.m_oneKeySign == 1 then
        LuaNetSendMsg:SendXunBaoOneKeyReq(self.m_curData.id,data.m_autoUse)
        --print("XunBaoMainUI:OneKeyCallBack",self.m_curData.id)
    else
        Utils:InitUI("WanFa.XunBaoPopUI", AppDef.UIType.PopWindow, {2,self.m_curData.id})
    end
end

--法宝合成
function XunBaoMainUI:HeChengCallBack(sender)
    if self.m_isPlaying then
        return
    end
    if self.m_curData == nil or self.m_curData.id == 0 then
        return
    end
    LuaNetSendMsg:SendFaBaoHeChengReq(self.m_curData.id)
    --print("XunBaoMainUI:HeChengCallBack",self.m_curData.id)
end

--法宝一键合成
function XunBaoMainUI:OneKeyHCCallBack(sender)
    if self.m_checkHeChengNum < 2 or self.m_isPlaying then
        return
    end

    LuaNetSendMsg:SendFaBaoHeChengOneKeyReq()
    --print("XunBaoMainUI:HeChengCallBack",self.m_curData.id)
end

--法宝列表左右移动
-- function XunBaoMainUI:MoveCallBack(sender)
--     local data = sender.userObject
--     local percent =  Utils:GetScrollViewXPercent(self.m_leftListView)
--     local num = #self.m_datas
--     if num == 0 then num = 1 end
--     local sign = 100/num
--     local temp = math.ceil(percent/sign)   
--     percent =  temp* sign                                                                                  
--     if data == 1 then
--         percent = percent - sign   --左移
--     else 
--         percent = percent + sign   --右移
--     end
--     if percent < 0 then percent = 0 end
--     if percent > 100 then percent = 100 end
--     self.m_leftListView:scrollToPercentHorizontal(percent,1,true)
-- end

--打开阵容界面
function XunBaoMainUI:OnZhenBtnClick(sender)
    if self.m_isPlaying then
        return
    end
    --Utils:OpenFunction(AppDef.EModuleID.EMID_SJBUZHEN)
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Common.PetFormationUI",AppDef.UIType.FirstClassLayer,{})
    self:SendMsg(LGameMsg.m_initUIMsg)

end

--右下按钮
function XunBaoMainUI:OnBottomRightBtnClick(sender)
    if self.m_isPlaying then
        return
    end
    --奖励面板
    Utils:InitUI("WanFa.XunBaoPopUI", AppDef.UIType.PopWindow, {3})
end

--显示挑战次数
function XunBaoMainUI:ShowTime()
    local value = {}
    local cfg = JsonConfig.m_config.getDefByID(17)
    if cfg ~= nil then
        value = json.decode(cfg.value)
    end
    local max = tonumber(value[3]) or 30
    local data = LActivityManager:GetXunBaoData()
    if self.m_cntLabel ~= nil then
        self.m_cntLabel:setString(""..data.m_cnt or 0)
    end
    local str = ""
    if data.m_sec > 0 and data.m_cnt < max then
        str = string.format(GUITips.RSI_WANFA_TIPS1,Utils:timeString(data.m_sec, true, true))
        self:AddSchedule()
    end
    self.m_tipsLabel:setString(str)
end

-------------------------------------------------------------奖励-end----------------------------------------------------
---------------------------------------------------------法宝描述--------------------------------------------------------
function XunBaoMainUI:ShowFaBaoDesc()
    self.m_faBaoDescPanel:setVisible(false)
    if self.m_curData == nil or self.m_curData.id == 0 then
        return
    end
    local cfg = JsonConfig.m_faBaoConfig.getDefByID(self.m_curData.id)
    if cfg == nil then
        return
    end
    self.m_faBaoDescPanel:setVisible(true)
    if self.m_listView == nil then
        self.m_listView = Utils:CreateListView(self.m_list,LISTVIEW_DIR_VERTICAL,1)
    end
    self.m_listView:removeAllItems()
    if #cfg.attr > 0 then
        self:ShowBaseAttr(cfg)
        self:ShowAttrs(cfg)
    end
    self:ShowDesc(cfg)
    self:ShowName(cfg)
end

function XunBaoMainUI:ShowBaseAttr(cfg)
    if cfg == nil then
        return
    end
    self.m_baseAttr:retain()
    self.m_baseAttr:removeFromParent()
    local typeLable = self.m_baseAttrType
    local valLable = typeLable:getChildByName("Value")
    Utils:ShowAttrLabelSec(typeLable, cfg.attr[1], valLable, "+"..cfg.attr[2])
    self.m_listView:pushBackCustomItem(self.m_baseAttr)
end

function XunBaoMainUI:ShowDesc(cfg)
    if cfg == nil then
        return
    end
    self.m_descLabel:setString(cfg.des or "")
    self.m_descNode:retain()
    self.m_descNode:removeFromParent()
    self.m_listView:pushBackCustomItem(self.m_descNode)
end

function XunBaoMainUI:ShowName(cfg)
    if cfg == nil then
        return
    end
    self.m_nameLabel:setString(cfg.name or "")
end

function XunBaoMainUI:ShowAttrs(cfg)
    self.m_qhAttr:setVisible(false)
    self.m_jlAttr:setVisible(false)
    if cfg == nil  then
        return
    end
    local qhAttrs = {}
    qhAttrs[cfg.atrr_qianghua[1]] = cfg.atrr_qianghua[2]
    local jlAttrs = {}
    for i = 1,#cfg.attr_jinglian do
        local attr = cfg.attr_jinglian[i]
        jlAttrs[attr[1]] = attr[2]
    end
    -- -- --强化
    self:ShowAttr(self.m_qhAttr,self.m_qhAttrType,qhAttrs)
    -- -- --精炼
    self:ShowAttr(self.m_jlAttr,self.m_jlAttrType,jlAttrs)
end

function XunBaoMainUI:ShowAttr(attrNode,attrType,attrs)
    if attrs == nil or  attrNode == nil or attrType == nil  then
        return
    end
    attrNode:setVisible(true)
    attrType:setString("")
    attrType:getChildByName("Value"):setString("")
    local cnt = 0
    for k,v in pairs(attrs) do
        local i = cnt + 1
        local typeLable = attrNode:getChildByName("Atrribute_"..i)
        if typeLable == nil then
            typeLable = attrType:clone()
            local pos = cc.p(attrType:getPosition())
            typeLable:setPositionY(pos.y-typeLable:getContentSize().height*cnt-2)
            attrNode:addChild(typeLable)
            typeLable:setName("Atrribute_"..i)
        end
        cnt = i
        local valLable = typeLable:getChildByName("Value")
        Utils:ShowAttrLabelSec(typeLable, k, valLable, "+"..v)
    end
    --local size = attrNode:getContentSize()
    --local width = size.width+(cnt-1)*(attrType:getContentSize().height+20)
    --print("ShowAttr width",width)
    --attrNode:setContentSize(cc.size(width,size.height))
    attrNode:retain()
    attrNode:removeFromParent()
    self.m_listView:pushBackCustomItem(attrNode)
end
---------------------------------------------------------法宝描述-end----------------------------------------

function XunBaoMainUI:CloseUI()
    LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "WanFa.XunBaoMainUI")
    self:SendMsg(LGameMsg.m_deleteUIMsg)
end

function XunBaoMainUI:DeleteSchedule()
    if self.m_refreshHandler ~= nil then
        Utils:unschedule(nil, self.m_refreshHandler)
        self.m_refreshHandler = nil
    end
end

function XunBaoMainUI:AddSchedule()
    local function RefreshCallback(dt)
        local data = LActivityManager:GetXunBaoData()
        data.m_sec = data.m_sec -1
        if data.m_sec < 0 then
            data.m_sec = 0
        end
        self:ShowTime()
        if data.m_sec == 0 then
            self:DeleteSchedule() 
        end
    end
    self:DeleteSchedule()
    self.m_refreshHandler = Utils:schedule(nil, RefreshCallback, 1, false)
end

function XunBaoMainUI:RegisterGuide()
    if self.m_guideBtn ~= nil then
        Utils:RegisterGuide(GuideDef.StepId.Guide_XunBao_4, self.m_guideBtn, function()
            self:SeekCallBack(self.m_guideBtn)
        end, nil, true)
    end
    if self.m_heChengBtn ~= nil then
        Utils:RegisterGuide(GuideDef.StepId.Guide_XunBao_6, self.m_heChengBtn, handler(self, XunBaoMainUI.HeChengCallBack), nil)
    end
    if self.m_closeBtn ~= nil then
        Utils:RegisterGuide(GuideDef.StepId.Guide_XunBao_8, self.m_closeBtn, handler(self, XunBaoMainUI.CloseUI), nil)
    end
end

function XunBaoMainUI:UpdateRedDot()
    LRedDotCheckMgr:AddCheckBtn(self.m_redPoint, AppDef.RedDotBtnName.XunBaoTask)
end

return XunBaoMainUI