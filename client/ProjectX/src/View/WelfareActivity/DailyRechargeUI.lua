--[[
lua里面的游戏逻辑控制
每日充值
]]

local DailyRechargeUI = LUIBase:New()
DailyRechargeUI.__index = DailyRechargeUI
--local this = LTcpSocket
function DailyRechargeUI:New(parent)
	local o = LUIBase:New()
	setmetatable(o,DailyRechargeUI)	
    o:Init(parent)
	return o
end

function DailyRechargeUI:Init(parent)
    self.m_pUILayer = cc.CSLoader:createNode("csd/DailyChargeLayer.csb")
    parent:addChild(self.m_pUILayer)
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    self:RegistMsgs()
    self:InitUIControl()
    self:AddTouchEvt()
end



function DailyRechargeUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
    LRechargeDataMgr:Free()
end

--[[
注册UI消息
]]
function DailyRechargeUI:RegistMsgs()
    self.msgIds = 
    {
        LUIWelfareActivityEvent.DailyReChargeBtnState,          --更新Btn
    }
    self:RegistSelf(self,self.msgIds)
end

function DailyRechargeUI:ProcessEvent(msg)
    if msg.msgId == LUIWelfareActivityEvent.DailyReChargeSuccess then
        self:CheckRechargeBtn()
    end
end

function DailyRechargeUI:InitUIControl()
    local panel = self.m_pUILayer:getChildByName("Panel"):getChildByName("DailyChargeBg"):getChildByName("ContentBg")
    --self.m_pUILayer:getChildByName("Panel"):getChildByName("BtnList"):setTouchEnabled(false)--TODO 待删除
    --button
    self.m_btn = panel:getChildByName("RechargeBtn")
    self.m_btnLabel = self.m_btn:getChildByName("Text")
    self.m_btn:setEnabled(false)
    --微信领取按钮-设为不可点
    self.m_wxBtn = panel:getChildByName("ReceiveBtn")
    self.m_wxBtnLabel = self.m_wxBtn:getChildByName("Text")
    self.m_wxBtn:setEnabled(false)

    --listview
    local listview = panel:getChildByName("ListView")
    --icon底
    self.m_iconBgList = {}
    self.m_nameLabels = {}
    for i= 1,3 do
        local icon = listview:getChildByName("IconBg_"..i)
        if icon ~= nil then
            table.insert(self.m_iconBgList,icon)
            local label = icon:getChildByName("Text")
            table.insert(self.m_nameLabels,label)
        end
    end
    local idx = #self.m_iconBgList+1
    self.m_iconBgList[idx] = panel:getChildByName("IconBg")
    self.m_nameLabels[idx] = self.m_iconBgList[idx]:getChildByName("Text")

    self.m_iconNodes = {}
end

function DailyRechargeUI:initData()
   LuaNetSendMsg:QueryKaifuHuodong(18,1)
end

function DailyRechargeUI:updateData(data)
    self.m_pUILayer:setVisible(true)
    self:CheckRechargeBtn()
    self:LoadItemList()
end

function DailyRechargeUI:CheckRechargeBtn()
    local data = LRechargeDataMgr:GetDailyRechargeData()
    if data.chongzhi == 1 then 
         if data.lingqu == 1 then
            self.m_btnLabel:setString(GUITips.RSI_RECHARGE_TIP2)
            self.m_btn:setEnabled(false)
         else
            self.m_btnLabel:setString(GUITips.RSI_RECHARGE_TIP1)
            self.m_btn:setEnabled(true)
            self.m_btn.userObject = 2
         end
    else
         self.m_btnLabel:setString(GUITips.RSI_RECHARGE_TIP8)
         self.m_btn:setEnabled(true)
         self.m_btn.userObject = 1
    end
end

function DailyRechargeUI:AddTouchEvt()

    local function EnterCallBack(sender)
        local sign = sender.userObject
        if sign == nil or sign < 1 then 
            return
        end
        if sign == 1 then
            self:OpenRechargeMainUI()
        elseif sign == 2 then 
            LuaNetSendMsg:QueryKaifuHuodong(18,2)
        end
    end
    self.m_btn:addClickEventListener(EnterCallBack)
	self:MarkIntaractCObj(self.m_btn)
end

function DailyRechargeUI:OpenRechargeMainUI()
    self:CloseUI()
    if #LRoleDataMgr.MyHeroInfo.m_PayPricelist > 0 then
         LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Vip.RechargeMainUI",AppDef.UIType.FirstClassLayer, 1)
         self:SendMsg(LGameMsg.m_initUIMsg)
    else -- 没有查询过 就先查询
         LuaNetSendMsg:QueryPayPriceList()
    end    
end

function DailyRechargeUI:LoadItemList()
    local data = LRechargeDataMgr:GetDailyRechargeData()
    local info = data.itemList
    if info == nil or #info == 0 then
        return
    end
    local size = #info
    if size > #self.m_iconBgList then
        size = #self.m_iconBgList
    end
    for i=1,size do
        self:ShowIcon(i,info[i].id,info[i].num)
    end
end

function DailyRechargeUI:ShowIcon(index,itemId,num,nameLabel)
    local item = Utils:GetItemCellValue(self.m_iconBgList[index],0,itemId,true,true,num,self.m_iconNodes[index],true)
    local quality = Utils:getQualityByItem(item)
--    print("DailyRechargeUI:ShowIcon quality", quality)
    if quality >= 5 then
        local posX = self.m_iconBgList[index]:getContentSize().width / 2
        local posY = self.m_iconBgList[index]:getContentSize().height / 2
        Utils:createAnimEffect(self.m_iconBgList[index], cc.p(posX, posY), "res2/fx/gaojiwupin")
    end

    if itemId < AppDef.AwrdItem.AWRD_ITEM_COIN then	
        local data = LItemMgr:getItem(itemId)
        if data ~= nil and nameLabel ~= nil then
            nameLaebel:setString(data.m_name)
        end
    else
        self:ShowMoneyName(itemId,nameLabel)
    end
end

function DailyRechargeUI:ShowMoneyName(itemId,nameLabel)
    local strName = AppDef.AwrdItemName[itemId]
    if nameLabel ~= nil and strName ~= nil then
        nameLabel:setString(strName)
    end
end

function DailyRechargeUI:CloseUI()
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Recharge.DailyRechargeUI")
	self:SendMsg(LGameMsg.m_initUIMsg)
end


return DailyRechargeUI