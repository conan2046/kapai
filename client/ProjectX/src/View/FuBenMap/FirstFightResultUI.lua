
local FirstFightResultUI = LUIBase:New()
FirstFightResultUI.__index = FirstFightResultUI
--local this = LTcpSocket
function FirstFightResultUI:New(data)
	local o = LUIBase:New()
	setmetatable(o,FirstFightResultUI)	
    o:Init(data)
	return o
end

--注册事件
-- -----------------------------------
function FirstFightResultUI:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function FirstFightResultUI:ProcessEvent(msg)

end

function FirstFightResultUI:Init(data)

    self.m_pUILayer = cc.CSLoader:createNode("csd/common/zhandoujiesuanLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    self.m_timeline = cc.CSLoader:createTimeline("csd/common/zhandoujiesuanLayer.csb")
    self.m_timeline:pause()
    self.m_pUILayer:runAction(self.m_timeline)

    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:initData(data)
    self:initControlUI()
    self:showResult();
    self._coolTime = 0
    -- self:AddSchedule()
end

function FirstFightResultUI:initData( data )
     -- dump(data,"data");
    -- body
    self._datas = data
    self._step = 1
    if self._datas.wanFaId == nil then
        self._datas.wanFaId = 0
    end
end

function FirstFightResultUI:showResult()
    if self._datas.win == true then
        Utils:PlayEffect("GuideBGM", "id", 2)
        self:showWinResult();
    else
        Utils:PlayEffect("GuideBGM", "id", 1)
        self:showFailResult();
    end
    
    self.m_timeline:gotoFrameAndPlay(0, false)
    
    local function showResultEffect()
        local imod
        if self._datas.win == true then
            local parent = self.m_pUILayer:findChildByName("Panel/victorypanel/win_bg/effect_zhandoujiesuan_2");
            imod = Utils:CreateImod("res2/animation/effect_zhandoujiesuan_2", cc.p(0,0), parent, 1);
        else
            local parent = self.m_pUILayer:findChildByName("Panel/victorypanel/Defeat_bg/effect_zhandoujiesuan_3");
            imod = Utils:CreateImod("res2/animation/effect_zhandoujiesuan_3", cc.p(0,0), parent, 1);
        end
        if imod then
            imod:PlayNewAction(0,false)
        end
    end
    self.m_timeline:addFrameEndCallFunc(35, "Effect", showResultEffect)
end

function FirstFightResultUI:showWinResult()
    self._resultPanel:setVisible(true);
    self._winNode:setVisible(true);
    self._failNode:setVisible(false);
    self._reviveBtn:setVisible(false);
    --local imod = Utils:CreateImod("Monster/btm"..bossdata.pic.."_zd", cc.p(0,0), pImodNode, 1)
    
    self:showStar();
    if self._datas.wanFaId == AppDef.EModuleID.EMID_BPFUBEN then
        self:ShowBPFubenAward();
    else
        self:showAwardTitle();
        self:showMoneyAward();
        self:showRoleExp();
        self:showPetAward();
        self:showItemAward();
    end
    
end

function FirstFightResultUI:showAwardTitle()
    if #self._datas.itemList > 0 then
        self._awareTitleLayer:retain();
        self._awareTitleLayer:removeFromParent();
        self._listView:pushBackCustomItem(self._awareTitleLayer);
        self._awareTitleLayer:release();
    else
        self._awareTitleLayer:setVisible(false)
    end
end

function FirstFightResultUI:ShowBPFubenAward()
    local damageLabel = self.m_pUILayer:findChildByName("Fuben/tontguanxinxilayer/Text_1")
    damageLabel:setString(GUITips.SI_BP_TIP58 .. self._datas.damage);
    local listView = self.m_pUILayer:findChildByName("Fuben/ListView");
    listView:removeAllChildren();
    for i=1,#self._datas.itemList do
        local itemId = tonumber(self._datas.itemList[i].itemId)
        if itemId ~= nil and itemId > 0 then
            local itemNode = self._baseItem:clone()
            Utils:GetItemCellValue(itemNode, 0, itemId, true, true, self._datas.itemList[i].itemNum, nil, true)
            itemNode:setVisible(true);
            local name = itemNode:getChildByName("name")
            if itemId == AppDef.AwrdItem.AWRD_ITEM_EQUIP then
                local nameStr = Utils:getEquipNameByID(self._datas.itemList[i].itemNum)
                name:setString(nameStr)
            else
                local nameStr = Utils:getItemNameByID(itemId)
                name:setString(nameStr)
            end
            listView:pushBackCustomItem(itemNode);
        end
    end
end

function FirstFightResultUI:showMoneyAward()
    local ind = 0
    local hasData = false;
    for i=1,#self._datas.itemList do
        local itemId = tonumber(self._datas.itemList[i][1])
        if AppDef:IsMoneyType(itemId) == true then
            ind = ind + 1
            if ind > 4 then
                break
            end
            hasData = true
            local iconImg = self._moneyLayer:getChildByName("huobi_" .. ind)
            local label = iconImg:getChildByName("GoldNumBg"):getChildByName("Num");
            label:setString(self._datas.itemList[i][3])


            local str = AppDef:GetMoneyIconById(itemId)
            iconImg:loadTexture(str, ccui.TextureResType.plistType)
        end
    end
    for i=ind+1,4 do 
        local iconImg = self._moneyLayer:getChildByName("huobi_" .. i)
        iconImg:setVisible(false)
    end

    if hasData then
        self._moneyLayer:retain();
        self._moneyLayer:removeFromParent();
        self._listView:pushBackCustomItem(self._moneyLayer);
        self._moneyLayer:release();
    else
        self._moneyLayer:setVisible(false)
    end
end

function FirstFightResultUI:showRoleExp()
    local exp = 0
    for i=1,#self._datas.itemList do
        local itemId = tonumber(self._datas.itemList[i][1])
        if itemId == AppDef.SpecialItemId.HeroExp then
            exp = exp + self._datas.itemList[i][3];
        end
    end
    print("showRoleExp",exp)
    if exp == 0 then
        self._heroLayer:setVisible(false)
        return;
    end
    self._heroLayer:setVisible(true)
    self._heroLayer:retain();
    self._heroLayer:removeFromParent();
    self._listView:pushBackCustomItem(self._heroLayer);
    self._heroLayer:release();

    local label = self._heroLayer:getChildByName("level");
    label:setString(LRoleDataMgr.MyHeroInfo.level .. GUITips.Common_Ji);

    print("LRoleDataMgr.MyHeroInfo.head",LRoleDataMgr.MyHeroInfo.head)
    local strHeadImage = AppDef:GetHeroPicFileName(LRoleDataMgr.MyHeroInfo.head, AppDef.HeadType.HERO_IMAGE_HEAD_ROUND);
    print("strHeadImage",strHeadImage)
    local infoNode = self._heroLayer:findChildByName("Panel_zhujue/Icon_zhujue");
    infoNode:loadTexture(strHeadImage, ccui.TextureResType.localType);


    label = self._heroLayer:getChildByName("Text_jingyan");
    label:setString(string.format(GUITips.RSI_ZQX_HERO_LV_UP,exp));

    local nextExp = LDataConstMgr:GetHeroLevelUpExp(LRoleDataMgr.MyHeroInfo.level)
    local expRate = LRoleDataMgr.MyHeroInfo.DetailData.exp/nextExp
    if expRate < 0 or expRate > 1 then
        expRate = 0
    end
    expRate = expRate * 100
    local bar = self._heroLayer:getChildByName("bloodBar");
    bar:setPercent(expRate)
    label = self._heroLayer:getChildByName("valu");
    label:setString("" .. LRoleDataMgr.MyHeroInfo.DetailData.exp .. "/" .. nextExp);

    if LRoleDataMgr.isShowLvUp then
        self._heroLayer:findChildByName("Image_shengji"):setVisible(true);
    else
        self._heroLayer:findChildByName("Image_shengji"):setVisible(false);
    end
end

function FirstFightResultUI:showPetAward()

    local pCellPet = self.m_pUILayer:findChildByName("Panel/firPanel/shenjianglayer")
    local ind = 0;
    for i=1,#self._datas.itemList do
        local itemId = tonumber(self._datas.itemList[i][1])
        if itemId == AppDef.SpecialItemId.PetExp then
            ind = i;
            break;
        end
    end
    if ind == 0 then
        self._petLayer:setVisible(false)
        return;
    end

    self._petLayer:retain();
    self._petLayer:removeFromParent();
    self._listView:pushBackCustomItem(self._petLayer);
    self._petLayer:release();
    
    local petList = LRoleDataMgr.Pet.petlist;
    local cnt = 1;
    for i = 1, #petList do
        if cnt > 5 then
            break
        end
        local pet = LRoleDataMgr.Pet.petlist[i]
        -- print("pet.fightPos",pet.fightPos)
        if LRoleDataMgr.Pet:GetPetPos(pet.id) > 0 then
            local petIcon = pCellPet:getChildByName("IconColor".. cnt)
            petIcon:setVisible(true)
            local petID = pet.id
            local pData =LRoleDataMgr.Pet:GetPetById(petID)
            Utils:ShowPetOnItem(petID, petIcon, true, pet.star);
            petIcon:getChildByName("Text_jiang" .. cnt):setString(string.format(GUITips.RSI_ZQX_HERO_LV_UP,self._datas.itemList[ind][3]))

            if LRoleDataMgr.tmpPetUpInfo and LRoleDataMgr.tmpPetUpInfo[petID] then
                petIcon:getChildByName("Image_27_0"):setVisible(true)
            else
                petIcon:getChildByName("Image_27_0"):setVisible(false)
            end
            petIcon:getChildByName("LoadingBar_2"):setPercent(pData.exp/ pData.expMax*100)
            petIcon:getChildByName("Text"):setString(pData.level)
            cnt = cnt + 1
        end
    end
    for i = cnt, 5 do
        local petIcon = pCellPet:getChildByName("IconColor"..i)
        petIcon:setVisible(false)
    end
    -- for i=1, 5 do
    --     local petIcon = pCellPet:getChildByName("IconColor"..i)
    --     if i > #LRoleDataMgr.Pet.petlist then
    --         petIcon:setVisible(false)
    --     else
            
    --         petIcon:setVisible(true)
            
    --         local petID = LRoleDataMgr.Pet.petlist[i].id
    --         local pData =LRoleDataMgr.Pet:GetPetById(petID)

    --         print("petID",petID)
    --         Utils:ShowPetOnItem(petID, petIcon, true);
    --         petIcon:getChildByName("Text_jiang" .. i):setString(string.format(GUITips.RSI_ZQX_HERO_LV_UP,self._datas.itemList[ind].itemNum))

    --         if LRoleDataMgr.tmpPetUpInfo and LRoleDataMgr.tmpPetUpInfo[petID] then
    --             petIcon:getChildByName("Image_27_0"):setVisible(true)
    --         else
    --             petIcon:getChildByName("Image_27_0"):setVisible(false)
    --         end
    --         petIcon:getChildByName("LoadingBar_2"):setPercent(pData.exp/ pData.expMax*100)
    --         petIcon:getChildByName("Text"):setString(pData.level)
    --     end   
    -- end
end

function FirstFightResultUI:showItemAward()
    self._itemList:removeAllChildren();
    --dump(self._datas, "----------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>showItemAward")
    local hasItem = false;
    for i=1,#self._datas.itemList do

        local itemId = tonumber(self._datas.itemList[i][1]);
        local itemNum = self._datas.itemList[i][3]
        if itemId ~= nil and itemId > 0 then
            if AppDef:IsSpecialItem(itemId) ==  false or itemId == AppDef.AwrdItem.AWRD_ITEM_EQUIP then
                local itemNode = self._baseItem:clone()
                -- local dataArr = {itemId,0,itemNum};
                -- if itemId == AppDef.AwrdItem.AWRD_ITEM_EQUIP or itemId == AppDef.AwrdItem.AWRD_ITEM_FABAO then
                --     dataArr = {itemId,itemNum,1};
                --     if self._datas.itemList[i].addNum then
                --         dataArr[3] = self._datas.itemList[i].addNum
                --     end
                -- end
                -- dump(dataArr,"-----------dataArr")
                Utils:ShowItemByConfigData(self._datas.itemList[i], itemNode, nil, true, true)
                                        --grid,type,itemId,showQuality,showNum,num, pItem, isOpenTouch, isChangeSize, pid, pstar,isSelect
                -- Utils:GetItemCellValue(itemNode, 0, itemId, true, true, self._datas.itemList[i].itemNum, nil, true)
                itemNode:setVisible(true);
                local name = itemNode:getChildByName("name")
                if itemId == AppDef.AwrdItem.AWRD_ITEM_EQUIP then
                    local nameStr = Utils:getEquipNameByID(self._datas.itemList[i][2])
                    name:setString(nameStr)
                else
                    local nameStr = Utils:getItemNameByID(itemId)
                    name:setString(nameStr)
                end
                
                self._itemList:addChild(itemNode);
                hasItem = true;
            end
        end
    end

    if hasItem then
        self._itemLayer:retain();
        self._itemLayer:removeFromParent();
        self._listView:pushBackCustomItem(self._itemLayer);
        self._itemLayer:release();
    else
        self._itemLayer:setVisible(false)
    end
end

function FirstFightResultUI:showFailByStroy()
    self._firPanel:setVisible(true)
    self._firPanel:getChildByName("TitleBg"):setVisible(false)
    self._passLayer:setVisible(true)
end

function FirstFightResultUI:showFailResult()
    self._resultPanel:setVisible(true)
    self._winNode:setVisible(false)
    self._firPanel:setVisible(true)
    self._bpCopyPanel:setVisible(false)
    self._failNode:setVisible(true)
    self._reviveBtn:setVisible(true)
    self._petLayer:setVisible(false)
    self._heroLayer:setVisible(false)
    self._itemLayer:setVisible(false)
    self._moneyLayer:setVisible(false)
    self._awareTitleLayer:setVisible(false)

    local tipLayer = self.m_pUILayer:findChildByName("Panel/firPanel/tishengzhanlilayer")
    tipLayer:retain();
    tipLayer:removeFromParent();
    self._listView:pushBackCustomItem(tipLayer);
    tipLayer:release();

    if self._datas.wanFaId == AppDef.EModuleID.EMID_KAPAI_WF_XZ then
        self:showFailByStroy()
        self._passLayer:retain()
        self._passLayer:removeFromParent()
        self._listView:pushBackCustomItem(self._passLayer)
        self._passLabel:setString("")
        local data = LActivityManager:GetXueZhanData()
        if data.m_reviveCnt ~= nil then
            self._reviveCntLabel:setString(""..data.m_reviveCnt)
        end
    end
end

function FirstFightResultUI:showStar()
    local starLayer = self._winNode:getChildByName("starlayer")
    local tipsLabel = self._winNode:getChildByName("tips")
    if self._datas.wanFaId == AppDef.EModuleID.EMID_KAPAI_WF_FS_STORY
        or self._datas.wanFaId == AppDef.EModuleID.EMID_BPFUBEN then
        starLayer:setVisible(false)
        tipsLabel:setString("")
        self._datas.starNum = 2
    else
        local msg = GUITips["RSI_XUEZHAN_TIP2" .. (6 +self._datas.starNum)];
        tipsLabel:setString(msg)
    end
    

    local function ShowStarEffect(efffectNode)
        efffectNode:setVisible(true);
        efffectNode:start()
    end

    local function ShowStar1Effect()
        local efffectNode = self._winNode:findChildByName("starlayer/Particle_1")
        ShowStarEffect(efffectNode);
    end

    local function ShowStar2Effect()
        local efffectNode = self._winNode:findChildByName("starlayer/Particle_2")
        ShowStarEffect(efffectNode);
    end

    local function ShowStar3Effect()
        local efffectNode = self._winNode:findChildByName("starlayer/Particle_3")
        ShowStarEffect(efffectNode);
    end

    local frameKeyArr = {{55,ShowStar1Effect},{65,ShowStar2Effect},{70,ShowStar3Effect}}

    for i = 1, 3 do
        local winNode = self._winNode:getChildByName("win" .. i);
        if i == self._datas.starNum then
            winNode:setVisible(true)
        else
            winNode:setVisible(false)
        end
        if i > self._datas.starNum then
            starLayer:getChildByName("Star" .. i):setVisible(false);
        else
            self.m_timeline:addFrameEndCallFunc(frameKeyArr[i][1], "Star" .. i, frameKeyArr[i][2])
        end
    end
end

function FirstFightResultUI:initControlUI()
    -- body
    local Panel = self.m_pUILayer:getChildByName("Panel");
    self._baseItem = self.m_pUILayer:getChildByName("baseItem");
    self._baseItem:setVisible(false);
    local victoryPanel = Panel:getChildByName("victorypanel");
    local replayBtn = victoryPanel:getChildByName("Button_Replay");
    replayBtn:addClickEventListener(handler(self, FirstFightResultUI.OnBtnReplayClick))
    local tongjiBtn = victoryPanel:getChildByName("Button_tongji");
    tongjiBtn:addClickEventListener(handler(self, FirstFightResultUI.OnBtnTongjiClick))
    -------------------------------------------------------------------------
    local firPanel = Panel:getChildByName("firPanel")
    self._firPanel = firPanel;
    self._bpCopyPanel = self.m_pUILayer:getChildByName("Fuben");
    self._petLayer = self._firPanel:getChildByName("shenjianglayer");
    self._heroLayer = self._firPanel:getChildByName("zhujueayer");
    self._resultPanel = Panel:getChildByName("victorypanel");
    self._resultPanel:setVisible(true)
    self._itemLayer = self._firPanel:getChildByName("itemlayer");
    self._moneyLayer = self._firPanel:getChildByName("huobilayer");
    self._itemList = self._itemLayer:getChildByName("itemList");
    self._winNode = self._resultPanel:getChildByName("win_bg");
    self._failNode = self._resultPanel:getChildByName("Defeat_bg");
    self._listView = self._firPanel:getChildByName("ListView");
    self._awareTitleLayer = self._firPanel:getChildByName("TitleBg");

    self._passLayer = self._firPanel:getChildByName("tontguanxinxilayer")
    self._passLabel = self._passLayer:getChildByName("Text_1")
    self._passLabel:setString("")
    self._reviveBtn = self._passLayer:getChildByName("Button_reborn")
    self._reviveBtn:addClickEventListener(handler(self, FirstFightResultUI.OnBtnReviveClick))
    self._reviveCntLabel = self._reviveBtn:getChildByName("Text_xuezhan"):getChildByName("Num")



    if self._datas.wanFaId == AppDef.EModuleID.EMID_BPFUBEN then
        self._firPanel:setVisible(false)
        self._bpCopyPanel:setVisible(true)
    else
        self._firPanel:setVisible(true)
        self._bpCopyPanel:setVisible(false)
    end


    -- self._coinNum = firPanel:getChildByName("GoldIcon1"):getChildByName("GoldNumBg"):getChildByName("Num")
    -- self._coinNum:setString("3000")

    -- local prof = LRoleDataMgr.MyHeroInfo.professional
    -- local strHeadImage = AppDef:GetHeroPicFileName(prof, AppDef.HeadType.HERO_IMAGE_HEAD_ROUND)
    -- print("strHeadImage ===", strHeadImage, prof)
    -- self._roleIcon = firPanel:getChildByName("IconColor"):getChildByName("Icon")
    -- self._roleIcon:loadTexture(strHeadImage, ccui.TextureResType.localType)
    -- local Text  = firPanel:getChildByName("IconColor"):getChildByName("Text")
    -- Text:setString(LRoleDataMgr.MyHeroInfo.level)

    -- self._petIconList = {}
    -- for i=1, 5 do
    --     local IconColor = firPanel:getChildByName("IconColor"..i)
    --     IconColor:setVisible(false)
    --     table.insert(self._petIconList, IconColor)
    -- end
    print("====================================================================")
    Panel:setTouchEnabled(true);
    Panel:addClickEventListener(handler(self, FirstFightResultUI.OnCloseClicked))

    local function zhaopuFunc()
        Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_CHOUKA)
        LGameMsg.m_baseMsg:ChangeEventId(LGameEvent.ExitBattle)
        self:SendMsg(LGameMsg.m_baseMsg)
        self:colseUI();
    end

    local function qianghuaFunc()
        Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_EQUIP_BAG)
        LGameMsg.m_baseMsg:ChangeEventId(LGameEvent.ExitBattle)
        self:SendMsg(LGameMsg.m_baseMsg)
        self:colseUI();
    end

    local function yangchengFunc()
        Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_SHENJIANG)
        LGameMsg.m_baseMsg:ChangeEventId(LGameEvent.ExitBattle)
        self:SendMsg(LGameMsg.m_baseMsg)
        self:colseUI();
    end

    self.m_pUILayer:findChildByName("Panel/firPanel/tishengzhanlilayer/Button_1"):addClickEventListener(zhaopuFunc);
    self.m_pUILayer:findChildByName("Panel/firPanel/tishengzhanlilayer/Button_2"):addClickEventListener(qianghuaFunc);
    self.m_pUILayer:findChildByName("Panel/firPanel/tishengzhanlilayer/Button_3"):addClickEventListener(yangchengFunc);
    -------------------------------------------------------------------------
    -- self._button = Panel:getChildByName("Button")
    -- self._button:setVisible(false)
    -- self._itemNode = {}
    -- if self._datas == nil then
    --     return
    -- end
    -- for i=1, #self._datas.itemList do

    --     --临时代码
    --     if i > 3 then
    --         return
    --     end

    --     local Icon_Bg1 = self._button:getChildByName("Icon_Bg"..i)
    --     table.insert(self._itemNode, Icon_Bg1)
    --     local IconBg = Icon_Bg1:getChildByName("IconBg")
    --     local name = Icon_Bg1:getChildByName("Name")
        
    --     local oneData = self._datas.itemList[i]
    --     if oneData.itemNum < 1 then
    --         oneData.itemNum = 1
    --     end
        
    --     print("oneData.itemId  1111 ==>", oneData.itemId)
    --     local item = Utils:GetItemCellValue(IconBg, 0, oneData.itemId, true, true, oneData.itemNum, nil, true)
    --     local nameStr = Utils:getItemNameByID(oneData.itemId)
    --     name:setString(nameStr)
        
    -- end

    
end

--复活
function FirstFightResultUI:OnBtnReviveClick()
    --print("FirstFightResultUI:OnBtnReviveClick",self._datas.win)
    if self._datas.win then
        return
    end
    --print("signXueZhan",self._datas.signXueZhan)
    if self._datas.wanFaId == AppDef.EModuleID.EMID_KAPAI_WF_XZ then
        local data = LActivityManager:GetXueZhanData()
        if data.m_levelId == nil or data.m_levelId == 0 then
            return
        end
        if data.m_reviveCnt == 0 then
            Utils:ShowScrollTips(GUITips.RSI_XUEZHAN_TIP26)
            return
        end
        --血战 复活
        LuaNetSendMsg:SendXueZhanReviveReq(1)
        LGameMsg.m_baseMsg:ChangeEventId(LGameEvent.ExitBattle)
        self:SendMsg(LGameMsg.m_baseMsg)
        self:colseUI()
        return
    end
end

function FirstFightResultUI:OnBtnReplayClick(sender)
    self:DeleteSchedule()
    self._step = 2
    --self:ShowResultEvent()
    LGameMsg.m_baseMsg:ChangeEventId(LGameEvent.ExitBattle)
    self:SendMsg(LGameMsg.m_baseMsg)
    self:colseUI()

    local handler
    local function replay()
        Utils:unschedule(nil, handler)
        --print(" LRoleDataMgr:ReplayBattle()")
        LRoleDataMgr:ReplayBattle(true)
        
    end
    handler = Utils:schedule(nil, replay, 0.5, false)
end

function FirstFightResultUI:OnBtnTongjiClick(sender)
    Utils:InitUI("FuBenMap.FightDatumUI",AppDef.UIType.PopFirstClassLayer)
end

function FirstFightResultUI:OnCloseClicked(sender)
    self:ShowResultEvent()
end

function FirstFightResultUI:ShowResultEvent(  )
    local function OkFunc()
        --血战
        local data = LActivityManager:GetXueZhanData()
        print("exit",data.m_cnt,data.m_reviveCnt,data.m_state)
        if data.m_cnt == 0 then
            if data.m_reviveCnt == 0 then
                Utils:InitUI("XueZhan.XueZhanEndUI",AppDef.UIType.PopWindow)
            else
                LuaNetSendMsg:SendXueZhanReviveReq(2)
            end
        else
            --血战 重置
            LuaNetSendMsg:QueryXueZhanInfo(6)
        end
        LGameMsg.m_baseMsg:ChangeEventId(LGameEvent.ExitBattle)
        self:SendMsg(LGameMsg.m_baseMsg)
        self:colseUI()
    end

    if self._datas.wanFaId == AppDef.EModuleID.EMID_KAPAI_WF_XZ then
        local data = LActivityManager:GetXueZhanData()
        if not self._datas.win then 
            Utils:ShowXueZhanDialog(OkFunc,handler(self,FirstFightResultUI.OnBtnReviveClick),data.m_reviveCnt)
            return
        elseif data.m_state == 4 then
            Utils:InitUI("XueZhan.XueZhanEndUI",AppDef.UIType.PopWindow)
        end
    end

    LGameMsg.m_baseMsg:ChangeEventId(LGameEvent.ExitBattle)
    self:SendMsg(LGameMsg.m_baseMsg)
    self:colseUI()
    -- -- body
    -- print("ShowResultEvent =========================>")
    -- if self._step == 1 then
    --     if not self._datas.win and self._datas.wanFaId == AppDef.EModuleID.EMID_KAPAI_WF_XZ then
    --         local data = LActivityManager:GetXueZhanData()
    --         if data.m_reviveCnt > 0 then
    --             Utils:ShowDialogOKCancel(GUITips.RSI_XUEZHAN_TIP19,OkFunc)
    --             return
    --         end
    --         LuaNetSendMsg:QueryXueZhanInfo(6)
    --     end
    --     self._firPanel:setVisible(false)
    --     self._bpCopyPanel:setVisible(false)
    --     -- self._button:setVisible(true)
    --     self._step = self._step + 1
    -- elseif self._step == 2 then 
    --     LGameMsg.m_baseMsg:ChangeEventId(LGameEvent.ExitBattle)
    --     self:SendMsg(LGameMsg.m_baseMsg)
    --     self:colseUI()
    -- end
end

function FirstFightResultUI:colseUI( ... )
    -- body
    Utils:DeleteUI("FuBenMap.FirstFightResultUI")
end

function FirstFightResultUI:onExit()
    Utils:CheckGuide(GuideDef.StepId.Guide_Pet_15,true)
    self.m_pUILayer = nil
    self:Destory()
    self:DeleteSchedule()
    if LRoleDataMgr.isShowLvUp then
        Utils:OpenFunction(AppDef.EModuleID.EMID_LVUP)
    end
    -- if LRoleDataMgr.m_fightResultData then
    --     LRoleDataMgr.m_fightResultData.wanFaId = 0
    -- end
    -- LRoleDataMgr.isShowLvUp
end


function FirstFightResultUI:DeleteSchedule()
    if self.m_refreshHandler then
        Utils:unschedule(nil, self.m_refreshHandler)
        self.m_refreshHandler = nil
    end
end

function FirstFightResultUI:AddSchedule()
    self:DeleteSchedule()
    local function RefreshCallback(dt)
        self._coolTime = self._coolTime + 1
        if self._coolTime >= 3 then
             self._coolTime = 0
            self:ShowResultEvent()
        end
    end
    self.m_refreshHandler = Utils:schedule(nil, RefreshCallback, 1, false)
end

return FirstFightResultUI