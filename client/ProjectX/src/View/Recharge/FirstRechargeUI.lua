--[[
lua里面的游戏逻辑控制
首充、次充界面
]]

local FirstRechargeUI = LUIBase:New()
FirstRechargeUI.__index = FirstRechargeUI
--local this = LTcpSocket
function FirstRechargeUI:New()
	local o = LUIBase:New()
	setmetatable(o,FirstRechargeUI)	
    o:Init()
	return o
end

function FirstRechargeUI:Init()
    self.m_pUILayer = cc.CSLoader:createNode("csd/huodong/FirstChargeLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    self:RegistMsgs()
    self:InitData(isFirst)
    self:AddTouchEvt()

    self.m_sign = 1

    local isFirstOpen = (not Utils:ToBool(LRoleDataMgr:GetSettingConfig(
            AppDef.ServerSetIndex.SSI_FIRST_OPEN_SC)))
    if isFirstOpen then
        self.m_isFirstOpen = true
        LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.AutoPathEvent.PauseAutoPath)
        self:SendMsg(LGameMsg.m_cBaseMsg)
    end
--    self:LoadPetList()
--    self:LoadWingList()
--    self:LoadMountList()
--    self:LoadItemList()
--    self:ShowCash()
--    self:ShowPetModel()
--    self:ShowMountModel()
end



function FirstRechargeUI:onExit()
    self:Destory()
    if self.m_btn ~= nil then
        local imod = self.m_btn:getChildByTag(9999)
        if imod ~= nil then
            imod:removeFromParent()
        end
        self.m_btn = nil
    end
    self.m_pUILayer = nil

    self.m_Mark = nil
    self.m_btnLabel = nil
    self.m_costPanel = nil
    self.m_costLabel = nil
    self.m_closeButton = nil
    self.m_petCell = nil
    if self.m_star then
        self.m_star:release()
        self.m_star = nil
    end
    if self.m_petCell then
        self.m_petCell:release()
        self.m_petCell = nil
    end
    self.m_iconBgList = nil
    self.m_titleImg1 = nil
    self.m_descLabel1 = nil
    self.m_titleImg2 = nil
    self.m_descLabel2 = nil

    self.m_mountNode = nil
    self.m_pMountModelNode = nil

    self.m_petNode = nil
    self.m_pPetModelNode = nil
end

--[[
注册UI消息
]]
function FirstRechargeUI:RegistMsgs()
    self.msgIds = 
    {
        LUIMainEvent.CheckFirstRechargeBtn,          --更新Btn状态
        LUIActivityEvent.RefreshFirstRechargeUI,     --刷新信息
    }
    self:RegistSelf(self,self.msgIds)
end

function FirstRechargeUI:ProcessEvent(msg)
    if msg.msgId == LUIMainEvent.CheckFirstRechargeBtn then
        self:CheckFirstSign()
    elseif msg.msgId == LUIActivityEvent.RefreshFirstRechargeUI then
        print("===================================== 111111111111111111111111111 >>>")
        self:UpdateInfo()
    end
end

function FirstRechargeUI:UpdateInfo()
    if self.m_isFirst == nil then
        self.m_isFirst = (LRoleDataMgr.m_firstRechargeState == 0)
        if not self.m_isFirst then       
            self.m_titleImg1:setVisible(false)
            self.m_descLabel1:setVisible(false)
            self.m_titleImg2:setVisible(true)
            self.m_descLabel2:setVisible(true)
        end
    end
    print("FirstRechargeUI:UpdateInfo ==>", self.m_isFirst, LRoleDataMgr.m_firstRechargeState)
    if self.m_isFirst ~= (LRoleDataMgr.m_firstRechargeState == 0) then
        return
    end

    self.m_sign = 1
    self:LoadPetList()
    self:LoadWingList()
    self:LoadMountList()
    self:LoadItemList()
    self:ShowCash()
    self:ShowPetModel()
    self:ShowMountModel()
    self:InitFirstSign()
    self:InitSound()
end

function FirstRechargeUI:InitData()
    local panel = self.m_pUILayer:getChildByName("Panel"):getChildByName("Bg") 
    self.m_Mark = self.m_pUILayer:getChildByName("Panel"):getChildByName("Panel_1") 
    --button
    local btnPanel = panel:getChildByName("BtnBg")
    self.m_btn = btnPanel:getChildByName("Button")

    self.m_btnLabel = self.m_btn:getChildByName("Text")
    self.m_costPanel = btnPanel:getChildByName("Recharge")
    self.m_costLabel = self.m_costPanel:getChildByName("Value")--已充金额/奖励需求金额
    --self.m_isFirst = (LRoleDataMgr.m_firstRechargeState == 0)
--    self:InitFirstSign()
    self.m_closeButton = panel:getChildByName("CloseBtnBg"):getChildByName("CloseBtn")

    --宠物Icon
    self.m_petCell = panel:getChildByName("IconColor")
    self.m_star = self.m_petCell:getChildByName("StarsList"):getChildByName("Star")
    self.m_star:retain()
    self.m_star:removeFromParent()
    self.m_petCell:retain()
    self.m_petCell:removeFromParent()
    --icon底
    self.m_iconBgList = {}
    local listPanel1 = panel:getChildByName("List_1")
    for i= 1,3 do
        local icon = listPanel1:getChildByName("IconBg_"..i)
        if icon ~= nil then
            table.insert(self.m_iconBgList,icon)
        end
    end
    local listPanel2 = panel:getChildByName("List_2")
    for i= 1,2 do
        local icon = listPanel2:getChildByName("IconBg_"..i)
        if icon ~= nil then
            table.insert(self.m_iconBgList,icon)
        end
    end

    --标题
    self.m_titleImg1 = panel:getChildByName("TitleImage_1")
    self.m_descLabel1 = panel:getChildByName("Tips"):getChildByName("Text_1")
    self.m_titleImg2 = panel:getChildByName("TitleImage_2")
    self.m_descLabel2 = panel:getChildByName("Tips"):getChildByName("Text_2")

    self.m_titleImg1:setVisible(true)
    self.m_descLabel1:setVisible(true)
    self.m_titleImg2:setVisible(false)
    self.m_descLabel2:setVisible(false)
    
    local modelPanel = self.m_pUILayer:getChildByName("Panel"):getChildByName("ImageBg") 
    --模型节点
    self.m_mountNode = modelPanel:getChildByName("Base_1"):getChildByName("Node")
    self.m_pMountModelNode = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, 0)
    self.m_mountNode:addChild(self.m_pMountModelNode)

    self.m_petNode = modelPanel:getChildByName("Base_2"):getChildByName("Node")
    self.m_pPetModelNode = ModelAniNode:create(AppDef.CEnum.ModelAniType.Monster, 0)
    self.m_petNode:addChild(self.m_pPetModelNode)

    self.m_mountNode:getParent():setVisible(false)
    self.m_petNode:getParent():setVisible(false)
    --self.m_btnimod = nil
end

function FirstRechargeUI:InitFirstSign()
    self.m_isFirst = (LRoleDataMgr.m_firstRechargeState == 0)
    local data = nil
    local size = self.m_btn:getContentSize()
    if self.m_isFirst then
        data = LRechargeDataMgr:GetFirstRechargeData()
        self.m_costPanel:setVisible(false)
        if data.isPaid then 
            self.m_btnLabel:setString(GUITips.RSI_RECHARGE_TIP1)
            if self.m_btn ~= nil then
                local imod = self.m_btn:getChildByTag(9999)
                if imod ~= nil then
                    imod:removeFromParent()
                end
            end
        else
            local imod = Utils:CreateImod("res2/fx/yueka",cc.p(size.width/2,size.height/2),self.m_btn,1)
            imod:setTag(9999)
            imod:PlayActionRepeat(0)
        end
    else
        data = LRechargeDataMgr:GetSecondRechargeData()
        self.m_costPanel:setVisible(true) --只次冲用
        if data.isPaid then 
            self.m_btnLabel:setString(GUITips.RSI_RECHARGE_TIP1)
            if self.m_btn ~= nil then
                local imod = self.m_btn:getChildByTag(9999)
                if imod ~= nil then
                    imod:removeFromParent()
                end
            end
        else
            local imod = Utils:CreateImod("res2/fx/yueka",cc.p(size.width/2,size.height/2),self.m_btn,1)
            imod:setTag(9999)
            imod:PlayActionRepeat(0)
        end
    end
end

function FirstRechargeUI:CheckFirstSign()
    if LRoleDataMgr.m_firstRechargeState == 1 or LRechargeDataMgr.m_secondRechargeState == 1 then
        if self.m_btn ~= nil then
            self.m_btn:setEnabled(false)
            local imod = self.m_btn:getChildByTag(9999)
            if imod ~= nil then
                imod:removeFromParent()
            end       
        end
        if self.m_btnLabel ~= nil then
            self.m_btnLabel:setString(GUITips.RSI_RECHARGE_TIP2)
        end
    end
end

function FirstRechargeUI:AddTouchEvt()
    local function CloseCallBack(sender)   
        if self.m_isFirstOpen then
            Utils:SendMsg(LUITaskDataEvent.ContinueTask)
        end 
	    self:CloseUI()
    end
    self.m_closeButton:addClickEventListener(CloseCallBack)
	self:MarkIntaractCObj(self.m_closeButton)
    self.m_Mark:addClickEventListener(CloseCallBack)
	self:MarkIntaractCObj(self.m_Mark)
    
    local function EnterCallBack(sender)
        if self.m_isFirst then
            local info = LRechargeDataMgr:GetFirstRechargeData()
            if info.isPaid then
                LuaNetSendMsg:QueryKaifuHuodong(9,3)
            else
                self:OpenRechargeMainUI()
            end
        else 
            local info = LRechargeDataMgr:GetSecondRechargeData()
            if info.isPaid then
                LuaNetSendMsg:QueryKaifuHuodong(42,3)
            else
                self:OpenRechargeMainUI()
            end
        end
    end
    self.m_btn:addClickEventListener(EnterCallBack)
	self:MarkIntaractCObj(self.m_btn)
end

function FirstRechargeUI:OpenRechargeMainUI()
    self:CloseUI()
    --LuaNetSendMsg:QueryPayPriceList()
    Utils:OpenRechargeMainUI()
end

function FirstRechargeUI:LoadItemList()
    local data = nil
    if self.m_isFirst then
        data = LRechargeDataMgr:GetFirstRechargeData()
    else
        data = LRechargeDataMgr:GetSecondRechargeData()
    end
    local info = data.itemList
    if info == nil or #info == 0 then
        return
    end
    local size = #info
    if size > #self.m_iconBgList then
        size = #self.m_iconBgList
    end
    print("FirstRechargeUI:LoadItemList ==>", size)
    for i=1,size do
        local item = Utils:GetItemCellValue(self.m_iconBgList[self.m_sign],0,info[i].id,true,true,info[i].num,nil,true)
        local quality = Utils:getQualityByItem(item)
        if quality >= 5 then
            Utils:createAnimEffect(self.m_iconBgList[self.m_sign], cc.p(self.m_iconBgList[self.m_sign]:getPosition()), "res2/fx/gaojiwupin")
        end

        self.m_sign = self.m_sign + 1
        if self.m_sign > #self.m_iconBgList then
            break
        end
    end
end


--加载坐骑列表
function FirstRechargeUI:LoadMountList()
    local data = nil
    if self.m_isFirst then
        data = LRechargeDataMgr:GetFirstRechargeData()
    else
        data = LRechargeDataMgr:GetSecondRechargeData()
    end
    local info = data.mountList
    if info == nil or #info == 0 then
        return
    end
    local size = #info
    if size > #self.m_iconBgList then
        size = #self.m_iconBgList
    end
    for i=1,size do
        self:ShowMountIcon(info[i],self.m_iconBgList[self.m_sign])
        self.m_sign = self.m_sign + 1
        if self.m_sign > #self.m_iconBgList then
            break
        end
    end
end

--加载坐骑图标
function FirstRechargeUI:ShowMountIcon(id,parent)

    Utils:AddSprite(parent, AppDef.ColorKuangArr[5])
    local icon = ccui.ImageView:create()
    icon.userObject = id
    icon:loadTexture("res2/Horse_Bust/"..id.."_tou.png",ccui.TextureResType.localType)
    local parentHeight = parent:getContentSize().height
    local itemHeight = icon:getContentSize().height
    local temp = (parentHeight-itemHeight)/2
    icon:setAnchorPoint(cc.p(0,0))
    icon:setPosition(cc.p(temp,temp))
    parent:addChild(icon)
    icon:setTouchEnabled(true)

    local function ShowInfo(sender)--查看信息
        local id = sender.userObject
        Utils:OpenWearTips("Mount",id)
    end
    icon:addClickEventListener(ShowInfo)
	self:MarkIntaractCObj(icon)

    local posX = parent:getContentSize().width / 2
    local posY = parent:getContentSize().height / 2
    Utils:createAnimEffect(parent, cc.p(posX, posY), "res2/fx/gaojiwupin")
end

function FirstRechargeUI:LoadWingList()
    local data = nil
    if self.m_isFirst then
        data = LRechargeDataMgr:GetFirstRechargeData()
    else
        data = LRechargeDataMgr:GetSecondRechargeData()
    end
    local info = data.wingList
    if info == nil or #info == 0 then
        return
    end
    local size = #info
    if size > #self.m_iconBgList then
        size = #self.m_iconBgList
    end
    for i=1,size do
        self:ShowWingIcon(info[i],self.m_iconBgList[self.m_sign])
        self.m_sign = self.m_sign + 1
        if self.m_sign > #self.m_iconBgList then
            break
        end
    end
end

--加载翅膀图标
function FirstRechargeUI:ShowWingIcon(id,parent)

    Utils:AddSprite(parent, AppDef.ColorKuangArr[5])
    
    local icon = ccui.ImageView:create()
    icon.userObject = id
    icon:loadTexture("res2/Wing_Bust/"..id.."_tou.png",ccui.TextureResType.localType)
    local parentHeight = parent:getContentSize().height
    local itemHeight = icon:getContentSize().height
    local temp = (parentHeight-itemHeight)/2
    icon:setAnchorPoint(cc.p(0,0))
    icon:setPosition(cc.p(temp,temp))
    parent:addChild(icon)
    icon:setTouchEnabled(true)

    local function ShowInfo(sender)--查看信息
        local id = sender.userObject
        Utils:OpenWearTips("Wing",id)
    end
    icon:addClickEventListener(ShowInfo)
	self:MarkIntaractCObj(icon)

    local posX = parent:getContentSize().width / 2
    local posY = parent:getContentSize().height / 2
    Utils:createAnimEffect(parent, cc.p(posX, posY), "res2/fx/gaojiwupin")
end

function FirstRechargeUI:LoadPetList()
    local data = nil
    if self.m_isFirst then
        data = LRechargeDataMgr:GetFirstRechargeData()
    else
        data = LRechargeDataMgr:GetSecondRechargeData()
    end
    local info = data.petList
    if info == nil or #info == 0 then
        return
    end
    local size = #info
    if size > #self.m_iconBgList then
        size = #self.m_iconBgList
    end
    for i=1,size do
        local item = self.m_petCell:clone()
        -- dump(info[i], "pet data ===>")
        Utils:ShowPetByData(info[i], self.m_iconBgList[self.m_sign], item)
        self.m_iconBgList[self.m_sign]:addChild(item)
        local info = LPetDataMgr:FindPetDataById(info[i].id)
        if info.quality >= 3 then
            Utils:createAnimEffect(self.m_iconBgList[self.m_sign], cc.p(self.m_iconBgList[self.m_sign]:getPosition()), "res2/fx/gaojiwupin")
        end
        self.m_sign = self.m_sign + 1
        if self.m_sign > #self.m_iconBgList then
            break
        end
    end
end

function FirstRechargeUI:ShowCash()
    if self.m_isFirst then
        return
    end
    local data = LRechargeDataMgr:GetSecondRechargeData()
    self.m_costLabel:setString(""..data.nowYB.."/"..data.needYB)
end

function FirstRechargeUI:CloseUI()
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Recharge.FirstRechargeUI")
	self:SendMsg(LGameMsg.m_initUIMsg)
end

function FirstRechargeUI:ShowPetModel()
    local data = nil
    if self.m_isFirst then
        data = LRechargeDataMgr:GetFirstRechargeData()
    else
        data = LRechargeDataMgr:GetSecondRechargeData()
    end
    if data == nil or data.petList == nil or #data.petList == 0 then
        --self.m_pPetModelNode:setVisible(false)
        return
    end
    local dPet =  LPetDataMgr:FindPetDataById(data.petList[1].id)
    if dPet == nil then return end

    local deskImg = self.m_petNode:getParent()
    deskImg:setVisible(true)
    self.m_pPetModelNode:InitAni(AppDef.CEnum.ModelAniType.Monster, dPet.pic)
    self.m_pPetModelNode:PlayStand(dPet.defaultFace)

    local size = deskImg:getContentSize()
    self.m_imod2 = Utils:CreateImod("res2/fx/shenqizhanshi",cc.p(size.width/2,size.height/1.5),deskImg,1)
    self.m_imod2:setLocalZOrder(-1)
    self.m_imod2:PlayActionRepeat(0)
end

function FirstRechargeUI:ShowMountModel()
    local data = nil
    if self.m_isFirst then
        data = LRechargeDataMgr:GetFirstRechargeData()
    else
        data = LRechargeDataMgr:GetSecondRechargeData()
    end
    if data == nil or data.mountList == nil or #data.mountList == 0 then
        --self.m_pMountModelNode:setVisible(false)
        self:ShowWingModel()
        return
    end
    local deskImg = self.m_mountNode:getParent()
    deskImg:setVisible(true)
    self.m_pMountModelNode:InitAni(AppDef.CEnum.ModelAniType.Hero,0,0,0,0,data.mountList[1],0)
    self.m_pMountModelNode:PlayStand(0)

    local size = deskImg:getContentSize()
    self.m_imod1 = Utils:CreateImod("res2/fx/shenqizhanshi",cc.p(size.width/2,size.height/1.5),deskImg,1)
    self.m_imod1:setLocalZOrder(-1)
    self.m_imod1:PlayActionRepeat(0)
end


function FirstRechargeUI:ShowWingModel()
    local data = nil
    if self.m_isFirst then
        data = LRechargeDataMgr:GetFirstRechargeData()
    else
        data = LRechargeDataMgr:GetSecondRechargeData()
    end
    if data == nil or data.wingList == nil or #data.wingList == 0 then
        --self.m_pMountModelNode:setVisible(false)
        return
    end
    local deskImg = self.m_mountNode:getParent()
    deskImg:setVisible(true)
    self.m_pMountModelNode:InitAni(AppDef.CEnum.ModelAniType.Wing,0,0,0,data.wingList[1],0,0)
    self.m_pMountModelNode:PlayStand(0)

    local size = deskImg:getContentSize()
    self.m_imod1 = Utils:CreateImod("res2/fx/shenqizhanshi",cc.p(size.width/2,size.height/1.5),deskImg,1)
    self.m_imod1:setLocalZOrder(-1)
    self.m_imod1:PlayActionRepeat(0)
end

function FirstRechargeUI:InitSound()
    -- if self.m_isFirst then
    --     if not Utils:ToBool(LRoleDataMgr:GetSettingConfig(AppDef.ServerSetIndex.SSI_FIRST_SHOW_SC)) then
    --         LRoleDataMgr:SetSettingConfig(AppDef.ServerSetIndex.SSI_FIRST_SHOW_SC, 1)
    --         Utils:PlayEffect("GuideBGM", "id", 3, nil, true)
    --     end
    -- else
    --     if not Utils:ToBool(LRoleDataMgr:GetSettingConfig(AppDef.ServerSetIndex.SSI_FIRST_SHOW_CC)) then
    --         LRoleDataMgr:SetSettingConfig(AppDef.ServerSetIndex.SSI_FIRST_SHOW_CC, 1)
    --         Utils:PlayEffect("GuideBGM", "id", 4, nil, true)
    --     end
    -- end
end


return FirstRechargeUI