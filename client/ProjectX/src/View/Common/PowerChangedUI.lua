--[[
战斗力变化效果
]]

local PowerChangedUI = LUIBase:New()
PowerChangedUI.__index = PowerChangedUI
--战斗中是否隐藏
PowerChangedUI.IsHideInBattle = true

PowerChangedUI.BgSize = nil
PowerChangedUI.BgCapInsets = nil
PowerChangedUI.BgHeight = nil
--local this = LTcpSocket
function PowerChangedUI:New(datas)
    local o = {}
    setmetatable(o,PowerChangedUI)   
    curNum = 100
    changeNum = 100
    o:Init(datas)
    return o
end

function PowerChangedUI:Init(datas)
    self.m_pUILayer = cc.CSLoader:createNode("csd/zhanlitishengLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    self.m_timeline = cc.CSLoader:createTimeline("csd/zhanlitishengLayer.csb")
    self.m_timeline:pause()
    self.m_pUILayer:runAction(self.m_timeline)

    local bg = self.m_pUILayer:getChildByName("zhanlitisheng"):getChildByName("Power_bg")
    bg:setVisible(true)
    self.m_size = bg:getContentSize()
    self.m_pPowerLabel = bg:getChildByName("AtlasLabel_1")
    self.m_pPowerImage = self.m_pPowerLabel:getChildByName("UPImage")
    self.m_pPowerImagePos = cc.p(self.m_pPowerImage:getPosition())
    self.m_bIsShowEffect = false
    self.m_iCurNum = 0
    self.m_iChangeNum = 0
    self.m_iBeginNum = 0
    self.m_iStep = 0
    self:UpdateUserData(datas)
    --self:SetTexts(curNum, changeNum)
end

function PowerChangedUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_bIsShowEffect = nil
    self.m_pPowerLabel = nil
    self.m_pUILayer = nil
    self.m_iStep = nil
    self.m_iCurNum = nil
    self.m_iChangeNum = nil
    self.m_timeline = nil
    self.m_size = nil
    self.m_pPowerImage = nil
    self.m_pPowerImagePos = nil
    self.m_iBeginNum = nil
end

function PowerChangedUI:UpdateUserData(datas)
    if datas == nil then
        self.m_pUILayer:setVisible(false)
        return
    end
    self:SetNum(datas[1],datas[2])
end

function PowerChangedUI:PlayCocosAnim(key)
    if self.m_timeline == nil or key == nil then
        return
    end
    self.m_timeline:play(key, false)
end

function PowerChangedUI:SetNum(curNum, changeNum)
    self.m_pUILayer:setVisible(true)
    self.m_pPowerLabel:stopAllActions()
    self.m_pUILayer:setGlobalZOrder(1)
    
    self.m_iCurNum = curNum - changeNum

    self.m_iChangeNum = changeNum
    local tmp = "/"
    self.m_iBeginNum = 0
    if self.m_iChangeNum < 0 then
        tmp = "."
    end
    if self.m_pPowerImage then
        self.m_pPowerImage:setVisible(self.m_iChangeNum > 0)
        if self.m_pPowerImage:isVisible() then
            self.m_pPowerImage:stopAllActions()
            self.m_pPowerImage:setOpacity(255)
            local str = tmp .. self.m_iChangeNum
            local count = #str
            if count > 1 then
                self.m_pPowerImage:setPositionY(self.m_pPowerImagePos.y)
                self.m_pPowerImage:setPositionX(48 * count + self.m_pPowerImage:getContentSize().width/2 + 10)
            end
        end
    end

    self.m_iStep = math.floor(self.m_iChangeNum / 10)
    local taction = {}
    self.m_pPowerLabel:setString(tmp .. self.m_iBeginNum)
    --延迟

    local repTimes = math.abs(changeNum)/math.abs(self.m_iStep)
    local delay = cc.DelayTime:create(0.05)
    if self.m_iChangeNum > 0 then
        table.insert(taction, cc.CallFunc:create(function()
            self:PlayCocosAnim("up")
        end))
        table.insert(taction, cc.DelayTime:create(55/60))
    else
        table.insert(taction, cc.CallFunc:create(function()
            self:PlayCocosAnim("down")
        end))
        table.insert(taction, cc.DelayTime:create(23/60))
    end
    local function chagenum()
        if self.m_iChangeNum > 0 then
            if self.m_iBeginNum <  self.m_iChangeNum then
                self.m_iBeginNum= self.m_iBeginNum + self.m_iStep
                self.m_pPowerLabel:setString(tmp .. self.m_iBeginNum)
            elseif self.m_iBeginNum >=  self.m_iChangeNum then
                self.m_pPowerLabel:setString(tmp .. self.m_iChangeNum)
            end
        else
            if self.m_iBeginNum >=  self.m_iChangeNum then
                self.m_iBeginNum= self.m_iBeginNum + self.m_iStep
                self.m_pPowerLabel:setString(tmp .. self.m_iBeginNum)
            elseif self.m_iBeginNum >=  self.m_iChangeNum then
                self.m_pPowerLabel:setString(tmp .. self.m_iChangeNum)
            end
        end
    end
    local seq = cc.Sequence:create(delay,cc.CallFunc:create(chagenum))
    local rep = cc.Repeat:create(seq,repTimes)
    --设置真值
    local function setnum()
        self.m_iBeginNum =  self.m_iChangeNum
        self.m_pPowerLabel:setString(tmp .. self.m_iChangeNum)
    end

    local call = cc.CallFunc:create(setnum)
    local seq2 = cc.Sequence:create(rep,call)
    table.insert(taction,seq2)
    table.insert(taction, cc.DelayTime:create(1))
    if self.m_iChangeNum > 0 then
        table.insert(taction, cc.CallFunc:create(function()
            self:PlayCocosAnim("end_1")
        end))
        table.insert(taction, cc.DelayTime:create(40/60))
    else
        table.insert(taction, cc.CallFunc:create(function()
            self:PlayCocosAnim("end_2")
        end))
        table.insert(taction, cc.DelayTime:create(40/60))
    end
    local function effectPlayEnd()
        self.m_pUILayer:setVisible(false)
        -- LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Common.PowerChangedUI")
        -- self:SendMsg(LGameMsg.m_initUIMsg)
    end
    local call2 = cc.CallFunc:create(effectPlayEnd)
    table.insert(taction,call2)
    local seqaction = cc.Sequence:create(taction)
    self.m_pPowerLabel:runAction(seqaction)
end

return PowerChangedUI