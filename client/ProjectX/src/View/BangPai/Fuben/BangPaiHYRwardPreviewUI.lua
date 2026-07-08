--[[
za
]]
local TimerLabelUI = require("View.Common.TimerLabelUI")
local BangPaiHYRwardPreviewUI = LUIBase:New()
BangPaiHYRwardPreviewUI.__index = BangPaiHYRwardPreviewUI
function BangPaiHYRwardPreviewUI:New()
	local o = LUIBase:New()
	setmetatable(o,BangPaiHYRwardPreviewUI)	
    o:Init()
	return o
end
function BangPaiHYRwardPreviewUI:Init()
    self.Script = "BangPai.Fuben.BangPaiHYRwardPreviewUI"
    self:CreateUINode("csd/huodong/OnlineLayer.csb")
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:InitPanel()
    self:InitData()
    self:AddTouchEvt()
    self:InitItemList()
    -- self:UpdateTime()
    -- LGameMsg.m_baseMsgWithOne:Change(LOnLineEvent.AddTimeFun,{finish=handler(self,BangPaiHYRwardPreviewUI.TimeFinish),update=handler(self,BangPaiHYRwardPreviewUI.UpdateTimeText)     })
    -- self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function BangPaiHYRwardPreviewUI:onExit()
     self:UnRegistSelf(self,self.msgIds)
    LGameMsg.m_baseMsgWithOne:Change(LOnLineEvent.DeleteTimeFun,nil)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

end
function BangPaiHYRwardPreviewUI:InitData()
    
end

--[[
注册UI消息
]]
function BangPaiHYRwardPreviewUI:RegistMsgs()
    self.msgIds = 
    {
        LUIBangPaiEvent.UpdateTodayHuoyue,
    }
    self:RegistSelf(self,self.msgIds)
end



function BangPaiHYRwardPreviewUI:ProcessEvent(msg)
    if  msg.msgId== LUIBangPaiEvent.UpdateTodayHuoyue then
        self:InitItemList();
    end
  
end

function BangPaiHYRwardPreviewUI:InitPanel()
    self.m_pUILayer:findChildByName("Panel/Bg/Time"):setVisible(false)
    self.m_pUILayer:findChildByName("Panel/Bg/Item"):setVisible(false);
    self.m_pItem = self.m_pUILayer:findChildByName("Panel/Bg/Item_0");
    self.m_pItem:setVisible(false);
    self.m_pItemList= self.m_pUILayer:findChildByName("Panel/Bg/ListView_1");
    local huoYuePanel = self.m_pUILayer:findChildByName("Panel/Bg/Huoyue")
    huoYuePanel:setVisible(true)
    local huoyueText = huoYuePanel:findChildByName("My/Text")
    local BangPaiText = huoYuePanel:findChildByName("Bangpai/Text")
    local huoyueBtn = huoYuePanel:getChildByName("Btn")
    huoyueBtn:addClickEventListener(handler(self,BangPaiHYRwardPreviewUI.GetHuoYeClicked))
    local huoyue  = LRoleDataMgr:GetMoney(AppDef.EMoneyType.EMT_HuoYue);
    huoyueText:setString(huoyue)
    BangPaiText:setString(LRoleDataMgr.Faction.todayHuoyue)
    -- self.m_pItem=self:FindNode("Bg.Item")
    -- self.m_pItem:setPosition(cc.p(-2000,-2000))
    -- self.m_pItemList=self:FindNode("Bg.ListView_1")
    -- self.m_pItemList:setClippingEnabled(true)
    -- self.m_pTime=self:FindNode("Bg.Time")
    -- self.m_pGetBtn=self:FindNode("Bg.Btn")
    -- self.m_pExitBtn=self:FindNode("Bg.R.Button_1")
    

end

function BangPaiHYRwardPreviewUI:GetHuoYeClicked()
    Utils:OpenFunction(AppDef.EModuleID.EMID_TASK_DALIY)
    self:RemoveUI()
end


function BangPaiHYRwardPreviewUI:AddTouchEvt()

    local btn = self.m_pUILayer:findChildByName("Panel/Bg/R/Button_1");
    btn:addClickEventListener(function(sender)
        self:RemoveUI();
    end)
    -- self.m_pGetBtn:addClickEventListener(function (sender)
    --     print("执行 LuaNetSendMsg:AwardOnlineAward()")
    --     LuaNetSendMsg:AwardOnlineAward()
    -- end)
end
function BangPaiHYRwardPreviewUI:InitItemList()

    --LRoleDataMgr.Faction.huoyueAward
    self.m_pItemList:removeAllChildren();
    local list = LRoleDataMgr.Faction.huoyueAward
    for i=1, #list do
        local cellChild =self.m_pItem:clone()
        cellChild:setTag(i)
        cellChild:setName(i)
        cellChild:setAnchorPoint(cc.p(0,0))
        cellChild:setPosition(cc.p(0,0))
        cellChild:setVisible(true)
        self.m_pItemList:pushBackCustomItem(cellChild)
        local function getClicked(sender)
            print("getClickedgetClicked")
            self:HandleGetReward(sender)
        end
        local btn = cellChild:findChildByName("Mask");
        btn.userData = i;
        btn:addClickEventListener(getClicked)
        self:UpdateOne(cellChild, list[i], i)
    end
end

function BangPaiHYRwardPreviewUI:HandleGetReward(sender)
    local ind = sender.userData;
    local list = LRoleDataMgr.Faction.huoyueAward
    local data = list[ind];
    local configData = JsonConfig.GetGuildRewardData(data.huoyueId);
    local rewardData = JsonConfig.m_BoxReward.getDefByID(configData.reward_fix)

    --奖励宝箱弹窗通用
--@title 标题
--@rewards 奖励列表（id,0,num)结构
--@callback 确认按钮回调
--@isShowBtn 确认按钮是否显示，false时显示文字 
--@tips okIsShow为false时,显示文字为nil则显示默认(RSI_BOX_TIP1);okIsShow为true时,为按钮文字(RSI_GS_TIP_RECOVERY_DRAW)
--@callback 领取按钮返回
--@closedCallBack --关闭按钮返回

    local function OkBtn()
        if list[ind].isGet == 0 then
            return
        end

        if list[ind].isGet == 2 then
            return
        end

        LuaNetSendMsg:QueryGetBangPaiHuoyueReward(list[ind].huoyueId);
    end
    if list[ind].isGet == 1 then
        Utils:OpenRewardBox(GUITips.RSI_BOX_TIP2,rewardData.reward,true,GUITips.RSI_GS_TIP_RECOVERY_SURE,OkBtn,nil);
    else
        Utils:OpenRewardBox(GUITips.RSI_BOX_TIP2,rewardData.reward,false,"",nil,nil);
    end
    


    -- if list[ind].isGet == 0 then
    --     return
    -- end

    -- if list[ind].isGet == 2 then
    --     return
    -- end

    -- LuaNetSendMsg:QueryGetBangPaiHuoyueReward(list[ind].huoyueId);
    --if 
end

function BangPaiHYRwardPreviewUI:UpdateOne(cell, data, ind)
    --[[
    id = 3,
    activity = 3000,
    reward_fix = 50003,
    pic = "equip3001"
    ]]
    local list = LRoleDataMgr.Faction.huoyueAward

    local configData = JsonConfig.GetGuildRewardData(data.huoyueId);

    local timeText = cell:findChildByName("Line/Time");

    if ind~=1 then
        cell:findChildByName("Line/Text"):setVisible(false)
    end
    --local effect
    local effect =cell:getChildByName("effect")
    local iconBg = cell:getChildByName("IconBg")
    if effect==nil then
        effect = Utils:ReceivableEffect(0.6)
        effect:setName("effect")
        cell:addChild(effect)
    else
        effect=cell:getChildByName("effect")
    end
    -- dump(iconBg:getPosition(),"iconBg======>")
    -- dump(effect:getPosition(),"effect======>")
    effect:setPosition(cc.p(iconBg:getPositionX(),iconBg:getPositionY()))
    effect:setLocalZOrder(-1)
    effect:setVisible(true)

    -- local item=cell:getChildByName("IconBg"):getChildByName("Mask"):getChildByName("Lingqu_0")
    timeText:setString(configData.activity)
    cell:findChildByName("Mask/Lingqu_0"):setTouchEnabled(false)
    if data.isGet == 0 then
        --未领取
        cell:findChildByName("Mask/Lingqu_0"):setVisible(false)
        cell:findChildByName("Mask/Lingqu"):setVisible(false)
        cell:findChildByName("Line/bg/Image"):setVisible(false)
        effect:setVisible(false)
    elseif data.isGet == 1 then
        cell:findChildByName("Mask/Lingqu_0"):setVisible(false)
        cell:findChildByName("Mask/Lingqu"):setVisible(false)
        cell:findChildByName("Line/bg/Image"):setVisible(true)
        effect:setVisible(true)
    else
        cell:findChildByName("Mask/Lingqu_0"):setVisible(false)
        cell:findChildByName("Mask/Lingqu"):setVisible(true)
        cell:findChildByName("Line/bg/Image"):setVisible(true)
        effect:setVisible(false)
    end
    if ind == #list then
        cell:findChildByName("Line/Bg"):setVisible(false);
    else
        local function getProgress()
            local nextData = list[ind + 1];
            local nextConfigData = JsonConfig.GetGuildRewardData(nextData.huoyueId);
            local max = nextConfigData.activity - configData.activity
            local cur = LRoleDataMgr.Faction.todayHuoyue - configData.activity;
            if cur < 0 then
                cur = 0
            end
            return (cur * 100) / max
        end
        local progress = getProgress();
        local progressBar = cell:findChildByName("Line/Bg/LoadingBar");
        progressBar:setPercent(progress);
    end
    


    local userDefine ={picFilePath = "item/" .. configData.pic .. ".png", quality = 0, num = 0}
    local itemValue = {}
    itemValue.userDefine = userDefine
    itemValue.isShowNum = false
    itemValue.isShowQualityBg = false
    itemValue.isChangeSize = true
    -- local iconNode = cell:findChildByName("IconBg/Mask/Lingqu_0");
    -- iconNode:setVisible(true)
    ItemCellUI:New(cell:getChildByName("IconBg"), itemValue)



end

function BangPaiHYRwardPreviewUI:SetItemState(cell,isGet)
    local isGetNode = cell:getChildByName("IconBg"):getChildByName("Mask"):getChildByName("Lingqu")
    local bar = cell:getChildByName("Line"):getChildByName("LoadingBar")
    local tipImage =cell:getChildByName("Line"):getChildByName("bg"):getChildByName("Image") 
    tipImage:setVisible(isGet)
    isGetNode:setVisible(isGet)
    if  isGet==true then
        bar:setPercent(100)
    else
        bar:setPercent(0)
    end
end
function BangPaiHYRwardPreviewUI:CheckIsGetReward(ind)
   return self.m_OnLineData:CheckIsGet(ind)
end
-- function BangPaiHYRwardPreviewUI:FindNode(str)
--     if string.len(str)<1 then
--         return
--     end
--     local nodeName = string.split(str,'.')
--     local node = self.m_pUILayer:getChildByName("Panel")
--     for i=1,#nodeName do
--         node=node:getChildByName(nodeName[i])     
--     end
--     if node==nil then
--         print("获取node失败")
--     end
--     return node
-- end
return BangPaiHYRwardPreviewUI