--参加按钮
function EnterBtnTouched(id, isFastPath)
    if isFastPath then
        local buffer = {
            [AppDef.EActivityID.EAID_SHENJIEMIJING] = true,
            [AppDef.EActivityID.EAID_WEIWODUXIAN] = true,
        }
        if buffer[id] == nil then
            for i=1,#LRoleDataMgr.OpenedActData do
                if id == LRoleDataMgr.OpenedActData[i].actID then
                    if LRoleDataMgr.OpenedActData[i].timestamp then
                        -- Utils:ShowScrollTips(GUITips.RSI_TIPS_OPEN1)
                        Utils:OpenWanfaUI(id)
                        return
                    end
                end
            end
        end
    end

    if id == AppDef.EActivityID.EAID_TOWER then 
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Tower.NewTowerUI",AppDef.UIType.SpecialLayer)
        LUIManager:SendMsg(LGameMsg.m_initUIMsg)
    elseif id == AppDef.EActivityID.EAID_SHAKEMONEYTREE then 
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Activity.MoneyTreeMainUI",AppDef.UIType.FirstClassLayer)
        LUIManager:SendMsg(LGameMsg.m_initUIMsg)
    elseif id == AppDef.EActivityID.EAID_KUNLUN then 
        LuaNetSendMsg:QueryEnterKunlun()
    elseif id == AppDef.EActivityID.EAID_ADVANCE then

        --跨服也可以昆仑寻宝
        -- if LRoleDataMgr.m_bIsCrossServer then
        --     Utils:ShowScrollTips(GUITips.RSI_CROSSSERVER_TIPS_2)
        --     return
        -- end

        if LRoleDataMgr.m_bIsInBattle then
            Utils:ShowScrollTips(GUITips.RSL_AY_MSG4)
            return
        end

        if LRoleDataMgr.MyHeroInfo:IsTeam() then
            Utils:ShowScrollTips(GUITips.RSI_VAWL_TIP_MONOPPLY)
            return
        end

        LGameMsg.m_baseMsg:ChangeEventId(LUILoadingEvt.ShowLoading)
        LUIManager:SendMsg(LGameMsg.m_baseMsg)

        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Monopoly.MonopolyBaseUI",AppDef.UIType.Normal)
        LUIManager:SendMsg(LGameMsg.m_initUIMsg)
        
    elseif id == AppDef.EActivityID.EAID_BOSS then --每日Boss
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Activity.DailyBossMainUI",AppDef.UIType.FirstClassLayer)
        LUIManager:SendMsg(LGameMsg.m_initUIMsg)
    elseif id == AppDef.EActivityID.EAID_ANIMA then -- 灵气捐献
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Activity.DonateManiUI",AppDef.UIType.FirstClassLayer)
        LUIManager:SendMsg(LGameMsg.m_initUIMsg)
    elseif id == AppDef.EActivityID.EAID_XIUXIANLILIAN then 
        LuaNetSendMsg:QueryLiLianInfo(1,nil)--请求修仙历练数据
    elseif id == AppDef.EActivityID.EAID_FLYFARY then  --飞仙战场
        LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.AutoPathEvent.StopAutoPath)
        LUIManager:SendMsg(LGameMsg.m_cBaseMsg)
        LuaNetSendMsg:QueryFlyFaryField(1)
    elseif id == AppDef.EActivityID.EAID_CANGBAOTU then 
        LGameMsg.m_baseMsgWithOne:Change(LUITaskDataEvent.ClickTask,102)
        LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
    elseif id == AppDef.EActivityID.EAID_ZHUAGUI then --捉鬼（寻路）
        if LRoleDataMgr.m_bIsInBattle then
            Utils:ShowScrollTips(GUITips.RSL_AY_MSG4)
            return
        end
        LGameMsg.m_autoPathMsg:ChangeToStart(11,-1,-1,0,bit.lshift(184,16),true,true, nil)
        LUIManager:SendMsg(LGameMsg.m_autoPathMsg)
		LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, true)
		LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
    elseif id == AppDef.EActivityID.EAID_DANYUAN then --丹园（寻路）
        if LRoleDataMgr.m_bIsInBattle then
            Utils:ShowScrollTips(GUITips.RSL_AY_MSG4)
            return
        end
        LGameMsg.m_autoPathMsg:ChangeToStart(11,-1,-1,0,bit.lshift(106,16),true,true, nil)
        LUIManager:SendMsg(LGameMsg.m_autoPathMsg)
		LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, true)
		LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
    elseif id == AppDef.EActivityID.EAID_SHIMEN then --师门（寻路）
        if LRoleDataMgr.m_bIsInBattle then
            Utils:ShowScrollTips(GUITips.RSL_AY_MSG4)
            return
        end
        LGameMsg.m_autoPathMsg:ChangeToStart(11,-1,-1,0,bit.lshift(19,16),true,true, nil)
        LUIManager:SendMsg(LGameMsg.m_autoPathMsg)
		LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, true)
		LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
    elseif id == AppDef.EActivityID.EAID_CONVOY then --护送神兽（寻路）
        if LRoleDataMgr.m_bIsInBattle then
            Utils:ShowScrollTips(GUITips.RSL_AY_MSG4)
            return
        end
        LGameMsg.m_autoPathMsg:ChangeToStart(11,-1,-1,0,bit.lshift(23,16),true,true, nil)
        LUIManager:SendMsg(LGameMsg.m_autoPathMsg)
		LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, true)
		LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
    elseif id == AppDef.EActivityID.EAID_QUBAO then --杀敌取宝（寻路）
        if LRoleDataMgr.m_bIsInBattle then
            Utils:ShowScrollTips(GUITips.RSL_AY_MSG4)
            return
        end
        LGameMsg.m_autoPathMsg:ChangeToStart(11,-1,-1,0,bit.lshift(2,16),true,true, nil)
        LUIManager:SendMsg(LGameMsg.m_autoPathMsg)
		LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, true)
		LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
    elseif id == AppDef.EActivityID.EAID_QUESTION then --每日答题（寻路）
        if LRoleDataMgr.m_bIsInBattle then
            Utils:ShowScrollTips(GUITips.RSL_AY_MSG4)
            return
        end
        LGameMsg.m_autoPathMsg:ChangeToStart(11,-1,-1,0,bit.lshift(198,16),true,true, nil)
        LUIManager:SendMsg(LGameMsg.m_autoPathMsg)
		LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, true)
		LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
    elseif id == AppDef.EActivityID.EAID_PLANT or id == AppDef.EActivityID.EAID_FACTIONROB then--帮派种植、帮派掠夺
        Utils:OpenFunction(AppDef.EModuleID.EMID_BPLIEBIAO, true, true)
    elseif id == AppDef.EActivityID.EAID_ORDEAL then 
        if LRoleDataMgr.MyHeroInfo:IsTeam() then
            local function okFunc()
                LuaNetSendMsg:QueryLeaveTeam()
                LuaNetSendMsg:QueryShiLianInfo(1)--英勇试炼
            end
            local function canelFunc()           
            end
            Utils:ShowDialogOKCancel(GUITips.RSI_TARGET_RD_TIPS22, okFunc,canelFunc)       
        else
             LuaNetSendMsg:QueryShiLianInfo(1)--英勇试炼
        end
         
      
    elseif id == AppDef.EActivityID.EAID_LIUJIESHILIAN then 
        LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.AutoPathEvent.StopAutoPath)
        LUIManager:SendMsg(LGameMsg.m_cBaseMsg)
        LuaNetSendMsg:QueryXunChaShiInfo(1) --六界巡查
    elseif id == AppDef.EActivityID.EAID_FISH then
        Utils:ShowDialogOKCancel(GUITips.RSI_GMN_TIP16, function()
            LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.AutoPathEvent.StopAutoPath)
            LUIManager:SendMsg(LGameMsg.m_cBaseMsg)
            LuaNetSendMsg:QueryFishingInfo(2,0,-1)--钓鱼
        end, function()end)
    elseif id == AppDef.EActivityID.EAID_LINGMO then
        Utils:ShowDialogOKCancel(GUITips.RSI_GMN_TIP19, function()
            LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.AutoPathEvent.StopAutoPath)
            LUIManager:SendMsg(LGameMsg.m_cBaseMsg)
            LuaNetSendMsg:QueryLingMoInfo()--灵魔
        end, function()end)
    elseif id == AppDef.EActivityID.EAID_LEITAI then
        if LRoleDataMgr.m_bIsInBattle then
            Utils:ShowScrollTips(GUITips.RSL_AY_MSG4)
            return
        end
        if LRoleDataMgr.MyHeroInfo:IsTeam() then
		    Utils:ShowScrollTips(GUITips.RSI_GMN_TIP20)
		    return
        end
        LuaNetSendMsg:QueryLeiTaiInfo(4)--个人擂台
    elseif id == AppDef.EActivityID.EAID_PETCOPY then
        Utils:OpenInstance(1)
    elseif id == AppDef.EActivityID.EAID_UPGRADECOPY then
        Utils:OpenInstance(2)
    elseif id == AppDef.EActivityID.EAID_STRENGTHENCOPY then
        Utils:OpenInstance(202)
    elseif id == AppDef.EActivityID.EAID_QIANNENGCOPY then
        Utils:OpenInstance(203)
    elseif id == AppDef.EActivityID.EAID_CUILIANCOPY then
        Utils:OpenInstance(204)
    elseif id == AppDef.EActivityID.EAID_JUEGUXUANYA then
        Utils:OpenInstance(102)
    elseif id == AppDef.EActivityID.EAID_HUBOZHAOZE then
        Utils:OpenInstance(105)    
    elseif id == AppDef.EActivityID.EAID_BAIHUA then
        Utils:ShowDialogOKCancel(GUITips.RSI_GMN_TIP13, function()
            LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.AutoPathEvent.StopAutoPath)
            LUIManager:SendMsg(LGameMsg.m_cBaseMsg)
            LuaNetSendMsg:QueryEnterBaihua()--百花仙子
        end, function()end)
    elseif id == AppDef.EActivityID.EAID_NIANSHOU then
        Utils:ShowDialogOKCancel(GUITips.RSI_GMN_TIP30, function()
            LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.AutoPathEvent.StopAutoPath)
            LUIManager:SendMsg(LGameMsg.m_cBaseMsg)
            LuaNetSendMsg:QueryEnterNianShou()--年兽
        end, function()end)
    elseif id == AppDef.EActivityID.EAID_WEEKTASK then
        if LRoleDataMgr.m_bIsInBattle then
            Utils:ShowScrollTips(GUITips.RSL_AY_MSG4)
            return
        end
        LGameMsg.m_autoPathMsg:ChangeToStart(11,-1,-1,0,bit.lshift(517,16),true,true, nil)
        LUIManager:SendMsg(LGameMsg.m_autoPathMsg)
		LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, true)
		LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
    elseif id == AppDef.EActivityID.EAID_DOUBLEEXP then
        
        if LRoleDataMgr.MyHeroInfo.SceneType ~= AppDef.SceneType.MSI_NORMAL  then
             --非正常地图不可传送
             LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.RSI_GL_CPT_TIP8)
             LUIManager:SendMsg(LGameMsg.m_scrollTipsMsg)
             return
        end
        --双倍经验（杀怪）
        LRoleDataMgr.isHangUp = true
        --传送
        local level = LRoleDataMgr.MyHeroInfo.level
        local index = 0
        if level < 11 then
            index = 1 
        elseif level < 31 then
            index = 2 
        elseif level < 41 then
            index = 3
        elseif level < 51 then
            index = 4
        elseif level < 61 then
            index = 5
        else
            index = 6
        end
        local targetMapId = AppDef.MapIds[index]
        if targetMapId == nil then return end
        if targetMapId ~= LRoleDataMgr.MyHeroInfo.sid then
            LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.AutoPathEvent.StopAutoPath)
            LUIManager:SendMsg(LGameMsg.m_cBaseMsg)
            LuaNetSendMsg:QueryChangeCity(targetMapId)
        else
            Utils:ShowDialogOKCancel(GUITips.RSI_HSD_TIP136, function()
              LGameMsg.m_hangUpMsg:Change(CEnum.HangUpEvent.StartHangUp, 0, 0)
              LUIManager:SendMsg(LGameMsg.m_hangUpMsg)
              LGameMsg.m_baseMsgWithOne:Change(LUIRoleDataChangeEvent.StartHangUp, {0, 0})
              LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
            end, function()end)
        end
    elseif id == AppDef.EActivityID.EAID_FENGSHEN then
        if LRoleDataMgr.m_bIsInBattle then
            Utils:ShowScrollTips(GUITips.RSL_AY_MSG4)
            return
        end
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Activity.FengShenUI",AppDef.UIType.SpecialLayer)
        LUIManager:SendMsg(LGameMsg.m_initUIMsg)
    elseif id == AppDef.EActivityID.EAID_SHENJIELUNDAO then
        if LRoleDataMgr.MyHeroInfo.SceneType == AppDef.SceneType.MSI_NORMAL then
            Utils:ShowDialogOKCancel(GUITips.RSI_GMN_TIP31, function()
                LGameMsg.m_autoPathMsg:ChangeToStart(11,-1,-1,0,bit.lshift(228,16),true,true, nil)
                LUIManager:SendMsg(LGameMsg.m_autoPathMsg)
				LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, true)
				LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
            end, function()end)
        elseif LRoleDataMgr.MyHeroInfo.SceneType == AppDef.SceneType.MSI_CROSSSERVER then
            local function callback()
                LuaNetSendMsg:QueryLunDaoInfo(1)
				LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, false)
				LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
            end
            LGameMsg.m_autoPathMsg:ChangeToStart(70,-1,-1,0,bit.lshift(230,16),true,true, callback)
            LUIManager:SendMsg(LGameMsg.m_autoPathMsg)
			LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, true)
			LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
        end
    elseif id == AppDef.EActivityID.EAID_FACTION_WAR then
        LuaNetSendMsg:QueryBangPaiWarInfo(6)
    elseif id == AppDef.EActivityID.EAID_SHENJIEMIJING then
        if LRoleDataMgr.m_bIsCrossServer then
            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Activity.MiJingUI", AppDef.UIType.FirstClassLayer)
            LUIManager:SendMsg(LGameMsg.m_initUIMsg)
        else
            LGameMsg.m_autoPathMsg:ChangeToStart(11,-1,-1,0,bit.lshift(228,16),true,true, nil)
            LUIManager:SendMsg(LGameMsg.m_autoPathMsg)
			LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, true)
			LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
        end
    elseif id == AppDef.EActivityID.EAID_WEIWODUXIAN then
        if LRoleDataMgr.m_bIsCrossServer then
            LuaNetSendMsg:QueryWeiWoDuXian(1)
        else
            LGameMsg.m_autoPathMsg:ChangeToStart(11,-1,-1,0,bit.lshift(228,16),true,true, nil)
            LUIManager:SendMsg(LGameMsg.m_autoPathMsg)
			LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, true)
			LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
        end
	elseif id == AppDef.EActivityID.EAID_KUAFURENWU then
		if LRoleDataMgr.m_bIsCrossServer==false then
           AutoPathKuaFuNpc()
           return
        end
    end 
 end 

--寻路到跨服npc
function AutoPathKuaFuNpc()
     local secneType = LRoleDataMgr.MyHeroInfo.SceneType
     local factionWarScene = secneType == AppDef.SceneType.MSI_FACTION_WAR or secneType == AppDef.SceneType.MSI_FACTION_WAR_PRE
           or secneType == AppDef.SceneType.MSI_MULTISER_FACTION_BATTLE_READY or secneType == AppDef.SceneType.MSI_MULTISER_FACTION_BATTLE
    if factionWarScene == true then
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.RSI_GL_CPT_TIP7)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
            return
    end 
	local function callback()
        LRoleDataMgr.MyHeroInfo.isKuFuTaskAutoPath=true
		LuaNetSendMsg:QueryNpcChatOpen(250, 250,taskid)  
		LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, false)
		LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
    end 
	LGameMsg.m_autoPathMsg:ChangeToStart(70,2324,873,2,bit.lshift(228,16),true,true,callback)
	LUIManager:SendMsg(LGameMsg.m_autoPathMsg)
	LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, true)
	LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
    -- LGameMsg.m_autoPathMsg:ChangeToStart(11,1245,1468,0,bit.lshift(228,16),true,true,callback)
    -- LUIManager:SendMsg(LGameMsg.m_autoPathMsg)
  

end

function GetOtherItemData(tempid)
    tempid = -tempid+1
    local T_ID = {0,0,5,4,1,3,2,6,7,9,10,11}
    local item_pname  = {"item/equip3007.png","item/equip3008.png","MonsterHead/MonsterHead23.png","item/equip3006.png","item/equip3006.png","item/equip3006.png","item/equip3006.png","item/equip3012.png","item/equip3021.png","item/equip3026.png","item/equip3027.png","item/equip6091.png"}
    if tempid > #T_ID then
        return ""
    end
    local index = T_ID[tempid]+1
    if index > #item_pname then
        return ""
    end
    return item_pname[index]
    --info.name = item_tname[-info.index];
end