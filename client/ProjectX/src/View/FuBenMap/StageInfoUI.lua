
local StageInfoUI = LUIBase:New()
StageInfoUI.__index = StageInfoUI
--local this = LTcpSocket
function StageInfoUI:New(data)
	local o = LUIBase:New()
	setmetatable(o,StageInfoUI)	
    o:Init(data)
	return o
end

--注册事件
-- -----------------------------------
function StageInfoUI:RegistMsgs()
    self.msgIds = 
    {
        LUIFuBenMapEvent.updateSaoDangEvent,
        LUIFuBenMapEvent.resetFightTimesSuc,
        LUIFuBenMapEvent.FormationUIClosed,
        LUIRoleDataChangeEvent.TiliChanged,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function StageInfoUI:ProcessEvent(msg)
    local msgId = msg:GetMsgId()
    if msgId == LUIFuBenMapEvent.updateSaoDangEvent then
        self:refreshUIAfterSaoDang(msg.value)
    elseif msgId == LUIFuBenMapEvent.resetFightTimesSuc then
        self:refreshUIAfterReset(msg.value)
    elseif msgId == LUIFuBenMapEvent.FormationUIClosed then
        self.m_pUILayer:setVisible(true)
    elseif msgId == LUIRoleDataChangeEvent.TiliChanged then
        self:TiliChanged();
    end
end

function StageInfoUI:Init(data)
    self:CreateUINode("csd/fuben/guanqiaxiangxiLayer.csb");

    self._data = data
    --print("StageInfoUI:Init ====>", self._data.stageId)
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    self:RegistMsgs();
    self:initControlUI();
    self:ShowInfo();
    self:ShowItemReward();
    self:RegisterGuide()
end

function StageInfoUI:ShowItemReward()
    local gold = 0
    local tongbao = 0;
    local tili = 0;
    local listView = self.m_pUILayer:findChildByName("Panel_1/Pane/Descbg/Image_bg/Panel_3/ListView_1");
    local smallAwardArr = {};
    --体力值*当前等级*2
    for i=1, #self._data.configData.show_reward do
        local data = self._data.configData.show_reward[i]
        if  AppDef:IsSpecialItem(data[1]) then
            if smallAwardArr[data[1]] == nil then
                smallAwardArr[data[1]] = 0
            end
            local value = data[3];
            if data[1] == AppDef.SpecialItemId.HeroExp and value == 0 then
                --体力值*当前等级*2
                value = self._data.configData.Hope*LRoleDataMgr.MyHeroInfo.level * 2;
            end
            smallAwardArr[data[1]] = smallAwardArr[data[1]] + value;
        else
            local node = self._baseItemNode:clone();
            node:setVisible(true)
            listView:pushBackCustomItem(node)
            if data[1] ==  AppDef.AwrdItem.AWRD_ITEM_PET  then
                local petIcon = self._basePetNode:clone()
                node:addChild(petIcon)
                Utils:ShowPet(data.petID, node, petIcon)
                local nameStr = LDataConstMgr:GetPetData(data.petID).name
                name:setString(nameStr)
            else
                local icon = node:getChildByName("Bg")
                -- dump(data, "ShowItemReward ===>")
                local name = node:findChildByName("Bg/TextBg/Name")
                if data[1] == AppDef.AwrdItem.AWRD_ITEM_EQUIP then
                    local item = Utils:GetItemCellValue(icon, 0, data[1], true, true, data[2], nil, true)
                    local nameStr = Utils:getEquipNameByID(data[2])
                    name:setString(nameStr)
                else
                    local item = Utils:GetItemCellValue(icon, 0, data[1], true, true, data[3], nil, true)
                    local nameStr = Utils:getItemNameByID(data[1])
                    name:setString(nameStr)
                end
                local choose = node:findChildByName("Bg/Choose")
                choose:setVisible(false)
            end
        end
    end
    local ind = 1
    for k,v in pairs(smallAwardArr) do
        if ind > 4 then
            return
        end
        local nodeIcon = self.m_pUILayer:findChildByName("Panel_1/Pane/Descbg/Image_bg/Panel_2/GoldIcon" .. ind .. "/Icon")

        local str = AppDef:GetMoneyIconById(k)
        nodeIcon:loadTexture(str, ccui.TextureResType.plistType)
        local numLabel = self.m_pUILayer:findChildByName("Panel_1/Pane/Descbg/Image_bg/Panel_2/GoldIcon" .. ind .. "/Num")
        numLabel:setString(v);
        ind = ind + 1;
    end
    for i = ind, 4 do
        self.m_pUILayer:findChildByName("Panel_1/Pane/Descbg/Image_bg/Panel_2/GoldIcon" .. i):setVisible(false)
    end
    -- local str = AppDef:GetMoneyIconById(data.pricePic)
    -- moneyIcon:loadTexture(str, ccui.TextureResType.plistType)

    -- local goldLabel = self.m_pUILayer:findChildByName("Panel_1/Descbg/Image_bg/Panel_2/GoldIcon2/Num")
    -- goldLabel:setString(gold);

    -- local tongbaoLabel = self.m_pUILayer:findChildByName("Panel_1/Descbg/Image_bg/Panel_2/GoldIcon1/Num")
    -- tongbaoLabel:setString(tongbao);

    -- local tiliLabel = self.m_pUILayer:findChildByName("Panel_1/Descbg/Image_bg/Panel_2/GoldIcon3/Num")
    -- tiliLabel:setString(tili);
end

function StageInfoUI:getSaodangFightNum()
    local serverNum = self._data.fightNum;

    if serverNum > 5 then
        serverNum = 5
    end
    local num = math.floor(LRoleDataMgr.MyHeroInfo:GetDetailData():getTili() / self._data.useTili);
    if num < serverNum then
        return num
    end

    return serverNum
end

function StageInfoUI:ShowInfo()
    local mapData = JsonConfig.m_FuBenMapConfig.getDefByID(self._data.configData.mapid)
    --扫荡模式是否开启

    self:FastFightMode(self._data.getStarNum > 0 or mapData.MapType == AppDef.MapType.FactionCopy)

    for i = 1, 3 do
        if i > self._data.getStarNum then
            self.m_pUILayer:findChildByName("Panel_1/Pane/Panel_left/StarList/Star" .. i.. "/Star"):setVisible(false)
        else
            self.m_pUILayer:findChildByName("Panel_1/Pane/Panel_left/StarList/Star" .. i.. "/Star"):setVisible(true)
        end

    end
    if mapData.MapType == AppDef.MapType.FactionCopy then
        self.m_pUILayer:findChildByName("Panel_1/Pane/Panel_left/StarList"):setVisible(false)
    end
    local titleTxt = self.m_pUILayer:findChildByName("Panel_1/Pane/Panel_left/TextPanel/Text_num")
    --local strTitle = string.format(GUITips.RSI_FUBENMAP_RES3, self._data.stageName)
    titleTxt:setString(self._data.configData.Name)

    self._changeTimes = self.m_pUILayer:findChildByName("Panel_1/Pane/Descbg/Image_bg/Panel_4/TimesBg/Icon/Num");

    self._data.maxNum = self._data.configData.AttackCount
    local str = string.format("%d/%d", self._data.fightNum, self._data.maxNum)
    self._changeTimes:setString(str)
    

    if mapData.MapType == AppDef.MapType.FactionCopy then
        --帮派副本
        self._btn:getChildByName("Text"):setString(GUITips.SI_BP_TIP62);
        self.m_pUILayer:findChildByName("Panel_1/Pane/Descbg/Image_bg/Panel_4/TimesBg/AddBtn"):setVisible(false);
        self.m_pUILayer:findChildByName("Panel_1/Pane/Descbg/Image_bg/Panel_1/Tili"):setVisible(false);
        self.m_pUILayer:findChildByName("Panel_1/Pane/Descbg/Image_bg/Panel_1/Desc"):setVisible(true);
        local descLabel = self.m_pUILayer:findChildByName("Panel_1/Pane/Descbg/Image_bg/Panel_1/Desc/Desc_0");
        descLabel:setString(self._data.configData.Des)

    else
        local btnStr = string.format(GUITips.RSI_FUBENMAP_RES6, self:getSaodangFightNum())
        self._btn:getChildByName("Text"):setString(btnStr)
        local tiliLabel = self.m_pUILayer:findChildByName("Panel_1/Pane/Descbg/Image_bg/Panel_1/Tili/Value");
        tiliLabel:setString(self._data.useTili);
        self.m_pUILayer:findChildByName("Panel_1/Pane/Descbg/Image_bg/Panel_1/Tili"):setVisible(true);
        self.m_pUILayer:findChildByName("Panel_1/Pane/Descbg/Image_bg/Panel_1/Desc"):setVisible(false);
    end
end

function StageInfoUI:initControlUI( ... )
    --扫荡一次
    self._btn = self.m_pUILayer:findChildByName("Panel_1/Pane/Descbg/Image_bg/Panel_4/Button_3");
    local function FastFightEvent( sender )
        -- body
        self:SaoDangEvent()
    end
    self._btn:addClickEventListener(FastFightEvent)
    self:MarkIntaractCObj(self._btn)
    self._btn:setVisible(false)

    --挑战
    self._ButtonRight = self.m_pUILayer:findChildByName("Panel_1/Pane/Descbg/Image_bg/Panel_4/Button_2");
    local function OKEvent( sender )
        -- body
        self:challengeEvent()
    end
    self._ButtonRight:addClickEventListener(OKEvent)
    self:MarkIntaractCObj(self._ButtonRight)

    local button = self.m_pUILayer:findChildByName("Panel_1/Pane/Descbg/Close");
    local function closeEvent( sender )
        -- body
        self:closeUI()
    end
    button:addClickEventListener(closeEvent)
    self:MarkIntaractCObj(button)

    local mapData = JsonConfig.m_FuBenMapConfig.getDefByID(self._data.configData.mapid)
    if mapData.MapType == AppDef.MapType.FactionCopy then
        local btn = self.m_pUILayer:findChildByName("Panel_1/Pane/Descbg/Image_bg/Panel_1/Duizhan");
        btn:setVisible(true);
        local function rankEvent( sender )
            -- body
            self:handleRankClicked()
        end
        btn:addClickEventListener(rankEvent)
    else
        self.m_pUILayer:findChildByName("Panel_1/Pane/Descbg/Image_bg/Panel_1/Duizhan"):setVisible(false)
    end

    local addChangeBtn = self.m_pUILayer:findChildByName("Panel_1/Pane/Descbg/Image_bg/Panel_4/TimesBg/AddBtn")
    addChangeBtn:addClickEventListener(function (sender)
        if  self._data.fightNum>0 then
            Utils:ShowScrollTips(GUITips.UI_ChangeReset)
            return 
        end
        self:ShowBuyTimeDialog()
    end)

    -- --扫荡十次
    -- self._Button10 = bg:getChildByName("Button_1_0")
    -- local function tenFastFigjhtEvent( sender)
    --     -- body
    -- end
    -- self._Button10:addClickEventListener(tenFastFigjhtEvent)
    -- self._Button10:setVisible(false)

    --挑战
    self._buttonMid = self.m_pUILayer:findChildByName("Panel_1/Pane/Descbg/Image_bg/Panel_4/Button_1");
    self._buttonMid:addClickEventListener(OKEvent)

    
    ------------------------------------------------------------------------
    
    self._baseItemNode = self.m_pUILayer:getChildByName("IconBg1");
    self._baseItemNode:setVisible(false);
    self._basePetNode = self.m_pUILayer:getChildByName("IconColor");

    -- self._iconNodeList = {}
    -- for i=1,4 do
    --     local node = IconList:getChildByName("Icon_Bg"..i)
    --     node:setVisible(false)
        
    --     -- local item = Utils:GetItemCellValue(icon, 0, 60003, true, true, 10000, nil, false)
    --     table.insert(self._iconNodeList, node)
    -- end


    

    ----------------------------------------------------------------
    

    local duiwu = self.m_pUILayer:findChildByName("Panel_1/Pane/Descbg/Image_bg/Panel_1/Buzhen")
    -- duiwu:setVisible(false)
    duiwu:addClickEventListener(function( sender )
        -- body
        self:HandleBuzhen();
        
    end)
end

function StageInfoUI:handleRankClicked()
    if not self._data.copyData then
        return
    end
    local mapId =  JsonConfig.getMapIdByStageID(self._data.stageId)
    Utils:OpenFunction(AppDef.EModuleID.EMID_BPRank,mapId);
    self:closeUI()
end

function StageInfoUI:HandleBuzhen()
    -- dump( self._data.copyData,"StageInfoUI:HandleBuzhen()========>")
    if self._data.copyData==nil then
        local fightId = JsonConfig.m_stageNodeConfig.getDefByID(self._data.stageId).fightID
        local mapData =JsonConfig.m_vecFightConfig.getDefByID(fightId)
        local value = {}
        value.enemyZhenfaId=mapData.zhenfa[1]
        value.enemyInfos={}
        local monster = 1
        for i=1,5 do
            local index = mapData["index"..i]
            if index>0 then

            end
            value.enemyInfos[i]=index
        end
        --local value = {}
        -- value.enemyZhenfaId = self._data.copyData.zhenfaId
        -- value.enemyInfos = {}
        -- local max = AppDef.Formation.MaxFightNum
        -- for i = 1, self._data.copyData.monsterNum do
        --     local data = self._data.copyData.fightInfo[i]
        --     value.enemyInfos[i] = data.id
        -- end
        -- local mapId =  JsonConfig.getMapIdByStageID(self._data.stageId)
        -- local fun = function()
            
        --    -- LuaNetSendMsg:QueryBangPaiFubenFight(mapId, self._data.copyData.id)
        --     --LuaNetSendMsg:QuertKunLunById(id)
        -- end
        value.callback =  handler(self, StageInfoUI.challengeEvent) 
        -- self:closeUI()
        self.m_pUILayer:setVisible(false)
        Utils:OpenFunction(AppDef.EModuleID.EMID_SJBUZHENWithEnemy,value,true)
    elseif self._data.copyData then 
        local value = {}
        value.enemyZhenfaId = self._data.copyData.zhenfaId
        value.enemyInfos = {}
        local max = AppDef.Formation.MaxFightNum
        for i = 1, self._data.copyData.monsterNum do
            local data = self._data.copyData.fightInfo[i]
            value.enemyInfos[i] = data.id
        end
        local mapId =  JsonConfig.getMapIdByStageID(self._data.stageId)
        local fun = function()
            
            LuaNetSendMsg:QueryBangPaiFubenFight(mapId, self._data.copyData.id)
            --LuaNetSendMsg:QuertKunLunById(id)
        end
        value.callback = fun
       -- self:closeUI()
        Utils:OpenFunction(AppDef.EModuleID.EMID_SJBUZHEN)
        --Utils:OpenFunction(AppDef.EModuleID.EMID_SJBUZHENWithEnemy, value)
    else
        if #LRoleDataMgr.Pet.petlist == 0 then
            Utils:ShowScrollTips(GUITips.UI_No_Shenjiang_Tips)
            return
        end
       -- self:closeUI()
        Utils:OpenFunction(AppDef.EModuleID.EMID_SJBUZHEN)
    end
    
    
end

function StageInfoUI:refreshUIAfterSaoDang(data)
    -- body
    self._data.fightNum = self._data.fightNum - data.sandangNum
    if self._data.fightNum < 0 then
        self._data.fightNum = 0
    end
    local str = string.format("%d/%d", self._data.fightNum, self._data.maxNum)
    self._changeTimes:setString(str)

    local btnStr = string.format(GUITips.RSI_FUBENMAP_RES6, self:getSaodangFightNum())
    self._btn:getChildByName("Text"):setString(btnStr)
end

function StageInfoUI:TiliChanged()
    local btnStr = string.format(GUITips.RSI_FUBENMAP_RES6, self:getSaodangFightNum())
    self._btn:getChildByName("Text"):setString(btnStr)
end

function StageInfoUI:refreshUIAfterReset( data )
    -- body
    self._data.fightNum = self._data.maxNum
    local str = string.format("%d/%d", self._data.fightNum, self._data.maxNum)
    self._changeTimes:setString(str)

    local btnStr = string.format(GUITips.RSI_FUBENMAP_RES6, self:getSaodangFightNum())
    self._btn:getChildByName("Text"):setString(btnStr)

    self._data.leftResetTimes = self._data.leftResetTimes - 1
end

function StageInfoUI:challengeEvent()
    if self._data.fightNum < 1 then
        self:ShowBuyTimeDialog()
        return
    end
    
    local configData = JsonConfig.m_stageNodeConfig.getDefByID(self._data.stageId)
    if configData == nil then
        Utils:ShowScrollTips(self._data.stageId.."不存在")
        return 
    end
    local myTili = LRoleDataMgr:GetMoney(AppDef.EMoneyType.EMT_Tili)
    if myTili < configData.Hope then
        Utils:OpenUseUI(500,1);
        --Utils:ShowScrollTips(GUITips.UI_QiRi_Shop_tips7)
        return
    end

    local mapId =  JsonConfig.getMapIdByStageID(self._data.stageId)
    if self._data.copyData then
        if self._data.copyData.complete == 1 then
            Utils:ShowScrollTips(GUITips.RSI_MDSI_MSGI49)
            return
        end
        LuaNetSendMsg:QueryBangPaiFubenFight(mapId, self._data.copyData.id)
    else
        -- 每次副本挑战都建立独立的结算数据。失败时服务端不会发送
        -- GuanQiaWin 的星级奖励包，若沿用上一场数据会把旧的三星结果
        -- 显示到本场失败结算中。
        LRoleDataMgr.m_fightResultData = {
            wanFaId = 0,
            starNum = 0,
            itemList = {}
        }
        LuaNetSendMsg:QueryFightSatge(5, 1, mapId, self._data.stageId)
    end
    self:closeUI()
end

function StageInfoUI:SaoDangEvent()
    local mapData = JsonConfig.m_FuBenMapConfig.getDefByID(self._data.configData.mapid)
    if mapData.MapType == AppDef.MapType.FactionCopy then
        if self._data.copyData and self._data.copyData.complete == 1 then
            Utils:ShowScrollTips(GUITips.RSI_MDSI_MSGI49)
            return
        end
        if self._data.fightNum < 1 then
            Utils:ShowScrollTips(GUITips.RSI_MONOPOLY_USEUPROOL)
            return
        end

        Utils:OpenFunction(AppDef.EModuleID.EMID_BPQUICKFIGHT, self._data);
        self:closeUI()
        return
    end
    -- body
    if self._data.fightNum < 1 then
        self:ShowBuyTimeDialog()
        return
    end

    local configData = JsonConfig.m_stageNodeConfig.getDefByID(self._data.stageId)
    if configData == nil then
        Utils:ShowScrollTips(self._data.stageId.."不存在")
        return 
    end
    local myTili = LRoleDataMgr:GetMoney(AppDef.EMoneyType.EMT_Tili)
    --if myTili < configData.Hope * 5 then
    if myTili < configData.Hope then
        Utils:OpenUseUI(500,1);
        --Utils:ShowScrollTips(GUITips.UI_QiRi_Shop_tips7)
        return
    end

    local mapId =  JsonConfig.getMapIdByStageID(self._data.stageId)
    --print("initControlUI ===> ", mapId, self._data.stageId)
    LuaNetSendMsg:QueryFightSatge(6, 1, mapId, self._data.stageId)
end


function StageInfoUI:ShowBuyTimeDialog( ... )
    -- body
    local mapData = JsonConfig.m_FuBenMapConfig.getDefByID(self._data.configData.mapid)
    if mapData.MapType == AppDef.MapType.FactionCopy then
        Utils:ShowScrollTips(GUITips.RSI_MONOPOLY_USEUPROOL)
        return
    end
    local function okFunc()
        --购买
        if self._data.leftResetTimes < 1 then
            Utils:ShowScrollTips(GUITips.RSI_FUBENMAP_RES11)
            return
        end
        --print("StageInfoUI:ShowBuyTimeDialog ==>", self._data.stageId)
        LuaNetSendMsg:QueryResetStage(self._data.stageId)
    end
    local function cancelFunc()
    end
    local configData = JsonConfig.m_config.getDefByID(1);

    local values = json.decode(configData.value)
    local ind = #values - self._data.leftResetTimes + 1
    local resetCost = values[ind];
    resetCost = resetCost or self._data.resetCost;
    local strTips = string.format(GUITips.RSI_FUBENMAP_RES5, resetCost, self._data.leftResetTimes)
    Utils:ShowDialogOKCancel(strTips, okFunc, cancelFunc)
end

function StageInfoUI:FastFightMode( isFastOpen )
    -- body
    self._btn:setVisible(isFastOpen)
    self._ButtonRight:setVisible(isFastOpen)
    -- self._Button10:setVisible(isFastOpen)
    self._buttonMid:setVisible(not isFastOpen)
end

function StageInfoUI:closeUI(  )
    -- body
    Utils:DeleteUI("FuBenMap.StageInfoUI")
end

function StageInfoUI:onExit()
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_FuBen_Finish)
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_FuBen1_Finish)
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_Pet_14)
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_Pet_Finish)
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_FuBen2_Finish)
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_FuBen3_Finish)
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_FuBen4_Finish)
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_Equip_Finish)
    self.m_pUILayer = nil
    self:Destory()
end

function StageInfoUI:RegisterGuide()
    if self._buttonMid then
        local guideIds = {GuideDef.StepId.Guide_FuBen_Finish,GuideDef.StepId.Guide_FuBen1_Finish,GuideDef.StepId.Guide_Pet_14
            ,GuideDef.StepId.Guide_Pet_Finish,GuideDef.StepId.Guide_FuBen2_Finish,GuideDef.StepId.Guide_FuBen3_Finish
            ,GuideDef.StepId.Guide_FuBen4_Finish,GuideDef.StepId.Guide_Equip_Finish}
        for i=1,#guideIds do
            Utils:RegisterGuide(guideIds[i], self._buttonMid, handler(self,StageInfoUI.challengeEvent), nil, true)
        end
    end
end

return StageInfoUI
