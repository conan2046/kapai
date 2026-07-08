local GuessFistUI = LUIBase:New()
GuessFistUI.__index = GuessFistUI

function GuessFistUI:New()
    local o = LUIBase:New()
    setmetatable(o,GuessFistUI)  
    o:Init()
    return o
end

--[[
注册UI消息
]]
function GuessFistUI:RegistMsgs()
    self.msgIds = 
    {
        LUIActivityEvent.GuessFistResult,
    }
    self:RegistSelf(self,self.msgIds)
end

function GuessFistUI:ProcessEvent(msg)
    if msg.msgId == LUIActivityEvent.GuessFistResult then
        self.m_pResultIcon:setVisible(true)
        local resultStr
        local npcType

        if self.m_ftype == 4 then   -- 必胜出石头
            self.m_ftype = 3
        end

        if msg.value == 0 then -- 失败
            resultStr = AppDef.GUIRes.Guess_Fist_Lost
            npcType = self.m_ftype + 1
        elseif msg.value == 2 then -- 平手
            resultStr = AppDef.GUIRes.Guess_Fist_Draw
            npcType = self.m_ftype
        elseif msg.value == 1 then -- 胜利
            resultStr = AppDef.GUIRes.Guess_Fist_Win
            npcType = self.m_ftype - 1
        end
        if npcType == 0 then
            npcType = 1
        elseif npcType == 4 then
            npcType = 3
        else
            npcType = 1
        end

        local npcStr = AppDef.GUIRes["Guess_Fist_"..npcType]
        local selfStr = AppDef.GUIRes["Guess_Fist_"..self.m_ftype]
        self.m_pResultIcon:loadTexture(resultStr, ccui.TextureResType.plistType)
        self.m_pLeftAni:loadTexture(npcStr, ccui.TextureResType.plistType)
        self.m_pRightAni:loadTexture(selfStr, ccui.TextureResType.plistType)
        self.m_close = true

--闯关界面抽奖，1s种后自动关闭
        local function callback( ... )
            -- body
            local isInMonopoly = LRoleDataMgr.MonopolyData.isMonopolyState
            if isInMonopoly then
                --print("close guessUI ==============================================================================")
                LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.GuessFistMainUI")
                self:SendMsg(LGameMsg.m_initUIMsg)
            end
        end

        local delay = cc.DelayTime:create(1.5)
        local sequence = cc.Sequence:create(delay, cc.CallFunc:create(callback))
        self.m_pLeftAni:runAction(sequence)
        return sequence

    end
end

function GuessFistUI:Init()

    AppDef.spriteFrameCache:addSpriteFrames("csd/Plist/huodong_chuangguan03.plist","csd/Plist/huodong_chuangguan03.png")
    self:RegistMsgs()
    self.m_pUILayer = cc.CSLoader:createNode("csd/caiquanLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:InitData()
    self:AddTouchEvt()
    
    local isInMonopoly = LRoleDataMgr.MonopolyData.isMonopolyState
    if isInMonopoly then
        self:MonopolyGuessUI()
    else
        self:ShowChooseAward()
    end
end

function GuessFistUI:onExit()
    AppDef.spriteFrameCache:removeSpriteFramesFromFile("csd/Plist/huodong_chuangguan03.plist")
    self.m_panelUI = nil
    self.m_pNpcIcon = nil
    self.m_pHeroIcon = nil
    self.m_pResultIcon = nil
    self.m_pLeftAni = nil
    self.m_pRightAni = nil
    self.m_pChooseList = nil
    self.m_pQiannengBtn = nil
    self.m_pExpBtn = nil
    self.m_pGoldBtn = nil
    self.m_pGuessList = nil
    self.m_pClothBtn = nil
    self.m_pScissorBtn = nil
    self.m_pStoneBtn = nil
    self.m_pBishengBtn = nil
    self.m_atype = nil
    self.m_ftype = nil
    self.m_delayTime = nil
    self.m_tick = nil
    self.m_isUp = nil
    self.m_lx = nil
    self.m_rx = nil
    self.m_y = nil
    self.m_close = nil
    self:Destory()
end

function GuessFistUI:InitData()
    self.m_panelUI = self.m_pUILayer:getChildByName("caiquanUI")
    --NPC
    self.m_pNpcIcon = self.m_panelUI:getChildByName("Npc"):getChildByName("Icon")
    -- 玩家
    self.m_pHeroIcon = self.m_panelUI:getChildByName("User"):getChildByName("Icon")
    -- 结果
    self.m_pResultIcon = self.m_panelUI:getChildByName("Result")
    -- 左边动画
    self.m_pLeftAni = self.m_panelUI:getChildByName("Image_1")
    self.m_pLeftAni:setVisible(false)
    -- 右边动画
    self.m_pRightAni = self.m_panelUI:getChildByName("Image_2")
    self.m_pRightAni:setVisible(false)
    -- 奖励列表
    self.m_pChooseList = self.m_panelUI:getChildByName("choosebg")
    self.m_pQiannengBtn = self.m_pChooseList:getChildByName("btn_qianneng")
    self.m_pExpBtn = self.m_pChooseList:getChildByName("btn_exp")
    self.m_pGoldBtn = self.m_pChooseList:getChildByName("btn_gold")

    -- 出拳列表
    self.m_pGuessList = self.m_panelUI:getChildByName("caiquanbg")
    self.m_pClothBtn = self.m_pGuessList:getChildByName("btn_Cloth")
    self.m_pScissorBtn = self.m_pGuessList:getChildByName("btn_Scissor")
    self.m_pStoneBtn = self.m_pGuessList:getChildByName("btn_Stone")
    self.m_pBishengBtn = self.m_pGuessList:getChildByName("btn_bisheng")

    -- 猜拳参数
    self.m_atype = 0 --奖励类型
    self.m_ftype = 0 --选择
    self.m_delayTime = 0.1
    self.m_tick = 1 -- 当前次数
    self.m_isUp = false -- 是否是向上
    self.m_lx = self.m_pLeftAni:getPositionX()
    self.m_rx = self.m_pRightAni:getPositionX()
    self.m_y = self.m_pLeftAni:getPositionY()
    self.m_close = false

    self.m_pNpcIcon:loadTexture(AppDef.GUIRes.Guess_Fist_Npc,ccui.TextureResType.localType)
    local strHeadImage = AppDef:GetHeroPicFileName(LRoleDataMgr.MyHeroInfo.professional,
            AppDef.HeadType.HERO_IMAGE_HALF_BODY);
    self.m_pHeroIcon:loadTexture(strHeadImage, ccui.TextureResType.localType)
end

function GuessFistUI:AddTouchEvt()
    -- 潜能
    -- local function LayoutTouchCallback(pSender, inputType)
    --     if self.m_close then
    --         LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.GuessFistMainUI")
    --         self:SendMsg(LGameMsg.m_initUIMsg)
    --     end
    -- end
    -- self.m_panelUI:addClickEventListener(LayoutTouchCallback)

    -- 潜能
    local function QiannengCallback(sender)
        --print("QiannengCallback")
        self.m_atype = 1
        self:ShowGuess()
    end
    self.m_pQiannengBtn:addClickEventListener(QiannengCallback)
	self:MarkIntaractCObj(self.m_pQiannengBtn)
    -- 经验
    local function ExpCallback(sender)
        --print("ExpCallback")
        self.m_atype = 2
        self:ShowGuess()
    end
    self.m_pExpBtn:addClickEventListener(ExpCallback)
    self:MarkIntaractCObj(self.m_pExpBtn)
    -- 金钱
    local function GoldCallback(sender)
        --print("GoldCallback")
        self.m_atype = 3
        self:ShowGuess()
    end
    self.m_pGoldBtn:addClickEventListener(GoldCallback)
    self:MarkIntaractCObj(self.m_pGoldBtn)
    -- 布
    local function ClothCallback(sender)
        --print("ClothCallback")
        self:GuessFist(1)
    end
    self.m_pClothBtn:addClickEventListener(ClothCallback)
    self:MarkIntaractCObj(self.m_pClothBtn)
    -- 剪
    local function ScissorCallback(sender)
        --print("ScissorCallback")
        self:GuessFist(2)
    end
    self.m_pScissorBtn:addClickEventListener(ScissorCallback)
    self:MarkIntaractCObj(self.m_pScissorBtn)
    -- 石
    local function Stone(sender)
        --print("Stone")
        self:GuessFist(3)
    end
    self.m_pStoneBtn:addClickEventListener(Stone)
    self:MarkIntaractCObj(self.m_pStoneBtn)
    -- 必胜
    local function BishengCallback(sender)
        --print("BishengCallback")
        self:GuessFist(4)
    end
    self.m_pBishengBtn:addClickEventListener(BishengCallback)
	self:MarkIntaractCObj(self.m_pBishengBtn)
    self.m_pBishengBtn:setVisible(true)
    local isInMonopoly = LRoleDataMgr.MonopolyData.isMonopolyState
    if isInMonopoly then
        self.m_pBishengBtn:setVisible(false)
    end
end

--[[
奖励选择
]]
function GuessFistUI:ShowChooseAward()
    self.m_pGuessList:setVisible(false)
    self.m_pResultIcon:setVisible(false)
end

--[[
出拳选择
]]
function GuessFistUI:ShowGuess()
    self.m_pChooseList:setVisible(false)
    self.m_pGuessList:setVisible(true)
    self.m_pResultIcon:setVisible(false)
end

--[[
猜拳
]]
function GuessFistUI:GuessFist(type)
    if self.m_ftype ~= 0 then
        if self.m_close then
            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.GuessFistMainUI")
            self:SendMsg(LGameMsg.m_initUIMsg)
        end
        return
    end
    self.m_pLeftAni:setVisible(true)
    self.m_pRightAni:setVisible(true)
    self.m_pResultIcon:setVisible(false)
    self.m_ftype = type
    self.m_tick  = 1
    self:PlayAnimate()
end

--[[
多人闯关猜拳
]]
function GuessFistUI:MonopolyGuseeFist()
    -- body
    --print("GuessFistUI:MonopolyGuseeFist type", type)
    LuaNetSendMsg:QueryRushGateInfo(6, self.m_ftype)
end

--[[
猜拳动画
]]
function GuessFistUI:PlayAnimate()
    local function AnimateEnd()
        self:PlayAnimate()
    end

    --[[
    猜拳消息
    ]]
    local function SendGuessFist()
        local isInMonopoly = LRoleDataMgr.MonopolyData.isMonopolyState
        if isInMonopoly then
            self:MonopolyGuseeFist()
        else
            LuaNetSendMsg:QueryGuessFist(1, self.m_ftype, self.m_atype)
        end 
    end

    local offset
    if self.m_isUp then
        self.m_isUp = false
        offset = 10
    else
        self.m_isUp = true
        offset = -10
    end

    -- 左边动画
    local lMoveTo = cc.MoveTo:create(self.m_delayTime,cc.p(self.m_lx, self.m_y + offset))
    self.m_pLeftAni:runAction(lMoveTo)

    -- 右边动画
    local rMoveTo = cc.MoveTo:create(self.m_delayTime,cc.p(self.m_rx, self.m_y + offset))
    self.m_pRightAni:runAction(rMoveTo)

    if self.m_tick == 6 then  -- 只播放6次
        local action = cc.Sequence:create(cc.DelayTime:create(self.m_delayTime),cc.CallFunc:create(SendGuessFist))
        self.m_pUILayer:runAction(action)
        return
    end
    self.m_tick = self.m_tick + 1
    local action = cc.Sequence:create(cc.DelayTime:create(self.m_delayTime),cc.CallFunc:create(AnimateEnd))
    self.m_pUILayer:runAction(action)
end

function GuessFistUI:MonopolyGuessUI()
    -- body
    self.m_atype = 3
    self:ShowGuess()
end

return GuessFistUI
