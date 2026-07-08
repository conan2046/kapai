--[[
lua里面的游戏逻辑控制
]]


local PetKaPaiMainUI = LUIBase:New()
PetKaPaiMainUI.__index = PetKaPaiMainUI
--local this = LTcpSocket
function PetKaPaiMainUI:New(openTab)
    local o = LUIBase:New()
    setmetatable(o,PetKaPaiMainUI)   
    o:Init(openTab)
    return o
end

local functionInArr = {
    AppDef.EModuleID.EMID_KAPAI_SJJINENG,
    AppDef.EModuleID.EMID_KAPAI_SJSHENGXING,
    AppDef.EModuleID.EMID_KAPAI_SJXIULIAN,
    AppDef.EModuleID.EMID_KAPAI_SJXIULIAN_REALY,
    AppDef.EModuleID.EMID_KAPAI_ZHUXIANFUBEN, --补位用的方便处理逻辑.信息是默认开启的
}

local TipsArr = {
    GUITips.UI_Shengjiang_Btn_LvUp,
    GUITips.UI_Shenjiang_TabName3,
    GUITips.UI_Shenjiang_TabName6,
    GUITips.UI_Shenjiang_TabName5,
    GUITips.UI_Shenjiang_TabName1,
}


function PetKaPaiMainUI:RegistMsgs()
    self.msgIds = 
    {
        LUIKaPaiPetEvent.ShowPetLeftInfo,
        LUIPetEvent.PetDataChanged,
        LUIRedDotEvent.UpdateRedDotState,
    }
    self:RegistSelf(self, self.msgIds)
end

function PetKaPaiMainUI:ProcessEvent(msg)
    if msg.msgId == LUIKaPaiPetEvent.ShowPetLeftInfo then
        local showPos = LRoleDataMgr.Pet:GetPetPos(msg.value.id)
        self._fightPos = showPos
        self:showPetInfo(msg.value)
    elseif msg.msgId == LUIPetEvent.PetDataChanged then
        --修炼刷新不走这里
        if self.m_curUIInd == 4 then
            return
        end
        if self._petData == nil or self._petData.id == msg.value then
            local petData = LRoleDataMgr.Pet:GetPetById(msg.value)
            self:showPetInfo(petData)
            self:UpdateData()
        end
    elseif msg.msgId == LUIRedDotEvent.UpdateRedDotState then
        self:updateHotDot(msg.value)
    end
end

function PetKaPaiMainUI:Init(openTab)

    self:CreateUINode("csd/shenjiangyangcheng/yingxiongjueseLayer.csb")
   self._bg = self.m_pUILayer
   self.m_pSubLayer = {}
   self.m_curUIInd = 0
   self._fightPos = 0
   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    
    self:RegistMsgs()

    -- self._bg = cc.CSLoader:createNode("csd/shenjiangyangcheng/yingxiongjueseLayer.csb")
    -- self._bg:setPosition(cc.p(0, 0))
    -- self.m_pUILayer:addChild(self._bg)

    self._Node_3 = self._bg:getChildByName("Node_3")

    local Button_l = self._Node_3:getChildByName("Button_l")
    self._Button_l = Button_l
    Button_l:getChildByName("Prompt"):setVisible(false)
    local function leftEvent( sender )
        -- body
        local showPos = PetkaPaiManager:getNextPetPos(self._fightPos, 2)
        -- print("PetKaPaiMainUI self._fightPos === 11111111 >", showPos, self._fightPos)
        if self._fightPos == showPos then
            return
        end

        --更新数据
        self._fightPos = showPos
        self:showPetInfo(LRoleDataMgr.Pet:GetPetByFightPos(showPos))
        self:UpdateData()
        self:updateHotDot()
    end
    Button_l:addClickEventListener(leftEvent)



    local Button_r = self._Node_3:getChildByName("Button_r")
    self._Button_r = Button_r
    Button_r:getChildByName("Prompt"):setVisible(false)
    local function rightEvent( sender )
        -- body
        local showPos = PetkaPaiManager:getNextPetPos(self._fightPos, 1)
        -- print("PetKaPaiMainUI self._fightPos === 222222222222222>", showPos, self._fightPos)
        if self._fightPos == showPos then
            return
        end
        self._fightPos = showPos
        
        self:showPetInfo(LRoleDataMgr.Pet:GetPetByFightPos(showPos))
        self:UpdateData()
        self:updateHotDot()
    end
    Button_r:addClickEventListener(rightEvent)

    self._StarList = self._Node_3:getChildByName("StarList")
    local duiwu = self._Node_3:getChildByName("duiwu")
    duiwu:addClickEventListener(function( sender )
        -- body
        -- if #LRoleDataMgr.Pet.petlist == 0 then
        --     Utils:ShowScrollTips(GUITips.UI_No_Shenjiang_Tips)
        --     return
        -- end
        -- Utils:OpenFunction(AppDef.EModuleID.EMID_SJBUZHEN)
        self:closeUI()
    end)

    local btn_gaiming = self._Node_3:getChildByName("btn_gaiming")
    btn_gaiming:addClickEventListener(function ( sender )
        -- body
    end)

    self._petNode = self._Node_3:getChildByName("Node")

    self._zhanli = self._Node_3:getChildByName("bg_zhanli"):getChildByName('Value')
    self._Tips_2 = self._Node_3:getChildByName("Tips_2")
    self._bg_Quality = self._Node_3:getChildByName("bg_Quality")

    ---------------------------------------------------------------------------------
    -- if  LRoleDataMgr.m_bIsCrossServer==true then 
    --    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.UI_Title_KuafuWorldMap)
    --     self:SendMsg(LGameMsg.m_baseMsgWithOne)
    -- else
    --   LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.UI_Shengjiang_Btn_yangcheng)
    --   self:SendMsg(LGameMsg.m_baseMsgWithOne)
    -- end

   
    local function closeCallback()
        self:closeUI()
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local function tabBtnClicked(ind)
        return self:TabClicked(ind)
    end

    local tabValues = 
    {
        {GUITips.UI_Shengjiang_Btn_LvUp,GUITips.UI_Shenjiang_TabName3, GUITips.UI_Shenjiang_TabName6, GUITips.UI_Shenjiang_TabName5, GUITips.UI_Shenjiang_TabName1},
        tabBtnClicked
    }
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.AddTabBtn, tabValues)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local ind = 1
    --如果当前没有解锁,则按顺序找到解锁的
    if openTab ~= nil and openTab > 0 then
        local funcId = functionInArr[openTab]
        if Utils:CheckModelNotOpened(funcId, true) then
            for i=1, #functionInArr do
                if i ~= openTab then
                    if not Utils:CheckModelNotOpened(functionInArr[i], true) then
                        openTab = i
                        break
                    end
                end
            end
        end
    end

    ind = openTab

    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, ind)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    self:TabClicked(ind)
    self:RegisterGuide()
end

function PetKaPaiMainUI:UpdateData( ... )
    -- body
    --更新数据
    -- if self.m_pSubLayer[self.m_curUIInd].UpdateData ~= nil and  self._petData ~= nil  then
        -- print("DelayLoadSubUI ==>", self._fightPos)
        -- local petData = LRoleDataMgr.Pet:GetPetByFightPos(self._fightPos)
        -- self.m_pSubLayer[self.m_curUIInd]:UpdateData(self._petData)
    -- end
    --子页全部刷新数据
    for i=1, 5 do
        if self.m_pSubLayer[i] and self.m_pSubLayer[i].UpdateData ~= nil and  self._petData ~= nil  then
            self.m_pSubLayer[i]:UpdateData(self._petData)
        end
    end
    
end


function PetKaPaiMainUI:showPetModel( pid )
    -- body
    self._pPetModel = Utils:CreateAnimModel(AppDef.AwrdItem.AWRD_ITEM_PET, pid, self._pPetModel, true)
    if self._pPetModel == nil then
        return
    end
    if self._petNode:getChildByTag(101) == nil then
        self._petNode:addChild(self._pPetModel)
        self._pPetModel:setTag(101)
    end
    self._pPetModel:PlayStand(1)
end

function PetKaPaiMainUI:showPetInfo( petData )
    -- body
    if #LRoleDataMgr.Pet.petlist < 1 then
        return
    end

    self._petData = petData
    
    self._Button_r:setVisible(self._fightPos > 0 and self._fightPos < 6)
    self._Button_l:setVisible(self._fightPos > 0 and self._fightPos < 6)

    -- local petData = LRoleDataMgr.Pet:GetPetByFightPos(fightPos)
    print("fightPos ==>", self._fightPos)
    self._Tips_2:setString(string.format(GUITips.RSI_YINGXIONG_TIPS1, petData.level, petData.name, petData.breakLevel))

    PetkaPaiManager:ShowStarsVertical(self._StarList, petData.star)
    
    self._zhanli:setString(Utils:getPowerStr(petData.zhandouli))
    self:showPetModel(petData.id)

    local curRes = AppDef.Pet.QualityScoreRes[petData.baseData.quality]
    self._bg_Quality:getChildByName("Value"):loadTexture(curRes, ccui.TextureResType.plistType)
end

function PetKaPaiMainUI:TabClicked(ind)
    if ind == 2 then
        Utils:CheckGuide(GuideDef.StepId.Guide_FuBen3_7, true)
    elseif ind == 3 then
        Utils:CheckGuide(GuideDef.StepId.Guide_FuBen2_7, true)
    end
    if self.m_curUIInd == ind then
        return false
    end

    if ind >= 1 and ind <= 4 then
        if Utils:CheckModelNotOpened(functionInArr[ind]) then
            return false
        end
    end

    if self.m_curUIInd ~= 0 then
     self:HideCurUI()
    end
    self.m_curUIInd = ind
    
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, TipsArr[ind])
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    self:ShowCurUI()
end

function PetKaPaiMainUI:HideCurUI()
    if self.m_pSubLayer[self.m_curUIInd] == nil then
        return
    end
    self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(false)
end

function PetKaPaiMainUI:ShowCurUI()
    
     if self.m_pSubLayer[self.m_curUIInd] == nil then
        self:DelayLoadSubUI(self.m_curUIInd)
      
    else
        self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(true)
    end
end

function PetKaPaiMainUI:DelayLoadSubUI(tabInd)
    local uinames = {"View.KaPaiPet.PetKaPaiLvUpUI", "View.KaPaiPet.PetKaPaiStarUpUI", "View.KaPaiPet.HeroBreakUpUI", "View.KaPaiPet.PetKaPaiXiuLianUI", "View.KaPaiPet.PetKaipaiInfoSubUI"}
    local ind = tabInd
    local delay = cc.DelayTime:create(0.1)
    local function loadSubUI()
        if self.m_curUIInd ~= ind then
            return
        end
        self.m_pSubLayer[ind] = require(uinames[ind]):New()
        self.m_pUILayer:addChild(self.m_pSubLayer[ind].m_pUILayer)
        self:UpdateData()
        self:updateHotDot()
    end
    local func = cc.CallFunc:create(loadSubUI)
    local sequence = cc.Sequence:create(delay, func)
    self.m_pUILayer:runAction(sequence)
end

function PetKaPaiMainUI:closeUI( ... )
    -- body
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "KaPaiPet.PetKaPaiMainUI")
    self:SendMsg(LGameMsg.m_initUIMsg)
end

function PetKaPaiMainUI:updateHotDot(data)
    -- body
    if data then
        --刷新红点
        if self.m_curUIInd == 1 then
            local isCanLvUp = PetkaPaiManager:getPetCanLevelUp(self._petData)
            LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RedDotState, {1, isCanLvUp})
            self:SendMsg(LGameMsg.m_baseMsgWithOne)

            --升级会影响到突破
            local isCanStarUp = PetkaPaiManager:isPetCanStarUp( self._petData )
            LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RedDotState, {2, isCanStarUp})
            self:SendMsg(LGameMsg.m_baseMsgWithOne)

        elseif self.m_curUIInd == 2 then
            local isCanStarUp = PetkaPaiManager:isPetCanStarUp( self._petData )
            LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RedDotState, {2, isCanStarUp})
            self:SendMsg(LGameMsg.m_baseMsgWithOne)
        elseif self.m_curUIInd == 3 then
            local isPetCanBreakUp =  PetkaPaiManager:isPetCanBreakUp(self._petData)
            LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RedDotState, {3, isPetCanBreakUp})
            self:SendMsg(LGameMsg.m_baseMsgWithOne)
        elseif self.m_curUIInd == 4 then
            local isPetCanBreakUp =  PetkaPaiManager:isPetCanTianMingJH(self._petData)
            LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RedDotState, {4, isPetCanBreakUp})
            self:SendMsg(LGameMsg.m_baseMsgWithOne)
        end
    else

        local isCanLvUp = PetkaPaiManager:getPetCanLevelUp(self._petData)
        LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RedDotState, {1, isCanLvUp})
        self:SendMsg(LGameMsg.m_baseMsgWithOne)

        local isCanStarUp = PetkaPaiManager:isPetCanStarUp( self._petData )
        LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RedDotState, {2, isCanStarUp})
        self:SendMsg(LGameMsg.m_baseMsgWithOne)

        local isPetCanBreakUp =  PetkaPaiManager:isPetCanBreakUp(self._petData)
        LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RedDotState, {3, isPetCanBreakUp})
        self:SendMsg(LGameMsg.m_baseMsgWithOne)

        local isPetCanTianMingJH =  PetkaPaiManager:isPetCanTianMingJH(self._petData)
        LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RedDotState, {4, isPetCanTianMingJH})
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end
end

function PetKaPaiMainUI:onExit()
    Utils:SendMsg(LUIFClassBgEvent.UnRegisterStep,GuideDef.StepId.Guide_FuBen2_9)
    Utils:SendMsg(LUIFClassBgEvent.UnRegisterStep,GuideDef.StepId.Guide_FuBen3_9)
    Utils:SendMsg(LUIFClassBgEvent.UnRegisterStep,GuideDef.StepId.Guide_Pet1_5)
    Utils:SendMsg(LUIFClassBgEvent.UnRegisterStep,GuideDef.StepId.Guide_FuBen2_6)
    Utils:SendMsg(LUIFClassBgEvent.UnRegisterStep,GuideDef.StepId.Guide_FuBen3_6)
    self:Destory()
    self.m_pUILayer = nil
    local uinames = {"View.KaPaiPet.PetKaPaiLvUpUI","View.KaPaiPet.PetKaPaiStarUpUI", "View.KaPaiPet.HeroBreakUpUI", "View.KaPaiPet.PetKaipaiInfoSubUI"}
    for i = 1,2 do
        --package.loaded[uinames[i]] = nil
        self.m_pSubLayer[i] = nil
    end
    self.m_pSubLayer = nil
    self.m_curUIInd = nil
    local guideIds = {GuideDef.StepId.Guide_FuBen2_10,GuideDef.StepId.Guide_FuBen3_10,GuideDef.StepId.Guide_Pet1_6}
    for i=1,#guideIds do
        Utils:CheckGuide(guideIds[i],true)
    end

    --用于更新小红点，从神将背包进去养成，关闭时更新小红点
    Utils:SendMsg(LUILogicEvent.ClosePetYangChengUI)
	LGameMsg.m_baseMsgWithOne:Change(LUIKaPaiPetEvent.BGVisible, false)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function PetKaPaiMainUI:RegisterGuide()
    Utils:SendMsg(LUIFClassBgEvent.RegisterCloseGuide,GuideDef.StepId.Guide_FuBen2_9)
    Utils:SendMsg(LUIFClassBgEvent.RegisterCloseGuide,GuideDef.StepId.Guide_FuBen3_9)
    Utils:SendMsg(LUIFClassBgEvent.RegisterCloseGuide,GuideDef.StepId.Guide_Pet1_5)
    local msg = {}
    msg.stepId = GuideDef.StepId.Guide_FuBen2_6
    msg.tabIndex = 3
    Utils:SendMsg(LUIFClassBgEvent.RegisterTabGuide,msg)
    local msg1 = {}
    msg1.stepId = GuideDef.StepId.Guide_FuBen3_6
    msg1.tabIndex = 2
    Utils:SendMsg(LUIFClassBgEvent.RegisterTabGuide,msg1)
end

return PetKaPaiMainUI