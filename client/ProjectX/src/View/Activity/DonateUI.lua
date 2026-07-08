local DonateUI = LUIBase:New()
DonateUI.__index = DonateUI

function DonateUI:New()
    local o = LUIBase:New()
    setmetatable(o,DonateUI)  
    o:Init()
    return o
end

--[[
注册UI消息
]]
function DonateUI:RegistMsgs()
    self.msgIds = 
    {
        LUIActivityEvent.RefreshDonate,
    }
    self:RegistSelf(self,self.msgIds)
end

function DonateUI:ProcessEvent(msg)
    if msg.msgId == LUIActivityEvent.RefreshDonate then
        self:ShowDonateInfo()
--转到最高等级,方便操作
        local detQuality = self:getBestDesQuality()
        if detQuality > 1 then
            self:rotateAction(detQuality)
        end
    end
end

function DonateUI:Init()
    AppDef.spriteFrameCache:addSpriteFrames("csd/Plist/lingqijuanxian.plist","csd/Plist/lingqijuanxian.png")
    self:RegistMsgs()
    self.m_pUILayer = cc.CSLoader:createNode("csd/DonateLayer.csb")
    local frameSize = AppDef.frameSize
    self.m_pUILayer:setContentSize(frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:InitData()
    self:AddTouchEvt()
    LuaNetSendMsg:QueryLingQiButton(6) -- 灵气捐献按钮开关
end

function DonateUI:onExit()
    AppDef.spriteFrameCache:removeSpriteFramesFromFile("csd/Plist/lingqijuanxian.plist")
    self:Destory()
end

function DonateUI:InitData()
    local panel = self.m_pUILayer:getChildByName("Panel"):getChildByName("Donate")
    local imgBg = panel:getChildByName("LoadingBg")

    -- 进度
    self.m_percent = imgBg:getChildByName("LoadingBar")
    -- 总次数
    self.m_numCnt = imgBg:getChildByName("NumBg"):getChildByName("Value")
    -- 图片
    self.m_imgs = {}
    self.m_rotateIcon = {}
    self.m_NodePos = {{},{}}
    self.m_maxQuality = 5
    for i=1,self.m_maxQuality do
        self.m_imgs[i] = imgBg:getChildByName("Image_"..i)
        self.m_rotateIcon[i] = imgBg:getChildByName("Icon_"..i)
        self.m_rotateIcon[i]:setTag(i)
        self.m_rotateIcon[i]:loadTexture(AppDef.GUIRes["Lingqi_Ball_"..i], ccui.TextureResType.plistType)
        self.m_NodePos[1][i], self.m_NodePos[2][i] = self.m_rotateIcon[i]:getPosition()
        self.m_rotateIcon[i].curIdx = i
    end
    -- 特效节点
    self.m_pAniNode = self.m_imgs[1]:getChildByName("IconBg"):getChildByName("Node")
    self.m_pAniImod = ImodAnim:create()
    local size = self.m_pAniNode:getContentSize()
    self.m_pAniImod:setPosition(cc.p(size.width/2, size.height/2))
    self.m_pAniNode:addChild(self.m_pAniImod,5,666)

    -- 剩余捐赠次数
    self.m_times = panel:getChildByName("Times"):getChildByName("TimesBg"):getChildByName("Value")
    -- 捐赠按钮
    self.m_pDonateBtn = panel:getChildByName("Button")
    self.m_pCurQuality = 1
    self.m_pDstQuality = 0
    self.m_isRotate = false
    self.m_svrQuality = self.m_maxQuality - self.m_pCurQuality + 1
end

function DonateUI:AddTouchEvt()
    -- 捐赠
    local function DonateCallback(pSender, inputType)
        local Linqi = LRoleDataMgr.MyHeroInfo.m_pLingqi
        local item = LDataConstMgr:getCItemByID(Linqi.ids[self.m_svrQuality])
        if item ~= nil then
            local num = LRoleDataMgr.Equip:CountItemNumById(Linqi.ids[self.m_svrQuality])
            if num == 0 then
                self:ShowMsgBox()
                return
            end
        end
        self:PlayDonateAni()
        LuaNetSendMsg:QueryAnimaInfo(7, self.m_svrQuality)
    end
    self.m_pDonateBtn:addClickEventListener(DonateCallback)
	self:MarkIntaractCObj(self.m_pDonateBtn)
    -- 转
    local function ChangeSelectCallback(pSender, inputType)
        self.m_pDstQuality = pSender:getTag()
        self:rotateAction(self.m_pDstQuality)
    end
    for i=1,5 do
        self.m_rotateIcon[i]:setTouchEnabled(true)
        self.m_rotateIcon[i]:addClickEventListener(ChangeSelectCallback)
		self:MarkIntaractCObj(self.m_rotateIcon[i])
    end
end

--[[
切换捐赠品质
]]
function DonateUI:ChangeDonateQuality(dstQuality)
    function RotateCallBack()
        self:ChangeDonateQuality()
    end

    -- 动画速度
    self.m_delayTime = 0.2
    -- 是否要继续移动
    if self.m_pCurQuality ~= self.m_pDstQuality then
        local action = cc.Sequence:create(cc.DelayTime:create(self.m_delayTime + 0.02), cc.CallFunc:create(RotateCallBack))
        self.m_pUILayer:getChildByName("Panel"):getChildByName("Donate"):runAction(action)
    else
        self.m_isRotate = false
        self:ShowDonateInfo()
        self.m_pAniNode:setVisible(true)
        return
    end

    -- 控制移动
    for i=1,self.m_maxQuality do
        local nextIdx = self.m_rotateIcon[i].curIdx + 1
        if nextIdx > 5 then nextIdx = 1 end
        local x, y = self.m_NodePos[1][nextIdx], self.m_NodePos[2][nextIdx]
        local lMoveTo = cc.MoveTo:create(self.m_delayTime, cc.p(x, y))
        self.m_rotateIcon[i]:runAction(lMoveTo)
        self.m_rotateIcon[i].curIdx = nextIdx
    end
    self.m_pCurQuality = self.m_pCurQuality - 1
    if self.m_pCurQuality == 0 then self.m_pCurQuality = self.m_maxQuality end
    self.m_pAniNode:setVisible(false)
end

--[[
捐赠动画
]]
function DonateUI:PlayDonateAni()
    local x, y = self.m_percent:getPosition()
    local donateAni = self.m_rotateIcon[self.m_pCurQuality]:clone()
    local panel = self.m_pUILayer:getChildByName("Panel"):getChildByName("Donate")
    local imgBg = panel:getChildByName("LoadingBg")
    imgBg:addChild(donateAni)

    local time = 0.5
    local move = cc.MoveTo:create(time, cc.p(x, y))
    local fade = cc.FadeTo:create(time,50)
    local scale = cc.ScaleTo:create(time,1.5)
    local spawnAction = cc.Spawn:create(move,fade,scale)

    local function RunAwayCallBack(node, value)
        value.node:removeFromParent()
        value.node = nil
    end
    local callbackAction = cc.CallFunc:create(RunAwayCallBack, {node=donateAni})
    local seqAction = cc.Sequence:create(spawnAction,callbackAction)
    donateAni:runAction(seqAction)
end

-- 显示灵气信息
function DonateUI:ShowDonateInfo()
    local Linqi = LRoleDataMgr.MyHeroInfo.m_pLingqi
    if #Linqi.exps == 0 then return end
    self.m_svrQuality = self.m_maxQuality - self.m_pCurQuality + 1
    for i=1,self.m_maxQuality do
        local idx = self.m_rotateIcon[i].curIdx
        local qualityIdx = self.m_maxQuality - i + 1
        local img = self.m_imgs[idx]

        local expBg = img:getChildByName("EXPText"):setVisible(true)
        local itemBg = img:getChildByName("ItemText"):setVisible(true)
        local expText = expBg:getChildByName("Value")
        local itemText = itemBg:getChildByName("Value")
        expBg:setVisible(true)
        itemBg:setVisible(true)

        expText:setString(tostring(Linqi.exps[qualityIdx]))
        local item = LDataConstMgr:getCItemByID(Linqi.ids[qualityIdx])
        if item ~= nil then
            local num = LRoleDataMgr.Equip:CountItemNumById(Linqi.ids[qualityIdx])
            itemText:setString(string.format("%s*%d",item.m_name,num))
        else
            itemText:setString(GUITips.Res_Donate_None)
        end
    end
    self.m_times:setString(tostring(math.max(Linqi.times, 0)))
    self.m_numCnt:setString(tostring(Linqi.nowCnt))
    self.m_percent:setPercent(Linqi.nowCnt * 100 / AppDef.DonateCnt.MaxCnt)

    local png = string.format(AppDef.GUIRes.Linqi_Fire_Format, self.m_svrQuality-1, AppDef.GUIRes.Res_Suffix_Png)
    local ani = string.format(AppDef.GUIRes.Linqi_Fire_Format, self.m_svrQuality-1, AppDef.GUIRes.Res_Suffix_Ani)
    self.m_pAniImod:initAnimWithName(png, ani)
    self.m_pAniImod:PlayNewAction(0, true)
end

function DonateUI:ShowMsgBox()
    --杀敌取宝
    local function Shadiqubao()
        LGameMsg.m_autoPathMsg:ChangeToStart(11,-1,-1,0,bit.lshift(2,16),true,true, nil)
        LUIManager:SendMsg(LGameMsg.m_autoPathMsg)
		LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, true)
		LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.DonateManiUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end

    --封神战场
    local function Zhanchang()
        LuaNetSendMsg:QueryFlyFaryField(1)
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.DonateManiUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end

    --商城
    local function Shangcheng()
        Utils:OpenFunction(AppDef.EModuleID.EMID_SCCHANGYONG)
    end

    local function  OnOk()
    end

    local msgData = 
    {
        okCallback = nil,
        approachList = 
        {
            {
                iconPath = AppDef.GUIRes.Activity_Name24,
                callback = Shadiqubao
            },
            {
                iconPath = AppDef.GUIRes.Function_Name_Shangcheng,
                callback = Shangcheng
            },
        },

        tips = GUITips.Res_Donate_Not_Enough,
        okBtnName = GUITips.RSI_KNOW,
        okCallback = OnOk,
    }
    LGameMsg.m_baseMsgWithOne:Change(LUIMsgBoxEvent.ShowMsgBox, msgData)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function DonateUI:rotateAction( detQuality )
    -- body
    if not self.m_isRotate then
        for i=1,self.m_maxQuality do
            self.m_imgs[i]:getChildByName("EXPText"):setVisible(false)
            self.m_imgs[i]:getChildByName("ItemText"):setVisible(false)
        end
        self.m_isRotate = true
        self.m_pDstQuality = detQuality
        self:ChangeDonateQuality(detQuality)
    end
end

function DonateUI:getBestDesQuality()
    -- body
    local Linqi = LRoleDataMgr.MyHeroInfo.m_pLingqi
--    dump(Linqi, "getBestDesQuality")
    if #Linqi.exps == 0 then return 1 end
    self.m_svrQuality = self.m_maxQuality - self.m_pCurQuality + 1
    for i=1, self.m_maxQuality do
        local qualityIdx = self.m_maxQuality - i + 1
        local item = LDataConstMgr:getCItemByID(Linqi.ids[i])
        if item ~= nil then
            local num = LRoleDataMgr.Equip:CountItemNumById(Linqi.ids[i])
            if num > 0 then
                return  qualityIdx
            end
        end
    end
    return 1
end

return DonateUI
