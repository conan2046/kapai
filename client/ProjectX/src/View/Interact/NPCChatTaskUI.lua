--[[
NPC对话
]]

local NPCChatTaskUI = LUIBase:New()
NPCChatTaskUI.__index = NPCChatTaskUI
NPCChatTaskUI.IsHideInBattle = true
function NPCChatTaskUI:New(chatData)
    --print("NPCChatTaskUI:New",chatData)
	local o = LUIBase:New()
	setmetatable(o,NPCChatTaskUI)	
    o:Init(chatData)
	return o
end

--[[
注册消息
]]
function NPCChatTaskUI:RegistMsgs()
    self.msgIds = 
    {
        -- LUILoginEvent.RecvCheckHeroName,
        -- LUILoginEvent.RecvServerList,
        -- LUILoginEvent.RecvRoleServerList,
        -- LUILoginEvent.LoginSuccess,
    }
    self:RegistSelf(self,self.msgIds)
end

function NPCChatTaskUI:ProcessEvent(msg)
--    if msg.msgId == LUILoginEvent.RecvCheckHeroName then
--        self:SaveRandomName(msg.value)
--    end
end

function NPCChatTaskUI:Init(chatData)
    self:RegistMsgs()

    self.m_pUILayer = cc.CSLoader:createNode("csd/TaskAcceptLayer.csb")
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
    self:UpdateUserData(chatData)
end

function NPCChatTaskUI:InitData()
    local panel = self.m_pUILayer:getChildByName("QuestDialogUI")
    local namePanel = panel:getChildByName("bg_Name")
    self.m_pNameLabel = namePanel:getChildByName("Name")
    self.m_pTaskNameLabel = panel:getChildByName("taskName")
    self.m_pNPCImg = panel:getChildByName("NPC")
    self.m_pDescLabel = panel:getChildByName("taskDesc")
    self.m_pDescLabel:setVisible(false)
    self.m_pTargetLabel = panel:getChildByName("taskTarget")
    self.m_pBtn =panel:getChildByName("Item")

    self.m_taskId = 0
    self.m_taskType = 0
end 

function NPCChatTaskUI:GetNpcBodyTexture(npcType, npcPicId)
    if npcType == 0 then  --NPC
        return Utils:GetNPCIconRes(npcPicId, AppDef.HeadIconResType.Body)
    elseif npcType == 1 then --玩家
        return Utils:GetHeroIconRes(LRoleDataMgr.MyHeroInfo.professional, AppDef.HeadIconResType.Body)
    elseif npcType == 2 then --怪物
        return Utils:GetMonsterIconRes(npcPicId, AppDef.HeadIconResType.Body)
    elseif npcType == 3 then --坐骑
        return Utils:GetHorseIconRes(npcPicId, AppDef.HeadIconResType.Body)
    else
        return nil
    end
end

function NPCChatTaskUI:UpdateUserData(data)
    local npcType = data:ReadByte()
    local npcPicId = data:ReadWord()
    self.m_taskId = data:ReadUInt()
    local _TaskName = data:ReadString()
    local bufText = data:ReadString()

    -- print("_TaskName=",_TaskName,"bufTex=",bufText)
    --[主]妲己前传·缘起    bufTex= 0|苏妲己|[主]妲己前传·缘起|我就是苏妲己，出生时候让满城鲜花尽数凋零，才有了这个名字。|对话苏妲己|1,50000,0;7,0;5,0;|
    local testArr = string.split(bufText, "|")

    --NPC头像
    self.m_pNPCImg:loadTexture(self:GetNpcBodyTexture(npcType, npcPicId),ccui.TextureResType.localType)
    self.m_pNameLabel:setString(testArr[2])
    self.m_pTaskNameLabel:setString(testArr[3])
    --读取任务类型(0-领取 1-完成)
    self.m_taskType = tonumber(testArr[1])
    if self.m_taskType == 0 then
        self.m_pBtn:setTitleText(GUITips.Task_Accept)
        self.m_pTaskNameLabel:setTextColor(UICOLOR_PURPLE)
    else
        self.m_pBtn:setTitleText(GUITips.Task_Complete)
        self.m_pTaskNameLabel:setTextColor(UICOLOR_BROWN)
    end
    local newLabel = self.m_pDescLabel:getParent():getChildByName("NewDesc")
    if newLabel == nil then
        newLabel = CCAysLabel:create()
        newLabel:setPosition(self.m_pDescLabel:getPosition())
        newLabel:setAnchorPoint(self.m_pDescLabel:getAnchorPoint())
        newLabel:setName("NewDesc")
        self.m_pDescLabel:getParent():addChild(newLabel)
    end
    local taskFontSize = self.m_pDescLabel:getFontSize()
    local taskFontName = self.m_pDescLabel:getFontName()

    newLabel:triggleInit(testArr[4] , cc.size(self.m_pDescLabel:getContentSize().width,0) , -132 , UICOLOR_BROWN , taskFontSize,
    false,0,0,0,true,false)   --ccWHITE
    size = newLabel:getSize() 


    --任务目标
    self.m_pTargetLabel:setString(testArr[5])
    --
    -- end = StringHelper::ReadBeforeCharStr(bufText, '|', end+1, str);
    -- CCLabelTTF* lbTaskGoal = (CCLabelTTF*)_TabAcceptTask->getChildByTag(302);
    -- lbTaskGoal->setFontName(FNT_NAMEC);
    -- lbTaskGoal->setColor(UICOLOR_BROWN);
    -- lbTaskGoal->setString(str.c_str());
    
    -- //读取任务奖励
    -- str = bufText.substr(end+1, bufText.size() - end -1);

    -- //清空奖励底框和文字
    -- for (int i=1; i<=3; i++)
    -- {
    --     _TabFinishTask->getChildByTag(400+i)->setVisible(false);
    --     _TabFinishTask->getChildByTag(500+i)->setVisible(false);
    -- }

    -- //解析奖励
    -- CCNode *lastNode = NULL;
    -- int curPrizeIdx = 1;
    -- for(size_t i = 0;i < str.size();)
    -- {
    --     //达到最大数量则忽略
    --     if(curPrizeIdx > 3)
    --         break;

    --     //读取奖励类型
    --     int prizeType = 0;
    --     int endSub = StringHelper::ReadBeforeCharInt(str, ',', i, prizeType);
    --     if(endSub == -1)
    --         break;
        
    --     //继续下一条
    --     i = endSub + 1;

    --     //奖励文本
    --     CCLabelTTF* lbText = (CCLabelTTF*)_TabFinishTask->getChildByTag(500+curPrizeIdx);
    --     lbText->setFontName(FNT_NAMEC);
    --     lbText->setColor(UICOLOR_BROWN);
    --     lbText->setVisible(true);

    --     //奖励背景框
    --     CCSprite* sprItemBG = (CCSprite*)_TabFinishTask->getChildByTag(400+curPrizeIdx);
    --     sprItemBG->setVisible(true);

    --     //1:角色经验 2:宠物经验 3:道具奖励 4:角色道行 5:角色潜能 6:绑定金币 7:不绑定金币
    --     if(prizeType == 1 || prizeType == 2 || prizeType == 4 || prizeType == 5 || prizeType == 6 || prizeType == 7)
    --     {
    --         string typeName = "";
    --         string iconName = "item/equip3007.mydp";
    --         if(prizeType == 1) { typeName = RES_STR(DataConsts::RSI_WELFARE_MSG18); iconName = "item/equip3007.mydp"; }
    --         else if(prizeType == 2) { typeName = RES_STR(DataConsts::RSI_FACTION_MSG33); iconName = "item/equip3007.mydp";}
    --         else if(prizeType == 4) { typeName = RES_STR(DataConsts::RSI_RANK_MSG10); iconName = "item/equip3007.mydp"; }
    --         else if(prizeType == 5) { typeName = RES_STR(DataConsts::RSI_FACTION_MSG36); iconName = "item/equip3008.mydp";}
    --         else if(prizeType == 6) { typeName = RES_STR(DataConsts::RIS_LEFTUI_MSG103); iconName = "item/equip3006.mydp";}
    --         else if(prizeType == 7) { typeName = RES_STR(DataConsts::RSI_WELFARE_MSG16); iconName = "item/equip3006.mydp";}

    --         //读取数值
    --         int val = 0;
    --         endSub = StringHelper::ReadBeforeCharInt(str, ';', i, val);
    --         if(endSub == -1)
    --             break;

    --         //继续下一条
    --         i = endSub + 1;

    --         //数量为0不显示
    --         if(val == 0)
    --         {
    --             lbText->setVisible(false);
    --             sprItemBG->setVisible(false);
    --             break;
    --         }

    --         //图标
    --         CCSprite* spr = CCSprite::create(iconName.c_str());
    --         spr->setAnchorPoint(sprItemBG->getAnchorPoint());
    --         spr->setPosition(sprItemBG->getPosition());
    --         _TabFinishTask->addChild(spr, 1);
            
    --         string briefVal = (val >=100*10000) ? CCSTR_FMT1("%dW",val/10000) : CCSTR_FMT1("%d",val);
    --         lbText->setString(CCSTR_FMT2(A2UC("%s:%s"), typeName.c_str(), briefVal.c_str()));
    --         curPrizeIdx++;
    --     }
    --     else if (prizeType == 3)
    --     {
    --         //编号
    --         int itemId = 0; 
    --         endSub = StringHelper::ReadBeforeCharInt(str, ',', i, itemId);
    --         if(endSub == -1)
    --             break;

    --         //品质
    --         int quality = 0;
    --         endSub = StringHelper::ReadBeforeCharInt(str, ',', endSub + 1, quality);
    --         if(endSub == -1)
    --             break;

    --         //强化等级
    --         int lv = 0;
    --         endSub = StringHelper::ReadBeforeCharInt(str, ',', endSub + 1, lv);
    --         if(endSub == -1)
    --             break;

    --         //数量
    --         int num = 0;
    --         endSub = StringHelper::ReadBeforeCharInt(str, ';', endSub + 1, num);
    --         if(endSub == -1)
    --             break;

    --         //继续下一条
    --         i = endSub + 1;

    --         //数量为0不显示
    --         if(num == 0)
    --         {
    --             lbText->setVisible(false);
    --             sprItemBG->setVisible(false);
    --             break;
    --         }

    --         CItem* p = ITEM_MGR->getItem(itemId);
    --         if(!p)
    --             break;

    --         //图标
    --         CCSprite* spr = CCSprite::create(CCSTR_FMT1("item/equip%d.mydp", p->m_pic));
    --         spr->setAnchorPoint(sprItemBG->getAnchorPoint());
    --         spr->setPosition(sprItemBG->getPosition());
    --         _TabFinishTask->addChild(spr, 1);

    --         //说明
    --         lbText->setString(CCSTR_FMT2(A2UC("%sx%d"), p->m_name.c_str(), num));
    --         curPrizeIdx++;
    --     }
    --     else if (prizeType == 8)  
    --     {
    --     }
    --     else
    --     {
    --     }
    -- }

end


function NPCChatTaskUI:GetNpcBodyTexture(npcType, npcPicId)
    if npcType == 0 then  --NPC
        return string.format("npchead/npchead%d.png", npcPicId)
    elseif npcType == 2 then --怪物
        return string.format("MonsterBody/Monsterbody%d.png", npcPicId)
    elseif npcType == 3 then --坐骑
        return string.format("HorseHead/HorseBody%d.png", npcPicId)
    else
        return "npchead/npc_head_defult.png"
    end
end

function NPCChatTaskUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_pNameLabel = nil
    self.m_pNPCImg = nil
    self.m_pDescLabel = nil
    self.m_pListView = nil
    self.m_pBaseBtn = nil
    self.m_pListViewBg = nil
    self.m_pBgLabel = nil

    self.m_pTargetLabel = nil
    self.m_pBtn = nil

    self.m_taskId = nil
    self.m_taskType = nil
    self.m_pChatData = nil
end

function NPCChatTaskUI:AddTouchEvt()
    local panel = self.m_pUILayer:getChildByName("QuestDialogUI")
    local function ExitCallback(sender)
       LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Interact.NPCChatTaskUI")
       self:SendMsg(LGameMsg.m_initUIMsg)
    end
    panel:addClickEventListener(ExitCallback)
	self:MarkIntaractCObj(panel)

    


    local function taskBtnCallback(sender)
        if self.m_taskType == 0 then
            LGameMsg.m_baseMsg:ChangeEventId(LUILogicEvent.TaskAccept)
        else
            LGameMsg.m_baseMsg:ChangeEventId(LUILogicEvent.TaskComplete)
        end
        self:SendMsg(LGameMsg.m_baseMsg)
        local tid = self.m_taskId
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Interact.NPCChatTaskUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
        LuaNetSendMsg:QueryNpcChatTask(tid)
        -- --播放动画
        -- local strPath
        -- if self.m_taskType == 0 then
        --     strPath = "UI/RecvTaskText.png"
        -- else
        --     strPath = "UI/FinishTaskText.png"
        -- end
        -- local AnimateSpr = cc.Sprite:create(strPath)
        -- AnimateSpr:setOpacity(0)

        -- local function EffectPlayEnd()
        --     local tid = self.m_taskId
            
        --     LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Interact.NPCChatTaskUI")
        --     self:SendMsg(LGameMsg.m_initUIMsg)
        --     LuaNetSendMsg:QueryNpcChatTask(tid)
        -- end
        -- local DelayTime = cc.DelayTime:create(1.0)
        -- local FadeToStart = cc.FadeTo:create(0.4,255)
        -- local FadeTo = cc.FadeTo:create(0.4,0)
        -- local CallBack = cc.CallFunc:create(EffectPlayEnd)
        -- AnimateSpr:runAction(cc.Sequence:create(FadeToStart,DelayTime,FadeTo,CallBack))
        -- AnimateSpr:setPosition(self.m_pUILayer:convertToNodeSpace(cc.p(AppDef.frameSize.width/2,AppDef.frameSize.height/2)))
        -- self.m_pUILayer:addChild(AnimateSpr)
    end
    self.m_pBtn:addClickEventListener(taskBtnCallback)
	self:MarkIntaractCObj(self.m_pBtn)
end
return NPCChatTaskUI