local GuideLayer = LUIBase:New()
GuideLayer.__index = GuideLayer
-------------------------------------
function GuideLayer:New(data)
    local o = {}
    setmetatable(o, GuideLayer)
    o:Init(data)
    return o
end
-------------------------------------
function GuideLayer:Init(data)
    self.Script = "Guide.GuideLayer"
    self.m_halfVisibleSize = nil
    self.m_stepId = data.stepId
    self.m_pCallback = data.callback
    self.m_pos = data.pos
    self.m_pInfo = nil
    ------------------------------------------------
    self.m_pTouchLayers = {}
    self.m_pPanel = nil
    self.m_pBg = nil
    self.m_pMask = nil
    self.m_pFinger = nil
    self.m_pCircle = nil
    self.m_pGuideBg = nil
    self.m_pLeftHeroImage = nil
    self.m_pLeftDesc = nil
    self.m_pRightHeroImage = nil
    self.m_pRightDesc = nil
    ------------------------------------------------
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    if self.m_stepId then
        self:initData()
    end
end
-------------------------------------
function GuideLayer:onExit()
    self:Destory()
    self.m_pUILayer = nil

    if self.m_pClipNode ~= nil then
        self.m_pClipNode:setVisible(false)
    end
    if self.m_pGuideBg ~= nil then
        self.m_pGuideBg:setVisible(false)
    end
    if self.m_pSelectImage ~= nil then
        self.m_pSelectImage:setVisible(false)
    end
    self.m_pTouchLayers = nil
    self.m_halfVisibleSize = nil
    self.m_stepId = nil
    self.m_pCallback = nil
    self.m_pos = nil
    self.m_pInfo = nil
    self.m_pBg = nil
    if self.m_pMask then
        self.m_pMask:removeFromParent(true)
        self.m_pMask = nil
    end
    self.m_pFinger = nil
    self.m_pCircle = nil
    self.m_pGuideBg = nil
    self.m_pLeftHeroImage = nil
    self.m_pLeftDesc = nil
    self.m_pRightHeroImage = nil
    self.m_pRightDesc = nil
    self.m_pPanel = nil
end
-------------------------------------
function GuideLayer:InitUIControl()
    local pPanel = self.m_pUILayer:getChildByName("Panel")
    pPanel:setLocalZOrder(1)
    self.m_pPanel = pPanel
    -----------------------------------------------------------
    for i=1,4 do
        local pLayer = pPanel:getChildByName("TouchMask"..i)
        if pLayer then
            pLayer:addClickEventListener(handler(self, GuideLayer.ShowFixAnim))
			self:MarkIntaractCObj(pLayer)
            table.insert(self.m_pTouchLayers, pLayer)
        end
    end
    -----------------------------------------------------------
    self.m_pBg = pPanel:getChildByName("Panel_1")
    local _ = self.m_pBg and self.m_pBg:setTouchEnabled(false)
    -----------------------------------------------------------
    local pSelectImage = pPanel:getChildByName("SelectImage")
    pSelectImage:setTouchEnabled(true)
    pSelectImage:addClickEventListener(handler(self, GuideLayer.ClickCallback))
	self:MarkIntaractCObj(pSelectImage)
    self.m_pSelectImage = pSelectImage

    local pCircle = pSelectImage:getChildByName("Image")
    pCircle:setLocalZOrder(1)
    self.m_pFinger = pSelectImage:getChildByName("Finger")
    self.m_pFinger:setLocalZOrder(2)
    -----------------------------------------------------------
    self.m_pGuideBg = pPanel:getChildByName("GuideBg")
    self.m_pLeftHeroImage = self.m_pGuideBg:getChildByName("Image_1")
    self.m_pLeftHeroImage:setVisible(false)
    self.m_pLeftDesc = self.m_pGuideBg:getChildByName("Text_1")
    self.m_pLeftDesc:setVisible(false)
    self.m_pRightHeroImage = self.m_pGuideBg:getChildByName("Image_2")
    self.m_pRightHeroImage:setVisible(false)
    self.m_pRightDesc = self.m_pGuideBg:getChildByName("Text_2")
    self.m_pRightDesc:setVisible(false)
    -----------------------------------------------------------
end
-------------------------------------
function GuideLayer:RegistMsgs()
    self.msgIds = {
        LUIGuideEvent.AutoFinishGuide,
    }

    self:RegistSelf(self, self.msgIds)
end
-------------------------------------
function GuideLayer:ProcessEvent(msg)
    if msg.msgId == LUIGuideEvent.AutoFinishGuide then
        if self.m_stepId == msg.value then
            self:ClickCallback(nil)
        end
    end
end
-------------------------------------
function GuideLayer:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
-------------------------------------
function GuideLayer:InitViewSize()
    self:CreateUINode("csd/GuideLayer.csb")
    local viewsize = AppDef.frameSize
    self.m_halfVisibleSize = cc.size(viewsize.width/2, viewsize.height/2)
end
------------------------------------
function GuideLayer:initData()
    self.m_pInfo = LDataConstMgr:GetGuideData(self.m_stepId)
    if self.m_pInfo == nil then
        local  function DeleteUI()
            self:RemoveUI()
        end
        self.m_pUILayer:setVisible(false)
        Utils:DelayToCallFunc(self.m_pUILayer, 0.1, DeleteUI)
        return
    end
    --ç›´æŽ¥å®Œæˆæ­¥éª¤ï¼Œä¸éœ€è¦ç‚¹å‡?
    if not self.m_pInfo.isOpen then
        Utils:DelayToCallFunc(self.m_pUILayer, 1/30, function()
            self:ClickCallback(nil)
        end)
    else
        self:setCircle()
        self:setMask()
        self:setDialog()
        self:setFinger()
        self:playSound()
        self:setTouchLayers()

        LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.AutoPathEvent.PauseAutoPath)
        self:SendMsg(LGameMsg.m_cBaseMsg)

        Utils:SendMsg(LUIGuideEvent.ShowingGuide, self.m_stepId)
        Utils:DeleteUI("ImproveUI.SkillOpenUI")
    end
end
------------------------------------
function GuideLayer:ClickCallback(sender)
    local stepId = self.m_stepId
    Utils:SendMsg(LUIGuideEvent.GuideComplete, stepId)
    if self.m_pCallback then
        self.m_pCallback()
    end
    self:RemoveUI()
end
-------------------------------------
function GuideLayer:setDialog()
    self.m_pGuideBg:setVisible(false)
    local pos = nil
    if self.m_pInfo.towards == 0 then
        pos = cc.p(self.m_halfVisibleSize.width, 0)
    elseif self.m_pInfo.towards == 1 then
        pos = cc.p(0, 0)
    elseif self.m_pInfo.towards == 2 then
        pos = cc.p(self.m_halfVisibleSize.width*2 - self.m_pGuideBg:getContentSize().width, 0)
    end
    if pos then
        self.m_pGuideBg:setPosition(cc.pAdd(pos, self.m_pInfo.deviant))
        if #self.m_pInfo.desc > 0 then
            self.m_pGuideBg:setVisible(true)
        end
    end
    if self.m_pInfo.towards == 2 then
        self.m_pLeftHeroImage:setVisible(false)
        self.m_pLeftDesc:setVisible(false)
        self.m_pRightHeroImage:setVisible(true)
        self.m_pRightDesc:setVisible(true)
        self.m_pRightDesc:setString(self.m_pInfo.desc)
    else
        self.m_pLeftHeroImage:setVisible(true)
        self.m_pLeftDesc:setVisible(true)
        self.m_pLeftDesc:setString(self.m_pInfo.desc)
        self.m_pRightHeroImage:setVisible(false)
        self.m_pRightDesc:setVisible(false)
    end
end
-------------------------------------
function GuideLayer:setMask()
    self.m_pClipNode = self.m_pUILayer:getChildByTag(0xf5)
    local function addMask()
        local pMask = nil
        local pos = self.m_pInfo.pos or self.m_pos
        if self.m_pInfo.fixId == 1 then
            pMask = cc.Sprite:createWithSpriteFrameName("res/UI/ui_juese/ui_jineng_kuang_xuanzhong_mask.png")
            pMask:setContentSize(self.m_pSelectImage:getContentSize())
            pMask:setPosition(pos)
        else
            local maskSize = self.m_pInfo.maskSize or self.m_pSelectImage:getContentSize()
            pMask = cc.Scale9Sprite:create(cc.rect(1, 1, 28, 26), "UI/BattleVectoryBkg2.png")
            pMask:setIgnoreAnchorPointForPosition(false)
            pMask:setAnchorPoint(cc.p(0.5, 0.5))
            pMask:setContentSize(maskSize)
            local visibleSize = AppDef.frameSize
            local towards = self.m_pInfo.sizeTowards or 0
            if towards == 1 then--左下
            elseif towards == 2 then--右下
                pos = cc.p(pos.x-1334+visibleSize.width, pos.y/750*visibleSize.height)
            elseif towards == 3 then--中上
                pos = cc.pAdd(cc.pSub(pos, cc.p(667,750)), cc.p(visibleSize.width/2, visibleSize.height))
            elseif towards == 4 then--左上
                pos = cc.pAdd(cc.pSub(pos, cc.p(0,750)), cc.p(0, visibleSize.height))
            elseif towards == 5 then--右上
                pos = cc.pAdd(cc.pSub(pos, cc.p(1334,750)), cc.p(visibleSize.width, visibleSize.height))
            elseif towards == 6 then--中中
                pos = cc.pAdd(cc.pSub(pos, cc.p(667,375)), cc.p(visibleSize.width/2, visibleSize.height/2))
            elseif towards == 7 then--中左
                pos = cc.pAdd(cc.pSub(pos, cc.p(0,375)), cc.p(0, visibleSize.height/2))
            elseif towards == 8 then--中右
                pos = cc.pAdd(cc.pSub(pos, cc.p(1334,375)), cc.p(visibleSize.width, visibleSize.height/2))
            else
                pos = cc.pAdd(cc.pSub(pos, cc.p(667,0)), cc.p(visibleSize.width/2, 0))
            end
            local anchor = cc.p(pos.x/visibleSize.width, pos.y/visibleSize.height)

            local size = pMask:getContentSize()
            pMask:setAnchorPoint(anchor)
            pMask:setPosition(cc.p(pos.x+(anchor.x-0.5)*size.width, pos.y+(anchor.y-0.5)*size.height))
        end
        self.m_pMask = pMask
    end

    if self.m_pClipNode ~= nil then
        if self.m_pMask ~= nil then
            self.m_pMask:removeFromParent(true)
            self.m_pMask = nil
        end
        addMask()
        self.m_pClipNode:setStencil(self.m_pMask)
        self.m_pClipNode:setVisible(true)--self.m_pInfo.fixId ~= 2
        return
    end

    addMask()

    local pClipNode = cc.ClippingNode:create(self.m_pMask)
    pClipNode:setAlphaThreshold(0)
    
    self.m_pBg:retain()
    self.m_pBg:removeFromParent(false)
    self.m_pBg:setAnchorPoint(cc.p(0, 0))
    self.m_pBg:setPosition(cc.p(0, 0))
    self.m_pBg:setContentSize(AppDef.frameSize)
    pClipNode:addChild(self.m_pBg)
    self.m_pBg:release()
    self.m_pBg:setOpacity(100)
    self.m_pBg:runAction(cc.FadeTo:create(0.075, 255))

    pClipNode:setPosition(AppDef.Director:getVisibleOrigin())
    pClipNode:setInverted(true)
    self.m_pUILayer:addChild(pClipNode, 0, 0xf5)
    self.m_pClipNode = pClipNode
    self.m_pClipNode:setVisible(true)--self.m_pInfo.fixId ~= 2
end
-------------------------------------
function GuideLayer:setCircle()
    -- dump(self.m_pInfo, "self.m_pInfo--->")
    local pImage = self.m_pSelectImage:getChildByName("Image")
    if self.m_pInfo.fixId == 1 then
        pImage:loadTexture("res/UI/ui_xingongneng/ui_xinshouyindao_dianji.png", UI_TEX_TYPE_PLIST)
        pImage:setScale9Enabled(false)
        pImage:setContentSize(cc.size(130, 130))
        self.m_pSelectImage:setContentSize(cc.size(100, 100))
    else
        pImage:loadTexture("res/UI/ui_xingongneng/ui_texiao_fangkuang.png", UI_TEX_TYPE_PLIST)
        pImage:setScale9Enabled(true)
        if self.m_pInfo.size then
            pImage:setContentSize(cc.size(self.m_pInfo.size.width+38, self.m_pInfo.size.height+38))
        else
            pImage:setContentSize(cc.size(130, 130))
        end
        self.m_pSelectImage:setContentSize(cc.size(pImage:getContentSize().width-38, pImage:getContentSize().height-38))
    end

    ccui.Helper:doLayout(self.m_pSelectImage)
    self.m_pSelectImage:setPosition(self.m_pos)
    self.m_pSelectImage:setSwallowTouches(self.m_pCallback ~= nil)
    self.m_pSelectImage:setVisible(true)
end
-------------------------------------
function GuideLayer:setFinger()
    local size = self.m_pFinger:getParent():getContentSize()
    local pos = cc.p(self.m_pInfo.fingerOffset.x + size.width/2, self.m_pInfo.fingerOffset.y + size.height/2)
    self.m_pFinger:setPosition(pos)

    local pDiff = cc.p(10, -15)
    local pos2 = cc.pAdd(pos, pDiff)
    self.m_pFinger:stopAllActions()
    local pMove1 = cc.EaseOut:create(cc.MoveTo:create(1, pos2), 1) 
    local pMove2 = cc.EaseOut:create(cc.MoveTo:create(1, pos), 1)
    local seq = cc.Sequence:create(pMove1, cc.DelayTime:create(0.0), pMove2)
    self.m_pFinger:runAction(cc.RepeatForever:create(seq))
end
-------------------------------------
function GuideLayer:playSound()
    if self.m_pInfo ~= nil and self.m_pInfo.sound ~= nil and #(self.m_pInfo.sound) > 0 then
        local soundPath = "Guide_cv/" .. self.m_pInfo.sound
        LGameMsg.m_audioMsg:Change(LAudioEvent.PlayEffect, soundPath)
        self:SendMsg(LGameMsg.m_audioMsg)
    end
end
-------------------------------------
function GuideLayer:setTouchLayers()
    self.m_pPanel:setTouchEnabled(false)

    local function _CreateLayer(size, anchor, color)
        local pLayer = ccui.Layout:create()
        pLayer:setContentSize(size or cc.size(0, 0))
        pLayer:setTouchEnabled(true)
        pLayer:setIgnoreAnchorPointForPosition(false)
        pLayer:setAnchorPoint(anchor or cc.p(0, 0))
        pLayer:setBackGroundColorType(LAYOUT_COLOR_SOLID)
        pLayer:setBackGroundColor(color or cc.c3b(0, 0, 0))
        pLayer:setBackGroundColorOpacity(0)
        return pLayer
    end
    
    if #self.m_pTouchLayers < 4 then
        for i=#self.m_pTouchLayers+1,4 do
            local anchor = nil
            local color = nil
            if i == 1 then
                color = cc.c3b(255, 0, 0)
            elseif i == 2 then
                color = cc.c3b(0, 255, 0)
            elseif i == 3 then
                anchor = cc.p(0, 1)
                color = cc.c3b(0, 0, 255)
            elseif i == 4 then
                anchor = cc.p(1, 0)
                color = cc.c3b(255, 255, 0)
            end
            local pLayer = _CreateLayer(nil, anchor, color)
            pLayer:setName("TouchMask"..i)
            pLayer:addClickEventListener(handler(self, GuideLayer.ShowFixAnim))
			self:MarkIntaractCObj(pLayer)
            self.m_pPanel:addChild(pLayer)
            table.insert(self.m_pTouchLayers, pLayer)
        end
    end
    local touchSize = self.m_pSelectImage:getContentSize()
    local visibleSize = AppDef.frameSize
    for i=1,#self.m_pTouchLayers do
        local pLayer = self.m_pTouchLayers[i]
        local size = nil
        local pos = nil
        if i == 1 then
            pos = cc.p(0, self.m_pos.y + touchSize.height/2)
            size = cc.size(visibleSize.width, visibleSize.height - self.m_pos.y - touchSize.height/2)
        elseif i == 2 then
            pos = cc.p(self.m_pos.x + touchSize.width/2, 0)
            size = cc.size(visibleSize.width - self.m_pos.x - touchSize.width/2, visibleSize.height)
        elseif i == 3 then
            pos = cc.p(0, self.m_pos.y - touchSize.height/2)
            size = cc.size(visibleSize.width, self.m_pos.y - touchSize.height/2)
        elseif i == 4 then
            pos = cc.p(self.m_pos.x - touchSize.width/2, 0)
            size = cc.size(self.m_pos.x - touchSize.width/2, visibleSize.height)
        end
        if size then
            pLayer:setContentSize(size)
        end
        if pos then
           pLayer:setPosition(pos)
        end
    end
end
-------------------------------------
function GuideLayer:ShowFixAnim(sender)
    if self.m_pMask == nil or self.m_pInfo.fixId ~= 2 then
        return
    end
    local visibleSize = AppDef.frameSize
    local size = self.m_pMask:getContentSize()

    self.m_pMask:setScale(visibleSize.width/size.width, visibleSize.height/size.height)

    local arr = {}
    -- table.insert(arr, cc.CallFunc:create(function()
    --     self.m_pClipNode:setVisible(true)
    -- end))
    table.insert(arr, cc.ScaleTo:create(0.3, 1, 1))
    table.insert(arr, cc.DelayTime:create(1))
    -- table.insert(arr, cc.CallFunc:create(function()
    --     self.m_pClipNode:setVisible(false)
    -- end))
    self.m_pMask:stopAllActions()
    self.m_pMask:runAction(cc.Sequence:create(arr))
end
-------------------------------------

function GuideLayer:UpdateUserData(data)
    if self.m_stepId == data.stepId and (data.stepId == 201 or data.stepId == 316) then
        self.m_pos = data.pos
        self:initData()
    end
end
return GuideLayer