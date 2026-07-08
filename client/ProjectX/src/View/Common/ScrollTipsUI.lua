--滚动信息提示界面
local ScrollTipsUI = LUIBase:New()
ScrollTipsUI.__index = ScrollTipsUI
ScrollTipsUI.BgSize = nil
ScrollTipsUI.BgCapInsets = nil
ScrollTipsUI.BgHeight = nil
ScrollTipsUI.MaxTipsNodes = 5--最大缓存5个
--local this = LTcpSocket
function ScrollTipsUI:New(userData)
    local o = LUIBase:New()
    setmetatable(o,ScrollTipsUI)   
    o:Init(userData)
    return o
end

function ScrollTipsUI:Init(userData)
    --self.m_pUILayer = cc.CSLoader:createNode("csd/LoginBgLayer.csb")
    self.m_IsCenterTiping = false
    self.m_VecCenterTipNodes = {}
    self.m_pUILayer = cc.Node:create()
    self.m_pTipsUIBuff = {}--上浮提示数组
    self.m_pUsedTipsUIArr = {}--正在使用的上浮提示数组
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:UpdateUserData(userData)
end

function ScrollTipsUI:onExit()
    self.m_IsCenterTiping = nil
    self.m_pTipsArr = nil
    self.m_pUILayer = nil
    self.m_VecCenterTipNodes = nil
end

function ScrollTipsUI:UpdateUserData(userData)
    if userData then
        if not self.m_pUILayer:isVisible() then
            self.m_pUILayer:setVisible(true)
        end
        self:SetTexts(userData[1])
    end
end

function ScrollTipsUI:SetTexts(tips)
    if self.m_pTipsArr == nil then
        self.m_isNew = true
        self.m_pTipsArr = {}
    end

    if self.m_IsCenterTiping == false then
        self:CreateTips(tips)
        self.m_IsCenterTiping = true
    else
        table.insert(self.m_pTipsArr,tips)
    end
end

function ScrollTipsUI:CreateTips(msg)
    local function ShowNext(sender)
        self:OnTipsNext(sender)
    end

    local function delayEnd(pSender)
        self:CenterTipsDelayEnd(pSender)
    end

    --local str = table.remove(self.m_pTipsArr,1)
    local node = self:GetTipsNode(msg)
    local move = cc.MoveBy:create(0.3,cc.p(0,node:getContentSize().height))
    local moveSine = cc.EaseSineIn:create(move)
    local callfun = cc.CallFunc:create(ShowNext)
    local fout = cc.FadeTo:create(0.3,255)
    
    node:runAction(cc.Sequence:create(move,callfun))
    node:runAction(fout)

    local delay2 = cc.DelayTime:create(2)
    local callfun2 = cc.CallFunc:create(delayEnd)
    node:runAction(cc.Sequence:create(delay2,callfun2))
end

function ScrollTipsUI:OnTipsNext(pSender)
    --先进行中间部分
    --CCPoint tp = ObjectHelper::calPosToUIByOffset(ccp(480,267 + pSender->getContentSize().height));
    local move = cc.MoveBy:create(0.3,cc.p(0,pSender:getContentSize().height))
    pSender:runAction(move)
    
    --需要移动已经存在的中间部分
    for i = 1, #self.m_VecCenterTipNodes do
        local it = self.m_VecCenterTipNodes[i]
        --CCPoint tp = ObjectHelper::calPosToUIByOffset(ccp(480, it->getPositionY() + it->getContentSize().height));
        local TipMove = cc.MoveBy:create(0.3,cc.p(0,it:getContentSize().height))
        it:runAction(TipMove)
    end
    table.insert(self.m_VecCenterTipNodes, pSender)
    --最多只保留3条
    if #self.m_VecCenterTipNodes > 3 then
        self.m_VecCenterTipNodes[1]:stopAllActions()
        self:CenterTipsDelayEnd(self.m_VecCenterTipNodes[1])
    end
    
    if #self.m_pTipsArr > 0 then
        self:CreateTips(self.m_pTipsArr[1])
        table.remove(self.m_pTipsArr,1)
        
    else
        self.m_IsCenterTiping = false
    end
end

function ScrollTipsUI:CenterTipsDelayEnd(pSender)
    local function effectEnd(sender)
        --sender:removeFromParent()
        for i = 1, #self.m_pUsedTipsUIArr do
            if self.m_pUsedTipsUIArr[i] == sender then
                table.remove(self.m_pUsedTipsUIArr,i)
                break
            end
        end
        table.insert(self.m_pTipsUIBuff,pSender)
        pSender:retain()
        pSender:removeFromParent()
    end
    pSender:stopAllActions()
    --CCPoint tp = ObjectHelper::calPosToUIByOffset(ccp(480,pSender->getPositionY() + pSender->getContentSize().height));
    local move = cc.MoveBy:create(0.3,cc.p(0,pSender:getContentSize().height))
    local moveSine = cc.EaseSineIn:create(move)
    local callBack = cc.CallFunc:create(effectEnd)
    pSender:runAction(cc.Sequence:create(moveSine,callBack))

    local label = pSender:getChildByTag(1)
    pSender:runAction(cc.FadeTo:create(0.3,0))
    label:runAction(cc.FadeTo:create(0.3,0))

    for i = 1, #self.m_VecCenterTipNodes do
        if self.m_VecCenterTipNodes[i] == pSender then
            table.remove(self.m_VecCenterTipNodes,i)
            break
        end
    end
end

function ScrollTipsUI:CreateTipsNode(msg)
    local bgImage = "res/UI/ui_common/ui_common_tipbg.png"
    if ScrollTipsUI.BgSize == nil then
        local spframe = AppDef.spriteFrameCache:spriteFrameByName(bgImage)
        ScrollTipsUI.BgSize = spframe:getRect()
        ScrollTipsUI.BgCapInsets = cc.rect(6, 4, ScrollTipsUI.BgSize.width-12, ScrollTipsUI.BgSize.height-8)
    end
    
    local bkgSpr = cc.Scale9Sprite:createWithSpriteFrameName(bgImage,ScrollTipsUI.BgCapInsets)
    if ScrollTipsUI.BgHeight == nil then
        ScrollTipsUI.BgHeight = bkgSpr:getContentSize().height
    end
    -- bkgSpr:setPosition(cc.p(AppDef.frameSize.width/2, 350 - ScrollTipsUI.BgHeight))
    -- bkgSpr:setOpacity(0)
    self.m_pUILayer:addChild(bkgSpr,200)

    local ttf = CCAysLabel:createWithFixedWidth(AppDef.frameSize.width * 0.6, AppDef.FontSize.Normal,AppDef.UIColor.YELLOW)
    
    bkgSpr:addChild(ttf,1,1)
    -- local msgSize = ttf:getSize()
    -- bkgSpr:setPreferredSize(cc.size(msgSize.width + 60, msgSize.height + 12))
    -- ttf:setPosition(cc.p(30, msgSize.height + 8))
    if msg then
        self:InitTipNode(msg, bkgSpr, ttf)
    end
    return bkgSpr
end

function ScrollTipsUI:InitTipNode(msg, bkgSpr, ttf)
    if ttf == nil then
        ttf = bkgSpr:getChildByTag(1)
    end
    bkgSpr:setPosition(cc.p(AppDef.frameSize.width / 2, 350 - ScrollTipsUI.BgHeight))
    bkgSpr:setOpacity(0)
    ttf:setString(msg)
    local msgSize = ttf:getSize()
    bkgSpr:setPreferredSize(cc.size(msgSize.width + 60, msgSize.height + 12))
    ttf:setPosition(cc.p(30, msgSize.height + 8))
end

function ScrollTipsUI:GetTipNodeInBuff()
    if #self.m_pTipsUIBuff > 0 then
        local node = self.m_pTipsUIBuff[1]
        table.remove(self.m_pTipsUIBuff, 1)
        self.m_pUILayer:addChild(node,200)
        node:release()
        table.insert(self.m_pUsedTipsUIArr, node)
        return node
    end
    local node = self:CreateTipsNode()
    table.insert(self.m_pUsedTipsUIArr, node)
    return node
end

function ScrollTipsUI:GetTipsNode(msg)

    local curShowNum = #self.m_pUsedTipsUIArr
    if curShowNum >= ScrollTipsUI.MaxTipsNodes then
        --取最早显示的
        local node = self.m_pUsedTipsUIArr[1]
        table.remove(self.m_pUsedTipsUIArr,1)
        table.insert(self.m_pUsedTipsUIArr, node)
        node:stopAllActions()
        self:InitTipNode(msg, node)
        return node
    end
    local node = self:GetTipNodeInBuff(msg)
    self:InitTipNode(msg, node)
    return node
end

return ScrollTipsUI