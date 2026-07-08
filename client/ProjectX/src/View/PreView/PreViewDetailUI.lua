local PreViewDetailUI = LUIBase:New()
PreViewDetailUI.__index = PreViewDetailUI
-------------------------------------
function PreViewDetailUI:New(id)
    local o = {}
    setmetatable(o, PreViewDetailUI)
    o:Init(id)
    return o
end
-------------------------------------
function PreViewDetailUI:Init(id)
    self.Script = "PreView.PreViewDetailUI"
    ------------------------------------------------
    self.m_time = 11
    self.m_id = id
    self.m_config = LDataConstMgr:GetNovicePreviewData(id)
    if self.m_config == nil then
        self:RemoveUI()
        return
    end
    ------------------------------------------------
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    if self.m_schedule then
        Utils:unschedule(nil, self.m_schedule)
        self.m_schedule = nil
    end
    self.m_schedule = Utils:schedule(nil, handler(self, PreViewDetailUI.update), 1, false)
    self:update(0)
    self:playSound()
end

-------------------------------------
function PreViewDetailUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_pBtnText = nil
    self.m_config = nil
    if self.m_schedule then
        Utils:unschedule(nil, self.m_schedule)
        self.m_schedule = nil
    end
end
-------------------------------------
function PreViewDetailUI:InitUIControl()
    if self.m_config == nil then
        return
    end
    local pPanel = self.m_pUILayer:getChildByName("xingongneng")
    local nodes = pPanel:getChildren()
    for i=1,#nodes do
        nodes[i]:setVisible(false)
    end
    -----------------------------------------------------------
    local pDiZuo = pPanel:getChildByName("dizuo")
    pDiZuo:setVisible(true)

    local pAnim = ImodAnim:createWithFileSync("res2/fx/shenqizhanshi")
    pAnim:setIgnoreAnchorPointForPosition(false)
    pAnim:setAnchorPoint(cc.p(0.5, 0))
    pAnim:PlayActionRepeat(0)
    pAnim:setPosition(cc.p(pDiZuo:getContentSize().width/2, pDiZuo:getContentSize().height/2+20))
    pDiZuo:addChild(pAnim)
    -----------------------------------------------------------
    local pMask = pPanel:getChildByName("Mask")
    pMask:setVisible(true)
    pMask:setTouchEnabled(true)
    -- pMask:addClickEventListener(handler(self, PreViewDetailUI.RemoveUI))
    -----------------------------------------------------------
    local pNode = pPanel:getChildByName("Node")
    self:InitItemOrModel(pNode)
    -----------------------------------------------------------
    local pTitle = pPanel:getChildByName("Title")
    pTitle:setVisible(true)
    pTitle:setString(self.m_config.desc)
    -----------------------------------------------------------
    local iconCfg = self.m_config.icon
    if #iconCfg >= 3 then
        local pZhanLi = pPanel:getChildByName("zhanli")
        pZhanLi:setVisible(true)

        local pValue = pZhanLi:getChildByName("Value")
        pValue:setString(Utils:getPowerStr(LRoleDataMgr.MyHeroInfo.zhanDouLiInAll))

        local pUpImage = pValue:getChildByName("UpImage")
        local pUpValue = pUpImage:getChildByName("Value_0")
        pUpValue:setString(tostring(iconCfg[3]))

        ccui.Helper:doLayout(pValue)
    end
    -----------------------------------------------------------
    local pBg = pPanel:getChildByName("BgImage")
    if pBg then
        pBg:setVisible(true)
        local pText = pBg:getChildByName("Text")
        local _ = pText and pText:setString(self.m_config.tips or "")
    end
    -----------------------------------------------------------
    local pBtn = pPanel:getChildByName("btn_Confirm")
    pBtn:setVisible(true)
    pBtn:addClickEventListener(handler(self, PreViewDetailUI.RemoveUI))
	self:MarkIntaractCObj(pBtn)
    self.m_pBtnText = pBtn:getChildByName("Text")
end
-------------------------------------
function PreViewDetailUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

-------------------------------------
function PreViewDetailUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/xingongnengLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

function PreViewDetailUI:InitItemOrModel(pParent)
    if self.m_config == nil then
        return
    end
    local iconCfg = self.m_config.icon
    local iType = iconCfg[1]
    local iValue = iconCfg[2]
    if iType == 1 then--道具
        local path = string.format(AppDef.GUIRes.Res_Item_Path, iValue)
        local sp = cc.Sprite:create(path)
        pParent:addChild(sp)
        pParent:setVisible(true)
    elseif iType == 2 then--图片
        local sp = cc.Sprite:createWithSpriteFrameName(iValue)
        if sp then
            sp:setAnchorPoint(cc.p(0.5, 0))
            pParent:addChild(sp)
            pParent:setVisible(true)
        else
            Utils:Debug("ERROR picture!!!!!", iValue)
        end
    elseif iType == 3 then--碎图
        local sp = cc.Sprite:create(iValue)
        if sp then
            sp:setAnchorPoint(cc.p(0.5, 0))
            pParent:addChild(sp)
            pParent:setVisible(true)
        else
            Utils:Debug("ERROR picture!!!!!", iValue)
        end
    elseif iType == AppDef.AwrdItem.AWRD_ITEM_PET then--怪物
        local pData = LDataConstMgr:GetPetData(iValue)
        if pData and pData.pic then
            local pAnim = ModelAniNode:create(AppDef.CEnum.ModelAniType.Monster, 0)
            pAnim:InitAni(AppDef.CEnum.ModelAniType.Monster, pData.pic)
            pAnim:PlayStand(0)
            pParent:addChild(pAnim)
            pParent:setVisible(true)
        end
    elseif iType == AppDef.AwrdItem.AWRD_ITEM_HORSE then--坐骑
        local pAnim = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, 0)
        pAnim:InitAni(AppDef.CEnum.ModelAniType.Hero,0,0,0,0,iValue,0)
        pParent:addChild(pAnim)
        pParent:setVisible(true)
    elseif iType == AppDef.AwrdItem.AWRD_ITEM_WINDS then--翅膀
        local pAnim = ModelAniNode:create(AppDef.CEnum.ModelAniType.Wing, 0)
        pAnim:InitAni(AppDef.CEnum.ModelAniType.Wing,0,0,0,iValue,0,0)
        pAnim:PlayStand(0)
        pParent:addChild(pAnim)
        pParent:setVisible(true)
    elseif iType == AppDef.AwrdItem.AWRD_ITEM_ARTIFACT then--神器
        local pAnim = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, 0)
        pAnim:InitAni(AppDef.CEnum.ModelAniType.Hero,0,0,0,0,0,iValue)
        pAnim:setPosition(cc.p(30, -90))
        pParent:addChild(pAnim)
        pParent:setVisible(true)
    end
end

function PreViewDetailUI:update(dt)
    self.m_time = self.m_time - 1
    if self.m_time <= 0 then
        self.m_time = 0
        self:RemoveUI()
        return
    end
    if self.m_pBtnText ~= nil then
        self.m_pBtnText:setString(string.format(GUITips.RSI_PREVIEW_MSG1, self.m_time))
    end

end

function PreViewDetailUI:playSound()
    if self.m_config == nil or self.m_config.sound == nil or #self.m_config.sound == 0 then
        return
    end
    LGameMsg.m_audioMsg:Change(LAudioEvent.PlayEffect, self.m_config.sound)
    self:SendMsg(LGameMsg.m_audioMsg)
end

return PreViewDetailUI